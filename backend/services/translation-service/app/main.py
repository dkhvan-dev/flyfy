from __future__ import annotations

import hashlib
import hmac
import os
import asyncio
import ssl
from collections import OrderedDict
from contextlib import asynccontextmanager
from dataclasses import dataclass
from threading import RLock
from typing import Annotated, Any

import torch
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator
from transformers import M2M100ForConditionalGeneration, M2M100Tokenizer
import uvicorn


SUPPORTED_LANGUAGES = {"en", "ru", "kk"}


@dataclass(frozen=True)
class Settings:
    model_name: str
    supported_languages: set[str]
    internal_service_token: str
    max_batch_size: int
    max_input_tokens: int
    max_output_tokens: int
    num_beams: int
    cache_max_items: int
    preload_model: bool


@dataclass(frozen=True)
class ServerSettings:
    host: str
    http_port: int
    internal_http_tls_port: int
    mtls_mode: str
    mtls_ca_cert_path: str
    mtls_server_cert_path: str
    mtls_server_key_path: str
    mtls_allowed_spiffe_ids: tuple[str, ...]
    mtls_allowed_dns_names: tuple[str, ...]


@dataclass(frozen=True)
class MTLSPeerIdentities:
    spiffe_ids: tuple[str, ...]
    dns_names: tuple[str, ...]


def load_settings() -> Settings:
    supported = {
        normalize_language_code(value)
        for value in os.getenv("TRANSLATION_SUPPORTED_LANGUAGES", "en,ru,kk").split(",")
    }
    supported.discard("")
    supported = supported & SUPPORTED_LANGUAGES
    if not supported:
        supported = SUPPORTED_LANGUAGES

    return Settings(
        model_name=os.getenv("TRANSLATION_MODEL_NAME", "facebook/m2m100_418M").strip()
        or "facebook/m2m100_418M",
        supported_languages=supported,
        internal_service_token=os.getenv("INTERNAL_SERVICE_TOKEN", "").strip(),
        max_batch_size=max(1, int(os.getenv("TRANSLATION_MAX_BATCH_SIZE", "16"))),
        max_input_tokens=max(16, int(os.getenv("TRANSLATION_MAX_INPUT_TOKENS", "256"))),
        max_output_tokens=max(16, int(os.getenv("TRANSLATION_MAX_OUTPUT_TOKENS", "256"))),
        num_beams=max(1, int(os.getenv("TRANSLATION_NUM_BEAMS", "2"))),
        cache_max_items=max(0, int(os.getenv("TRANSLATION_CACHE_MAX_ITEMS", "20000"))),
        preload_model=os.getenv("TRANSLATION_PRELOAD_MODEL", "false").strip().lower()
        in {"1", "true", "yes", "on"},
    )


def load_server_settings() -> ServerSettings:
    return ServerSettings(
        host=os.getenv("HTTP_HOST", "0.0.0.0").strip() or "0.0.0.0",
        http_port=max(1, int(os.getenv("HTTP_PORT", "8094"))),
        internal_http_tls_port=max(0, int(os.getenv("INTERNAL_HTTP_TLS_PORT", "0"))),
        mtls_mode=normalize_mtls_mode(os.getenv("MTLS_MODE", "disabled")),
        mtls_ca_cert_path=os.getenv("MTLS_CA_CERT_PATH", "").strip(),
        mtls_server_cert_path=os.getenv("MTLS_SERVER_CERT_PATH", "").strip(),
        mtls_server_key_path=os.getenv("MTLS_SERVER_KEY_PATH", "").strip(),
        mtls_allowed_spiffe_ids=split_env_list(os.getenv("MTLS_ALLOWED_SPIFFE_IDS", "")),
        mtls_allowed_dns_names=split_env_list(os.getenv("MTLS_ALLOWED_DNS_NAMES", "")),
    )


def split_env_list(value: str) -> tuple[str, ...]:
    return tuple(item.strip() for item in value.split(",") if item.strip())


