# Benchmark results

Generated 2026-10-29 16:37 on this machine. Network figures in D3 are modelled from the stated profiles, not measured on a phone.

## D1 Model size

| File | Size |
|---|---|
| `mobilenetv2_v1_best.pt` | 9.2 MB |
| `crop_disease_v1.tflite` | 9.0 MB |

## D2 On-device inference (LiteRT, this laptop CPU)

100 runs, input [1, 224, 224, 3]: p50 **1.9 ms**, p95 1.9 ms.

No network involved, so this is the whole cost of a diagnosis on the device.

## D3 Backend /predict

Server time measured on localhost (100 requests): p50 **18 ms**, p95 19 ms.

Modelled time for a phone to get a diagnosis from the backend (upload + round trip + server time; network profiles are assumptions):

| Network | Uplink | RTT | Test photo (12 KB, measured) | Phone photo (3 MB, assumed) |
|---|---|---|---|---|
| Wi-Fi | 20,000 kbit/s | 20 ms | **43 ms** | **1,296 ms** |
| 4G | 5,000 kbit/s | 60 ms | **99 ms** | **5,111 ms** |
| 3G | 750 kbit/s | 200 ms | **354 ms** | **33,773 ms** |
| 2G (EDGE) | 100 kbit/s | 600 ms | **1,641 ms** | **252,276 ms** |

Compare with D2: on-device inference needs no upload at all.

## D4 RAG /ask (local Ollama)

First call: **2,965 ms** (includes loading the model if Ollama was idle). Warm calls (5): p50 **3,523 ms**.

This is why advice is an online add-on and never blocks the diagnosis.
