# python-ml-service (Phase 2)

FastAPI service that serves the crop disease classifier trained in `../ml-training` (Phase 1).
Full walkthrough: [`docs/PHASE_2_PYTHON_ML_SERVICE.md`](../docs/PHASE_2_PYTHON_ML_SERVICE.md).

```
app/
  main.py            create_app(): lifespan (loads model), request-id middleware, routers
  config.py          Settings from env vars / .env (pydantic-settings)
  dependencies.py    get_inference_service(): how routers get the model service
  core/logging.py    structlog: coloured locally, JSON in Docker
  core/errors.py     every error -> {"error", "detail", "request_id"}
  schemas/           Pydantic response models (the public API contract)
  services/          InferenceService: load checkpoint, preprocess, predict (no HTTP code)
  routers/           health.py, predict.py, models.py (thin HTTP layer)
scripts/export_tflite.py   standalone uv script: .pt -> .tflite for the mobile apps
tests/                     25 tests, run in-process with httpx (no server, no Phase 1 needed)
```

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness: 200 while the process runs |
| GET | `/ready` | Readiness: 200 when the model is loaded, else 503 |
| POST | `/api/v1/predict?top_k=3` | Multipart `file` (JPEG/PNG/WebP, ≤ 5 MB) → prediction |
| GET | `/api/v1/models` | Served model: version, classes, input size |
| GET | `/docs` | Interactive Swagger UI |

## Run locally

```bash
cd python-ml-service
uv sync
uv run pytest                                  # 25 tests, ~1 s

# Model from Phase 1 (run training first, see ml-training/README.md)
cp ../ml-training/outputs/checkpoints/{mobilenetv2_v1_best.pt,class_names.json} models/

cp .env.example .env                           # optional: every setting has a default
uv run uvicorn app.main:app --reload --port 8000
```

```bash
curl http://localhost:8000/ready
curl -F "file=@/path/to/leaf.jpg" "http://localhost:8000/api/v1/predict?top_k=3"
```

## Run with Docker

Needs Docker Desktop (or OrbStack) running. From the repo root:

```bash
docker compose up --build        # mounts python-ml-service/models read-only
curl http://localhost:8000/ready
docker compose down
```

The image is ≈1.5 GB: CPU-only torch alone is ~700 MB unpacked. Linux uses CPU wheels from
`download.pytorch.org/whl/cpu`, configured in `pyproject.toml`, so no CUDA libraries are included.

## Export for mobile (TFLite)

```bash
uv run scripts/export_tflite.py      # -> models/crop_disease_v1.tflite + crop_disease_v1.json
```

The script has its own dependencies (litert-torch needs torch < 2.15), so it runs in an isolated
environment that uv creates on the fly. It verifies the TFLite output against PyTorch.
The model takes `float32 [1, 224, 224, 3]` (NHWC, pixel values 0–1) and returns class probabilities.

## Troubleshooting

- **`Checkpoint not found` at startup**: copy the `.pt` file into `models/` (name must be
  `mobilenetv2_<MODEL_VERSION>_best.pt`).
- **Port 8000 in use**: `--port 8001`, or change the compose port mapping.
- **Want the Apple GPU locally**: `DEVICE=auto` in `.env` (Docker always uses CPU).
