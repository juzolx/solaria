"""Batch generator for the Solaria art style test (txt2img and img2img via ComfyUI API).

Usage: python -I artjob_gen.py jobs.json
jobs.json: [{"name": "human_body", "prompt": "...", "seeds": [1,2,3], "neg": "...",
             "w": 1024, "h": 1024, "init": "C:/path.png" (optional), "denoise": 0.6,
             "lora": 1.0, "cfg": 7, "steps": 24}]
Outputs: C:/ai/art_raw/<name>_s<seed>.png, plus a log line per image in C:/ai/art_raw/log.jsonl
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request
import uuid

HOST = "http://127.0.0.1:8188"
WF = r"C:\ai\workflows\pixel_sdxl.json"
OUT = r"C:\ai\art_raw"
NEG = ("3d render, realistic, photo, blurry, text, watermark, signature, multiple characters, "
       "cropped, cut off, frame, border, scenery, landscape, ground shadow, gradient background")


def upload(path):
    name = "artjob_" + os.path.basename(path)
    data = open(path, "rb").read()
    bnd = uuid.uuid4().hex
    body = (f"--{bnd}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
            f"Content-Type: image/png\r\n\r\n").encode() + data + \
           f"\r\n--{bnd}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n--{bnd}--\r\n".encode()
    req = urllib.request.Request(HOST + "/upload/image", data=body,
                                 headers={"Content-Type": f"multipart/form-data; boundary={bnd}"})
    return json.load(urllib.request.urlopen(req))["name"]


def run(job, seed):
    wf = json.load(open(WF, encoding="utf-8"))
    wf["6"]["inputs"]["text"] = job["prompt"]
    wf["7"]["inputs"]["text"] = job.get("neg", NEG)
    wf["3"]["inputs"]["seed"] = seed
    wf["3"]["inputs"]["steps"] = job.get("steps", 24)
    wf["3"]["inputs"]["cfg"] = job.get("cfg", 7.0)
    wf["5"]["inputs"]["width"] = job.get("w", 1024)
    wf["5"]["inputs"]["height"] = job.get("h", 1024)
    wf["10"]["inputs"]["strength_model"] = job.get("lora", 1.0)
    wf["10"]["inputs"]["strength_clip"] = job.get("lora", 1.0)
    wf["9"]["inputs"]["filename_prefix"] = "artjob_" + job["name"]
    if job.get("init"):
        nm = upload(job["init"])
        wf["20"] = {"class_type": "LoadImage", "inputs": {"image": nm}}
        wf["21"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["20", 0], "vae": ["11", 0]}}
        wf["3"]["inputs"]["latent_image"] = ["21", 0]
        wf["3"]["inputs"]["denoise"] = job.get("denoise", 0.6)
        del wf["5"]
    body = json.dumps({"prompt": wf, "client_id": str(uuid.uuid4())}).encode()
    req = urllib.request.Request(HOST + "/prompt", data=body, headers={"Content-Type": "application/json"})
    pid = json.load(urllib.request.urlopen(req))["prompt_id"]
    while True:
        hist = json.load(urllib.request.urlopen(f"{HOST}/history/{pid}"))
        if pid in hist:
            break
        time.sleep(0.7)
    h = hist[pid]
    if h.get("status", {}).get("status_str") != "success":
        print("FAIL", job["name"], seed, json.dumps(h.get("status"))[:500], flush=True)
        return
    for node in h["outputs"].values():
        for img in node.get("images", []):
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            data = urllib.request.urlopen(f"{HOST}/view?{q}").read()
            path = os.path.join(OUT, f"{job['name']}_s{seed}.png")
            open(path, "wb").write(data)
    rec = {k: v for k, v in job.items() if k != "seeds"}
    rec["seed"] = seed
    with open(os.path.join(OUT, "log.jsonl"), "a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")
    print("ok", job["name"], seed, flush=True)


def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = json.load(open(sys.argv[1], encoding="utf-8"))
    t0 = time.time()
    for job in jobs:
        for s in job["seeds"]:
            if os.path.exists(os.path.join(OUT, f"{job['name']}_s{s}.png")) and not job.get("redo"):
                continue
            run(job, s)
    print(f"done in {time.time()-t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
