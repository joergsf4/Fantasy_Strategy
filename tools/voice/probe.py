import os, sys, time
os.environ["COQUI_TOS_AGREED"] = "1"      # Nutzungsbedingungen (nur nicht-kommerziell) bestaetigt
import torch
from TTS.api import TTS
dev = "mps" if torch.backends.mps.is_available() else "cpu"
print("Geraet:", dev, flush=True)
t0 = time.time()
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
print("Laden:", round(time.time() - t0), "s", flush=True)
sp = tts.synthesizer.tts_model.speaker_manager.speakers
names = list(sp.keys())
print(len(names), "Sprecher:", ", ".join(names), flush=True)