def normalize_mtls_mode(value: str) -> str:
    normalized = value.strip().lower()
    if normalized in {"permissive", "enforce"}:
        return normalized
    return "disabled"


def validate_translation_mtls_config(settings: ServerSettings) -> None:
    if settings.mtls_mode == "disabled":
        return
    if settings.internal_http_tls_port == 0:
        raise ValueError("INTERNAL_HTTP_TLS_PORT is required when translation-service mTLS is enabled")
    if settings.internal_http_tls_port == settings.http_port:
        raise ValueError("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
    if not settings.mtls_ca_cert_path:
        raise ValueError("MTLS_CA_CERT_PATH is required when translation-service mTLS is enabled")
    if not settings.mtls_server_cert_path or not settings.mtls_server_key_path:
        raise ValueError("MTLS_SERVER_CERT_PATH and MTLS_SERVER_KEY_PATH are required when translation-service mTLS is enabled")


def internal_mtls_uvicorn_ssl_options(settings: ServerSettings) -> dict[str, object]:
    validate_translation_mtls_config(settings)
    return {
        "ssl_certfile": settings.mtls_server_cert_path,
        "ssl_keyfile": settings.mtls_server_key_path,
        "ssl_ca_certs": settings.mtls_ca_cert_path,
        "ssl_cert_reqs": ssl.CERT_REQUIRED if settings.mtls_mode == "enforce" else ssl.CERT_OPTIONAL,
    }


def extract_peer_certificate_identities(peer_cert: dict[str, Any] | None) -> MTLSPeerIdentities:
    if not peer_cert:
        return MTLSPeerIdentities(spiffe_ids=(), dns_names=())

    spiffe_ids: list[str] = []
    dns_names: list[str] = []
    for kind, value in peer_cert.get("subjectAltName", ()):
        normalized_kind = str(kind).strip().upper()
        normalized_value = str(value).strip()
        if not normalized_value:
            continue
        if normalized_kind == "URI" and normalized_value.startswith("spiffe://"):
            spiffe_ids.append(normalized_value)
        elif normalized_kind == "DNS":
            dns_names.append(normalized_value.lower())

    return MTLSPeerIdentities(
        spiffe_ids=tuple(spiffe_ids),
        dns_names=tuple(dns_names),
    )


def peer_certificate_identity_allowed(
    identities: MTLSPeerIdentities,
    server_settings: ServerSettings,
) -> bool:
    allowed_spiffe_ids = set(server_settings.mtls_allowed_spiffe_ids)
    allowed_dns_names = {value.lower() for value in server_settings.mtls_allowed_dns_names}
    if not allowed_spiffe_ids and not allowed_dns_names:
        return True
    if allowed_spiffe_ids.intersection(identities.spiffe_ids):
        return True
    if allowed_dns_names.intersection(identities.dns_names):
        return True
    return False


def mtls_h11_protocol_class():
    from uvicorn.protocols.http.h11_impl import H11Protocol

    class MTLSH11Protocol(H11Protocol):
        def connection_made(self, transport):  # type: ignore[no-untyped-def]
            super().connection_made(transport)
            ssl_object = transport.get_extra_info("ssl_object")
            peer_cert = ssl_object.getpeercert() if ssl_object is not None else None
            self._mtls_peer_identities = extract_peer_certificate_identities(peer_cert)

        def handle_events(self) -> None:
            super().handle_events()
            if self.scope is not None:
                self.scope["mtls.peer"] = getattr(
                    self,
                    "_mtls_peer_identities",
                    MTLSPeerIdentities(spiffe_ids=(), dns_names=()),
                )

    return MTLSH11Protocol


def normalize_language_code(value: str) -> str:
    normalized = value.strip().lower().replace("_", "-")
    if "-" in normalized:
        normalized = normalized.split("-", 1)[0]
    return normalized


class TranslateRequest(BaseModel):
    source_language: Annotated[str, Field(alias="sourceLanguage", min_length=2)]
    target_languages: Annotated[list[str], Field(alias="targetLanguages", min_length=1, max_length=8)]
    texts: Annotated[list[str], Field(min_length=1, max_length=32)]

    @field_validator("source_language")
    @classmethod
    def normalize_source_language(cls, value: str) -> str:
        return normalize_language_code(value)

    @field_validator("target_languages")
    @classmethod
    def normalize_target_languages(cls, values: list[str]) -> list[str]:
        result: list[str] = []
        seen: set[str] = set()
        for value in values:
            normalized = normalize_language_code(value)
            if not normalized or normalized in seen:
                continue
            result.append(normalized)
            seen.add(normalized)
        return result

    @field_validator("texts")
    @classmethod
    def trim_texts(cls, values: list[str]) -> list[str]:
        return [value.strip() for value in values]


class TranslateResponse(BaseModel):
    translations: dict[str, list[str]]
    model: str


class LRUTranslationCache:
    def __init__(self, max_items: int) -> None:
        self._max_items = max_items
        self._items: OrderedDict[str, str] = OrderedDict()
        self._lock = RLock()

    def get(self, key: str) -> str | None:
        if self._max_items <= 0:
            return None
        with self._lock:
            value = self._items.get(key)
            if value is None:
                return None
            self._items.move_to_end(key)
            return value

    def set(self, key: str, value: str) -> None:
        if self._max_items <= 0:
            return
        with self._lock:
            self._items[key] = value
            self._items.move_to_end(key)
            while len(self._items) > self._max_items:
                self._items.popitem(last=False)

    def size(self) -> int:
        with self._lock:
            return len(self._items)


class TranslationEngine:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._cache = LRUTranslationCache(settings.cache_max_items)
        self._model: M2M100ForConditionalGeneration | None = None
        self._tokenizer: M2M100Tokenizer | None = None
        self._device = "cuda" if torch.cuda.is_available() else "cpu"
        self._load_lock = RLock()
        self._inference_lock = RLock()

    @property
    def loaded(self) -> bool:
        return self._model is not None and self._tokenizer is not None

    @property
    def cache_size(self) -> int:
        return self._cache.size()

    def ensure_loaded(self) -> None:
        if self.loaded:
            return
        with self._load_lock:
            if self.loaded:
                return
            tokenizer = M2M100Tokenizer.from_pretrained(self._settings.model_name)
            model = M2M100ForConditionalGeneration.from_pretrained(self._settings.model_name)
            model.to(self._device)
            model.eval()
            self._tokenizer = tokenizer
            self._model = model

    def translate(
        self,
        source_language: str,
        target_languages: list[str],
        texts: list[str],
    ) -> dict[str, list[str]]:
        if not target_languages:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="target languages are required",
            )
        self._validate_languages(source_language, target_languages)
        if len(texts) > self._settings.max_batch_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"batch size exceeds {self._settings.max_batch_size}",
            )

        self.ensure_loaded()
        result: dict[str, list[str]] = {}
        for target_language in target_languages:
            if target_language == source_language:
                result[target_language] = texts
                continue
            result[target_language] = self._translate_target(
                source_language,
                target_language,
                texts,
            )
        return result

    def _validate_languages(self, source_language: str, target_languages: list[str]) -> None:
        if source_language not in self._settings.supported_languages:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"unsupported source language: {source_language}",
            )
        unsupported = [
            language
            for language in target_languages
            if language not in self._settings.supported_languages
        ]
        if unsupported:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"unsupported target languages: {', '.join(unsupported)}",
            )

    def _translate_target(
        self,
        source_language: str,
        target_language: str,
        texts: list[str],
    ) -> list[str]:
        cached: list[str | None] = [
            ""
            if text == ""
            else self._cache.get(cache_key(self._settings.model_name, source_language, target_language, text))
            for text in texts
        ]
        missing_indexes = [index for index, value in enumerate(cached) if value is None]
        if missing_indexes:
            translated = self._generate(
                source_language,
                target_language,
                [texts[index] for index in missing_indexes],
            )
            for index, translated_text in zip(missing_indexes, translated, strict=True):
                key = cache_key(
                    self._settings.model_name,
                    source_language,
                    target_language,
                    texts[index],
                )
                self._cache.set(key, translated_text)
                cached[index] = translated_text
        return [value or "" for value in cached]

    def _generate(
        self,
        source_language: str,
        target_language: str,
        texts: list[str],
    ) -> list[str]:
        if not self._model or not self._tokenizer:
            raise RuntimeError("translation model is not loaded")
        if not texts:
            return []

        with self._inference_lock:
            self._tokenizer.src_lang = source_language
            encoded = self._tokenizer(
                texts,
                return_tensors="pt",
                padding=True,
                truncation=True,
                max_length=self._settings.max_input_tokens,
            )
            encoded = encoded.to(self._device)
            with torch.inference_mode():
                generated_tokens = self._model.generate(
                    **encoded,
                    forced_bos_token_id=self._tokenizer.get_lang_id(target_language),
                    max_length=self._settings.max_output_tokens,
                    num_beams=self._settings.num_beams,
                )
        return self._tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)


