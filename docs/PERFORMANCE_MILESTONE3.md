# Milestone 3 performance measurements

Historical M2.5-to-fog comparison. See [the finalization comparison](PERFORMANCE_MILESTONE3_FINALIZATION.md) for the three-station route against `ebfa2689`.

Measured on **Linux, Intel Xeon Platinum 8573C, Mesa 25.0.7 llvmpipe (LLVM 19.1.7, 256 bits), Godot 4.5.1 Compatibility/OpenGL**. This is a software GPU in a shared cloud machine, not an Apple Silicon Mac. These numbers do not establish physical M1 playability or 60 FPS.

M2.5: `8cde10c`, detached checkout. M3: fog implementation from `6b47802` with HUD/rehearsal refinements; the rendered formulas/defaults are unchanged in the final revision. The existing `benchmark_milestone25.gd` supplies the baseline; `benchmark_fog.gd` retains its identical platform/warehouse positions, targets, FOV and preset procedure. Only fog authority is frozen for stable observation: 210 m behind the player (distant), then 8 m behind (near front). Both runs use the same environment, audio Dummy, 8 warmup frames and 24 directly timed rendered frame intervals per case, VSync requested off, no fixed FPS. Presets retain authored shadows, lighting and resolution scales. Actual viewport was **1180 × 812 in all three reports**: the cloud window manager resized the requested 960 × 540 window. Actual dimensions, rather than requested flags, govern comparison.

| View / preset | M2.5 median ms | M3 distant ms | Change | M3 near front ms | Near-front p95 ms |
|---|---:|---:|---:|---:|---:|
| Platform / Low | 104.99 | 114.27 | +8.8% | 110.50 | 119.15 |
| Platform / Medium | 254.99 | 279.00 | +9.4% | 267.83 | 368.19 |
| Platform / High | 1843.29 | 1825.95 | -0.9% | 1848.17 | 2131.51 |
| Warehouse B / Low | 112.03 | 113.27 | +1.1% | 103.13 | 111.88 |
| Warehouse B / Medium | 289.04 | 291.11 | +0.7% | 286.29 | 334.81 |
| Warehouse B / High | 1805.79 | 1799.52 | -0.3% | 1784.00 | 1990.61 |

Interpretation: distant-fog median overhead ranged from -0.9% to +9.4% in these short samples; small negative values are noise, not claimed optimization. Added render work is roughly 5–9 draw calls. The existing High preset is prohibitively slow on this software renderer, with or without advancing fog. The observer haze and small sheet budget keep the new effect cost bounded, but this does not prove acceptable performance on older Macs with upcoming photorealistic assets. The near-front pass did not produce a systematic additional slowdown in these views. Shared-host load and short samples (including a distant Warehouse B/High p95 outlier) limit precision. Headless scenario rehearsal completed during initial scene setup of the first two passes; the near-front pass ran after its rehearsal. No other graphical Godot process ran during sampling.

The UI's “critical” status may reflect the train being farther behind than the sampled player; the benchmark's near-front condition is explicitly **player clearance = 8 m**, not a subjective screenshot category. No fully engulfed or prolonged thermal-load benchmark was performed.

A separate 100,000-step headless microbenchmark measured **408.927 ms total / 4.08927 μs per tick**, including fixed-step authority, seeded events and four independent exposure components. It excludes route projection, scene integration and rendering. At 10 ticks/s that bookkeeping is small relative to render cost. Source: `tools/benchmark_fog_simulation.gd`.

Raw reports: [baseline](validation/milestone3/performance-baseline.json), [distant](validation/milestone3/performance-distant.json), [near front](validation/milestone3/performance-critical.json), [simulation](validation/milestone3/performance-simulation.json).

Reproduce using Godot 4.5.1 and a graphical display:

```sh
godot --path . --audio-driver Dummy --rendering-method gl_compatibility --resolution 960x540 --script res://tools/benchmark_fog.gd -- --fog-state=distant --out=/tmp/distant.json
godot --path . --audio-driver Dummy --rendering-method gl_compatibility --resolution 960x540 --script res://tools/benchmark_fog.gd -- --fog-state=critical --out=/tmp/critical.json
godot --headless --path . --script res://tools/benchmark_fog_simulation.gd
```

Run the original benchmark on the detached baseline for comparison. Use identical actual viewport sizes and graphics renderer. Do not compare these measurements directly to M2.6's different-hardware cohort. The preserved macOS pipeline validates actual universal launches; it is not a physical-M1 performance benchmark.
