# Ditto Talking Head

**Ditto Talking Head** is a high-performance, containerized pipeline for generating photo-realistic talking-head videos from a single portrait image and an audio track.  
It combines state-of-the-art deep-learning models with NVIDIA TensorRT for real-time inference on modern GPUs.

---

## Features
- **One-shot portrait animation** – drive any face with any voice  
- **GPU-optimized** – TensorRT engines for ≤ 8 ms/frame on Ampere+  
- **Docker-first workflow** – zero host-side dependency conflicts  
- **Automatic engine selection** – pre-built Ampere engines or on-the-fly rebuild for older GPUs  
- **ONNX → TensorRT converter** – easily re-target new precision / hardware  

---

## Quick Start (Docker)

```bash
# 1. Clone repo
git clone https://github.com/feifel/ditto-talkinghead.git
cd ditto-talkinghead

# 2. Download the models from Huggingface
git clone --depth 1 --filter=blob:none --sparse https://huggingface.co/digital-avatar/ditto-talkinghead checkpoints && git -C checkpoints sparse-checkout set ditto_cfg ditto_onnx

# 3. Build image
docker build -t ditto-talkinghead .

# 4. Run the docker image
docker run --gpus all --rm \
  -v "$(pwd)/checkpoints:/app/checkpoints" \
  -v "$(pwd)/example:/app/example" \
  -v "$(pwd)/output:/app/tmp" \
  -it ditto-talkinghead \/bin/bash

# 5. Generate a video result001.mp4 from portrait image potrait001.png and speech audio speech001.wav
python /app/ditto-talkinghead/inference.py \
  --data_root "./checkpoints/ditto_trt_custom" \
  --cfg_pkl "./checkpoints/ditto_cfg/v0.4_hubert_cfg_trt.pkl" \
  --audio_path "./example/speech001.wav" \
  --source_path "./example/portrait001.jpg" \
  --output_path "/app/tmp/result001.mp4"
```

Step 4 & 5 can also be executed in one:
```bash
docker run --gpus all --rm \
  -v "$(pwd)/checkpoints:/app/checkpoints" \
  -v "$(pwd)/example:/app/example" \
  -v "$(pwd)/output:/app/tmp" \
  ditto-talkinghead \
  python /app/ditto-talkinghead/inference.py \
    --data_root "./checkpoints/ditto_trt_custom" \
    --cfg_pkl "./checkpoints/ditto_cfg/v0.4_hubert_cfg_trt.pkl" \
    --audio_path "./example/speech001.wav" \
    --source_path "./example/portrait001.jpg" \
    --output_path "/app/tmp/result002.mp4"
```

Image size should be 512x512px if your image contains the head only, or 1080x1920px if it shows more than the head. It supports jpeg and png formats, maybe also others.

If you need to improve the image quality you can use:
https://imgupscaler.com/?utm_source=ai-search.io

The audio should be 16kHz. wav but it will be converted if you use different formats. You can also convert it with this command:
```bash
ffmpeg -i "input.any" -ac 1 -ar 16000 -c:a pcm_s16le "output.wav"
```
Video RAM went up from 1.4 GB to 3.9 GB during the creation of result001.mp4. It took 15s to render the 4.3s video on my RTX 4070 TI. The GPU was idle most of the time, so I hope that the online version (/app/ditto-talkinghead/stream_pipeline_online.py) will be usable for realtime video conversion.

## TODO
Test streaming functionality, maybe in combination with https://github.com/feifel/kani-tts.