def cache_key(model_name: str, source_language: str, target_language: str, text: str) -> str:
    digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
    return f"{model_name}:{source_language}:{target_language}:{digest}"


settings = load_settings()
engine = TranslationEngine(settings)


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.preload_model:
        engine.ensure_loaded()
    yield


app = FastAPI(title="Inflap Translation Service", version="1.0.0", lifespan=lifespan)


@app.middleware("http")
async def require_mtls_peer_identity(request: Request, call_next):
    server_settings = load_server_settings()
    if server_settings.mtls_mode != "enforce" or request.scope.get("scheme") != "https":
        return await call_next(request)

    peer_identities = request.scope.get("mtls.peer")
    if not isinstance(peer_identities, MTLSPeerIdentities):
        peer_identities = MTLSPeerIdentities(spiffe_ids=(), dns_names=())
    if not peer_certificate_identity_allowed(peer_identities, server_settings):
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"error": "mTLS peer identity is not allowed"},
        )
    return await call_next(request)


@app.middleware("http")
async def require_internal_token(request: Request, call_next):
    if request.url.path in {"/health", "/health/live", "/health/ready"} or not settings.internal_service_token:
        return await call_next(request)

    provided = request.headers.get("X-Internal-Service-Token", "").strip()
    if not hmac.compare_digest(provided, settings.internal_service_token):
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"error": "invalid internal service token"},
        )
    return await call_next(request)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "model": settings.model_name,
        "modelLoaded": engine.loaded,
        "supportedLanguages": sorted(settings.supported_languages),
        "cacheSize": engine.cache_size,
    }


