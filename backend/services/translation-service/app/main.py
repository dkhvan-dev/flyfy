from __future__ import annotations

import hashlib
import hmac
import os
from collections import OrderedDict
from contextlib import asynccontextmanager
from dataclasses import dataclass
from threading import RLock
from typing import Annotated

import torch
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator
from transformers import M2M100ForConditionalGeneration, M2M100Tokenizer


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
