from __future__ import annotations

import importlib.util
import os
import ssl
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import patch


def load_main_module():
    fastapi_stub = types.ModuleType("fastapi")
    fastapi_stub.FastAPI = _FastAPIStub
    fastapi_stub.HTTPException = _HTTPExceptionStub
    fastapi_stub.Request = object
    fastapi_stub.status = types.SimpleNamespace(
        HTTP_400_BAD_REQUEST=400,
        HTTP_401_UNAUTHORIZED=401,
        HTTP_503_SERVICE_UNAVAILABLE=503,
    )
    responses_stub = types.ModuleType("fastapi.responses")
    responses_stub.JSONResponse = _JSONResponseStub
    pydantic_stub = types.ModuleType("pydantic")
    pydantic_stub.BaseModel = object
    pydantic_stub.Field = lambda *args, **kwargs: None
    pydantic_stub.field_validator = lambda *args, **kwargs: _identity_decorator
    uvicorn_stub = types.ModuleType("uvicorn")
    uvicorn_stub.Config = _UvicornConfigStub
    uvicorn_stub.Server = _UvicornServerStub
    torch_stub = types.SimpleNamespace(
        cuda=types.SimpleNamespace(is_available=lambda: False),
        inference_mode=lambda: _NoopContext(),
    )
    transformers_stub = types.SimpleNamespace(
        M2M100ForConditionalGeneration=types.SimpleNamespace(from_pretrained=lambda _: object()),
        M2M100Tokenizer=types.SimpleNamespace(from_pretrained=lambda _: object()),
    )
    sys.modules.setdefault("fastapi", fastapi_stub)
    sys.modules.setdefault("fastapi.responses", responses_stub)
    sys.modules.setdefault("pydantic", pydantic_stub)
    sys.modules.setdefault("torch", torch_stub)
    sys.modules.setdefault("transformers", transformers_stub)
    sys.modules.setdefault("uvicorn", uvicorn_stub)

    module_path = Path(__file__).resolve().parents[1] / "app" / "main.py"
    spec = importlib.util.spec_from_file_location("translation_main_under_test", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("failed to load translation service module")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class _NoopContext:
    def __enter__(self):
        return None

    def __exit__(self, exc_type, exc, tb):
        return False


class _FastAPIStub:
    def __init__(self, *args, **kwargs):
        pass

    def middleware(self, *_args, **_kwargs):
        return _identity_decorator

    def get(self, *_args, **_kwargs):
        return _identity_decorator

    def post(self, *_args, **_kwargs):
        return _identity_decorator


class _HTTPExceptionStub(Exception):
    def __init__(self, status_code: int, detail: str):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


class _JSONResponseStub:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


def _identity_decorator(func):
    return func


class _UvicornConfigStub:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


class _UvicornServerStub:
    def __init__(self, config):
        self.config = config

    async def serve(self):
        return None


class TranslationMTLSConfigTest(unittest.TestCase):
    def test_load_server_settings_parses_internal_mtls_listener(self):
        module = load_main_module()

        with patch.dict(
            os.environ,
            {
                "HTTP_PORT": "8094",
                "INTERNAL_HTTP_TLS_PORT": "9494",
                "MTLS_MODE": "enforce",
                "MTLS_CA_CERT_PATH": "/run/mtls/ca.crt",
                "MTLS_SERVER_CERT_PATH": "/run/mtls/translation-service/server.crt",
                "MTLS_SERVER_KEY_PATH": "/run/mtls/translation-service/server.key",
                "MTLS_ALLOWED_SPIFFE_IDS": "spiffe://inflap/test/excursion-service",
                "MTLS_ALLOWED_DNS_NAMES": "excursion-service",
            },
            clear=False,
        ):
            settings = module.load_server_settings()

        self.assertEqual(settings.http_port, 8094)
        self.assertEqual(settings.internal_http_tls_port, 9494)
        self.assertEqual(settings.mtls_mode, "enforce")
        self.assertEqual(settings.mtls_ca_cert_path, "/run/mtls/ca.crt")
        self.assertEqual(settings.mtls_server_cert_path, "/run/mtls/translation-service/server.crt")
        self.assertEqual(settings.mtls_server_key_path, "/run/mtls/translation-service/server.key")
        self.assertEqual(settings.mtls_allowed_spiffe_ids, ("spiffe://inflap/test/excursion-service",))
        self.assertEqual(settings.mtls_allowed_dns_names, ("excursion-service",))

    def test_validate_translation_mtls_config_allows_disabled_mode(self):
        module = load_main_module()

        module.validate_translation_mtls_config(
            module.ServerSettings(
                host="0.0.0.0",
                http_port=8094,
                internal_http_tls_port=0,
                mtls_mode="disabled",
                mtls_ca_cert_path="",
                mtls_server_cert_path="",
                mtls_server_key_path="",
                mtls_allowed_spiffe_ids=(),
                mtls_allowed_dns_names=(),
            )
        )

    def test_validate_translation_mtls_config_requires_dedicated_port_when_enabled(self):
        module = load_main_module()

        with self.assertRaisesRegex(ValueError, "INTERNAL_HTTP_TLS_PORT is required"):
            module.validate_translation_mtls_config(
                module.ServerSettings(
                    host="0.0.0.0",
                    http_port=8094,
                    internal_http_tls_port=0,
                    mtls_mode="enforce",
                    mtls_ca_cert_path="/run/mtls/ca.crt",
                    mtls_server_cert_path="/run/mtls/server.crt",
                    mtls_server_key_path="/run/mtls/server.key",
                    mtls_allowed_spiffe_ids=(),
                    mtls_allowed_dns_names=(),
                )
            )

    def test_build_internal_mtls_uvicorn_config_requires_client_cert_in_enforce_mode(self):
        module = load_main_module()
        settings = module.ServerSettings(
            host="0.0.0.0",
            http_port=8094,
            internal_http_tls_port=9494,
            mtls_mode="enforce",
            mtls_ca_cert_path="/run/mtls/ca.crt",
            mtls_server_cert_path="/run/mtls/translation-service/server.crt",
            mtls_server_key_path="/run/mtls/translation-service/server.key",
            mtls_allowed_spiffe_ids=(),
            mtls_allowed_dns_names=(),
        )

        options = module.internal_mtls_uvicorn_ssl_options(settings)

        self.assertEqual(options["ssl_cert_reqs"], ssl.CERT_REQUIRED)
        self.assertEqual(options["ssl_ca_certs"], "/run/mtls/ca.crt")
        self.assertEqual(options["ssl_certfile"], "/run/mtls/translation-service/server.crt")
        self.assertEqual(options["ssl_keyfile"], "/run/mtls/translation-service/server.key")

    def test_extract_peer_certificate_identities_reads_san_uri_and_dns(self):
        module = load_main_module()

        identities = module.extract_peer_certificate_identities(
            {
                "subjectAltName": (
                    ("URI", "spiffe://inflap/test/excursion-service"),
                    ("DNS", "excursion-service"),
                    ("DNS", "ignored.example"),
                )
            }
        )

        self.assertEqual(identities.spiffe_ids, ("spiffe://inflap/test/excursion-service",))
        self.assertEqual(identities.dns_names, ("excursion-service", "ignored.example"))

    def test_peer_certificate_identity_allowed_requires_configured_identity(self):
        module = load_main_module()
        settings = module.ServerSettings(
            host="0.0.0.0",
            http_port=8094,
            internal_http_tls_port=9494,
            mtls_mode="enforce",
            mtls_ca_cert_path="/run/mtls/ca.crt",
            mtls_server_cert_path="/run/mtls/translation-service/server.crt",
            mtls_server_key_path="/run/mtls/translation-service/server.key",
            mtls_allowed_spiffe_ids=("spiffe://inflap/test/excursion-service",),
            mtls_allowed_dns_names=("excursion-service",),
        )

        self.assertTrue(
            module.peer_certificate_identity_allowed(
                module.MTLSPeerIdentities(
                    spiffe_ids=("spiffe://inflap/test/excursion-service",),
                    dns_names=(),
                ),
                settings,
            )
        )
        self.assertFalse(
            module.peer_certificate_identity_allowed(
                module.MTLSPeerIdentities(
                    spiffe_ids=("spiffe://inflap/test/unknown-service",),
                    dns_names=("unknown-service",),
                ),
                settings,
            )
        )


if __name__ == "__main__":
    unittest.main()
