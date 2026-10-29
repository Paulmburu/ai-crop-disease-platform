"""HTTP-level tests for every endpoint and every error path."""

import httpx
import pytest

from .conftest import CLASS_NAMES, image_bytes


async def test_health_and_ready_when_loaded(client):
    assert (await client.get("/health")).json() == {"status": "ok", "model_loaded": True, "model_version": "v1"}
    r = await client.get("/ready")
    assert r.status_code == 200 and r.json()["status"] == "ready"


async def test_ready_is_503_when_model_missing(unloaded_client):
    assert (await unloaded_client.get("/health")).status_code == 200  # process alive
    assert (await unloaded_client.get("/ready")).status_code == 503  # but not ready


@pytest.mark.parametrize(("fmt", "mime"), [("JPEG", "image/jpeg"), ("PNG", "image/png"), ("WEBP", "image/webp")])
async def test_predict_returns_ranked_predictions(client, fmt, mime):
    r = await client.post("/api/v1/predict?top_k=2", files={"file": (f"leaf.{fmt}", image_bytes(fmt), mime)})
    assert r.status_code == 200, r.text
    body = r.json()
    assert len(body["top_k"]) == 2
    assert body["prediction"] == body["top_k"][0]
    assert body["top_k"][0]["confidence"] >= body["top_k"][1]["confidence"]
    assert body["prediction"]["class_name"] in CLASS_NAMES
    assert body["model_version"] == "v1" and body["inference_ms"] > 0
    assert r.headers["X-Request-ID"]


async def test_request_id_is_propagated(client):
    r = await client.get("/health", headers={"X-Request-ID": "abc123"})
    assert r.headers["X-Request-ID"] == "abc123"


async def test_wrong_content_type_is_415(client):
    r = await client.post("/api/v1/predict", files={"file": ("a.txt", b"hello", "text/plain")})
    assert r.status_code == 415
    assert r.json()["error"] == "unsupported_media_type"


async def test_corrupt_image_is_400(client):
    r = await client.post("/api/v1/predict", files={"file": ("a.jpg", b"not really a jpeg", "image/jpeg")})
    assert r.status_code == 400
    assert r.json()["error"] == "invalid_image"


async def test_empty_file_is_400(client):
    r = await client.post("/api/v1/predict", files={"file": ("a.jpg", b"", "image/jpeg")})
    assert r.status_code == 400


async def test_oversized_upload_is_413(client):
    big = b"\xff" * (5 * 1024 * 1024 + 1)
    r = await client.post("/api/v1/predict", files={"file": ("big.jpg", big, "image/jpeg")})
    assert r.status_code == 413
    assert r.json()["error"] == "payload_too_large"


async def test_missing_file_is_422_with_same_error_shape(client):
    r = await client.post("/api/v1/predict")
    assert r.status_code == 422
    assert set(r.json()) == {"error", "detail", "request_id"}


async def test_top_k_out_of_range_is_422(client):
    r = await client.post("/api/v1/predict?top_k=0", files={"file": ("a.jpg", image_bytes(), "image/jpeg")})
    assert r.status_code == 422


async def test_predict_is_503_when_model_missing(unloaded_client):
    r = await unloaded_client.post("/api/v1/predict", files={"file": ("a.jpg", image_bytes(), "image/jpeg")})
    assert r.status_code == 503
    assert r.json()["error"] == "model_not_loaded"


async def test_models_endpoint(client, unloaded_client):
    info = (await client.get("/api/v1/models")).json()
    assert info["class_names"] == CLASS_NAMES and info["image_size"] == 224
    assert (await unloaded_client.get("/api/v1/models")).status_code == 503


async def test_unknown_route_uses_error_shape(client):
    r = await client.get("/nope")
    assert r.status_code == 404 and r.json()["error"] == "not_found"


async def test_low_confidence_is_uncertain(tmp_path):
    from app.main import create_app
    from app.services.inference import InferenceService

    from .conftest import make_checkpoint

    # A random 3-class model is never 99.9% sure, so every prediction must come back "uncertain".
    service = InferenceService(make_checkpoint(tmp_path / "m.pt", threshold=0.999))
    service.load()
    app = create_app(service=service)
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as c:
        r = await c.post("/api/v1/predict", files={"file": ("a.jpg", image_bytes(), "image/jpeg")})
    body = r.json()
    assert r.status_code == 200 and body["status"] == "uncertain" and body["confidence_threshold"] == 0.999


def test_old_checkpoint_without_threshold_defaults_to_half(tmp_path):
    from app.services.inference import InferenceService

    from .conftest import make_checkpoint

    service = InferenceService(make_checkpoint(tmp_path / "m.pt", threshold=None))
    service.load()
    assert service.confidence_threshold == 0.5
