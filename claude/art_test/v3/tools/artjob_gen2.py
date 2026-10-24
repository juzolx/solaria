"""Batch generator v2: txt2img / img2img + optional OpenPose ControlNet + optional IP-Adapter style ref.

jobs.json: [{"name", "prompt", "seeds", "neg"?, "init"?, "denoise"?, "pose"?, "pose_strength"?, "pose_end"?,
             "style"?, "style_weight"?, "style_type"?, "lora"?, "cfg"?, "steps"?}]
Outputs C:/ai/art_raw/<name>_s<seed>.png and a line in C:/ai/art_raw/log.jsonl.
"""
import json, os, sys, time, urllib.parse, urllib.request, uuid
sys.path.insert(0, r"C:\ai\scripts")
from artjob_gen import upload, NEG, HOST, OUT

WF = r"C:\ai\workflows\pixel_sdxl.json"


def build(job, seed):
    wf = json.load(open(WF, encoding="utf-8"))
    wf["6"]["inputs"]["text"] = job["prompt"]
    wf["7"]["inputs"]["text"] = job.get("neg", NEG)
    k = wf["3"]["inputs"]
    k.update(seed=seed, steps=job.get("steps", 24), cfg=job.get("cfg", 7.0))
    wf["10"]["inputs"]["strength_model"] = wf["10"]["inputs"]["strength_clip"] = job.get("lora", 1.0)
    wf["9"]["inputs"]["filename_prefix"] = "artjob2_" + job["name"]
    model = ["10", 0]
    if job.get("style"):
        wf["19"] = {"class_type": "LoadImage", "inputs": {"image": upload(job["style"])}}
        wf["15"] = {"class_type": "ImageScale", "inputs": {"image": ["19", 0], "upscale_method": "nearest-exact",
                                                           "width": 448, "height": 448, "crop": "center"}}
        wf["16"] = {"class_type": "IPAdapterModelLoader", "inputs": {"ipadapter_file": "ip-adapter-plus_sdxl_vit-h.safetensors"}}
        wf["17"] = {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"}}
        wf["18"] = {"class_type": "IPAdapterAdvanced", "inputs": {
            "model": ["10", 0], "ipadapter": ["16", 0], "image": ["15", 0], "clip_vision": ["17", 0],
            "weight": job.get("style_weight", 0.6), "weight_type": job.get("style_type", "style transfer"),
            "combine_embeds": "concat", "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only"}}
        model = ["18", 0]
    k["model"] = model
    if job.get("pose"):
        wf["12"] = {"class_type": "LoadImage", "inputs": {"image": upload(job["pose"])}}
        wf["13"] = {"class_type": "ControlNetLoader", "inputs": {"control_net_name": job.get("cn", "xinsir-openpose-sdxl-1.0.safetensors")}}
        wf["14"] = {"class_type": "ControlNetApplyAdvanced", "inputs": {
            "positive": ["6", 0], "negative": ["7", 0], "control_net": ["13", 0], "image": ["12", 0],
            "strength": job.get("pose_strength", 0.85), "start_percent": 0.0, "end_percent": job.get("pose_end", 0.8), "vae": ["11", 0]}}
        k["positive"], k["negative"] = ["14", 0], ["14", 1]
    if job.get("init"):
        wf["20"] = {"class_type": "LoadImage", "inputs": {"image": upload(job["init"])}}
        wf["21"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["20", 0], "vae": ["11", 0]}}
        k["latent_image"] = ["21", 0]
        k["denoise"] = job.get("denoise", 0.6)
        del wf["5"]
    return wf


def run(job, seed):
    wf = build(job, seed)
    body = json.dumps({"prompt": wf, "client_id": str(uuid.uuid4())}).encode()
    req = urllib.request.Request(HOST + "/prompt", data=body, headers={"Content-Type": "application/json"})
    try:
        pid = json.load(urllib.request.urlopen(req))["prompt_id"]
    except urllib.error.HTTPError as e:
        print("FAIL submit", job["name"], e.read()[:800], flush=True); return
    while True:
        hist = json.load(urllib.request.urlopen(f"{HOST}/history/{pid}"))
        if pid in hist:
            break
        time.sleep(0.7)
    h = hist[pid]
    if h.get("status", {}).get("status_str") != "success":
        print("FAIL", job["name"], seed, json.dumps(h.get("status"))[:800], flush=True); return
    for node in h["outputs"].values():
        for img in node.get("images", []):
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            open(os.path.join(OUT, f"{job['name']}_s{seed}.png"), "wb").write(urllib.request.urlopen(f"{HOST}/view?{q}").read())
    rec = {kk: v for kk, v in job.items() if kk != "seeds"}; rec["seed"] = seed
    with open(os.path.join(OUT, "log.jsonl"), "a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")
    print("ok", job["name"], seed, flush=True)


if __name__ == "__main__":
    t0 = time.time()
    for job in json.load(open(sys.argv[1], encoding="utf-8")):
        for s in job["seeds"]:
            if os.path.exists(os.path.join(OUT, f"{job['name']}_s{s}.png")) and not job.get("redo"):
                continue
            run(job, s)
    print(f"done in {time.time() - t0:.0f}s", flush=True)
