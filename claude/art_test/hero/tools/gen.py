"""Run ComfyUI jobs (txt2img / img2img / IP-Adapter / ControlNet) into C:/ai/art_raw/hero.
Usage: python -I gen.py jobs.json   (uses C:/ai/scripts/artjob_gen2.py graph builder)"""
import json, os, sys, time
sys.path.insert(0, r"C:\ai\scripts")
import artjob_gen2 as g
g.OUT = r"C:\ai\art_raw\hero"
t0 = time.time()
for job in json.load(open(sys.argv[1], encoding="utf-8")):
    for s in job["seeds"]:
        if os.path.exists(os.path.join(g.OUT, f"{job['name']}_s{s}.png")) and not job.get("redo"):
            continue
        g.run(job, s)
print(f"done in {time.time() - t0:.0f}s", flush=True)
