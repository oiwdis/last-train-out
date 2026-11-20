#!/usr/bin/env python3
"""Original deterministic synthesis, stdlib only; no external audio samples."""
import math, random, struct, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio/fog'
ROOT.mkdir(parents=True, exist_ok=True)
rate = 22050
for kind in ('rumble', 'wind', 'breath', 'metal'):
    rng = random.Random(3001)
    duration = 8 if kind != 'metal' else 3
    data, filtered = bytearray(), 0.0
    for i in range(rate * duration):
        t = i / rate
        filtered = filtered * 0.96 + rng.uniform(-1, 1) * 0.04
        if kind == 'rumble':
            v = 0.35 * math.sin(math.tau * 43 * t) + 0.2 * math.sin(math.tau * 61 * t) + filtered
        elif kind == 'wind':
            v = filtered * (1.3 + 0.5 * math.sin(math.tau * t / 8))
        elif kind == 'breath':
            v = filtered * max(0, math.sin(math.tau * t / 4)) ** 2 * 3
        else:
            v = sum(math.sin(math.tau * hz * t) / (j + 2) for j, hz in enumerate((213, 347, 541, 827))) * math.exp(-2.3 * t)
        # Seamless quiet loop edges; the cue gets a short click-prevention attack.
        fade = min(1, t / 0.04, (duration - t) / 0.04)
        data.extend(struct.pack('<h', int(max(-0.95, min(0.95, v * fade)) * 32767)))
    with wave.open(str(ROOT / f'{kind}.wav'), 'wb') as output:
        output.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        output.writeframes(data)
    (ROOT / f'{kind}.wav.import').write_text(f'''[remap]
importer="wav"
type="AudioStreamWAV"
path="res://.godot/imported/{kind}.wav-generated.sample"
[deps]
source_file="res://assets/audio/fog/{kind}.wav"
dest_files=["res://.godot/imported/{kind}.wav-generated.sample"]
[params]
force/8_bit=false
force/mono=false
force/max_rate=false
edit/trim=false
edit/normalize=false
edit/loop_mode={0 if kind == 'metal' else 2}
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
''')
