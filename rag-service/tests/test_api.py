from app.services.rag import RAGService

from .conftest import FakeLLM, make_client


async def test_ask_returns_answer_with_numbered_sources(client):
    r = await client.post("/api/v1/ask", json={"question": "How do I manage tomato late blight?"})
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["grounded"] is True and body["model"] == "fake-llm"
    assert [s["index"] for s in body["sources"]] == list(range(1, len(body["sources"]) + 1))
    first = next(s for s in body["sources"] if s["class_name"] == "Tomato_Late_blight")
    assert first["references"] == ["https://example.org/late-blight", "https://example.org/other"]


async def test_ask_with_class_name_filters_sources(client):
    r = await client.post("/api/v1/ask", json={"question": "What are the symptoms?",
                                                "class_name": "Potato___Early_blight"})
    assert {s["class_name"] for s in r.json()["sources"]} == {"Potato___Early_blight"}


async def test_ask_validation_errors_use_error_shape(client):
    for payload in ({}, {"question": "x"}, {"question": "a" * 501}, {"question": "valid?", "top_k": 0}):
        r = await client.post("/api/v1/ask", json=payload)
        assert r.status_code == 422, payload
        assert r.json()["error"] == "validation_error"


async def test_llm_down_returns_503(store):
    async with make_client(RAGService(store, FakeLLM(fail=True), max_distance=0.95)) as c:
        r = await c.post("/api/v1/ask", json={"question": "late blight management"})
    assert r.status_code == 503 and r.json()["error"] == "llm_unavailable"


async def test_health_and_ready(client, store):
    assert (await client.get("/health")).json()["chunks"] == store.count()
    assert (await client.get("/ready")).status_code == 200
    async with make_client(RAGService(store, FakeLLM(ready=False))) as c:
        r = await c.get("/ready")
    assert r.status_code == 503 and r.json()["llm_ready"] is False


async def test_classes_endpoint(client):
    assert (await client.get("/api/v1/classes")).json() == ["Potato___Early_blight", "Tomato_Late_blight"]


async def test_request_id_echoed(client):
    r = await client.get("/health", headers={"X-Request-ID": "req-1"})
    assert r.headers["X-Request-ID"] == "req-1"
