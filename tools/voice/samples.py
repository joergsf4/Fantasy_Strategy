import json, os, sys, time
os.environ["COQUI_TOS_AGREED"] = "1"
import torch
from TTS.api import TTS

voices = json.load(open("voices.json"))
only = sys.argv[1:]
dev = "mps" if torch.backends.mps.is_available() else "cpu"
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
try:
    tts.to(dev)
    print("Geraet:", dev, flush=True)
except Exception as e:
    print("Geraet cpu (mps nicht moeglich):", e, flush=True)
    dev = "cpu"
os.makedirs("samples", exist_ok=True)
for fid, v in voices.items():
    if fid.startswith("_") or (only and fid not in only):
        continue
    t0 = time.time()
    try:
        tts.tts_to_file(text=v["line"], speaker=v["speaker"], language="de", speed=v["speed"], file_path=f"samples/{fid}.wav")
    except Exception as e:
        print("FEHLER", fid, str(e)[:200], flush=True)
        if dev == "mps":
            tts.to("cpu"); dev = "cpu"
            tts.tts_to_file(text=v["line"], speaker=v["speaker"], language="de", speed=v["speed"], file_path=f"samples/{fid}.wav")
    print(f"OK {fid} ({time.time() - t0:.1f}s)", flush=True)
print("FERTIG", flush=True)