@app.get("/health/live")
def live() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/ready")
def ready() -> dict[str, object]:
    if not engine.loaded:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="translation model is not loaded",
        )
    return {
        "status": "ready",
        "model": settings.model_name,
        "supportedLanguages": sorted(settings.supported_languages),
        "cacheSize": engine.cache_size,
    }


@app.post("/v1/translate", response_model=TranslateResponse)
def translate(payload: TranslateRequest) -> TranslateResponse:
    translations = engine.translate(
        payload.source_language,
        payload.target_languages,
        payload.texts,
    )
    return TranslateResponse(translations=translations, model=settings.model_name)


async def serve_translation() -> None:
    server_settings = load_server_settings()
    validate_translation_mtls_config(server_settings)

    servers = [
        uvicorn.Server(
            uvicorn.Config(
                app,
                host=server_settings.host,
                port=server_settings.http_port,
                log_level="info",
            )
        )
    ]
    if server_settings.mtls_mode != "disabled":
        servers.append(
            uvicorn.Server(
                uvicorn.Config(
                    app,
                    host=server_settings.host,
                    port=server_settings.internal_http_tls_port,
                    log_level="info",
                    http=mtls_h11_protocol_class(),
                    **internal_mtls_uvicorn_ssl_options(server_settings),
                )
            )
        )

    await asyncio.gather(*(server.serve() for server in servers))


def main() -> None:
    asyncio.run(serve_translation())


if __name__ == "__main__":
    main()
