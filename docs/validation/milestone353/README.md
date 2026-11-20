# Milestone 3.5.3 evidence

The primary comparison and release decision concern the immutable universal ZIP from PR commit `5534cf82c2e6e494cbf54add169e6ab4e8101b46`. Subsequent changes affect test drivers, diagnostic validation and evidence. The game, shipped assets, project configuration and export settings match the tested source. The bundle records the build's merge commit. The ZIP and PCK digests are recorded separately.

| Question | Evidence |
|---|---|
| What failed before any production change? | [Original native logs and reports](origin/README.md), [hypotheses, stacks and first failure history](../../RENDERER_CRASH_INVESTIGATION.md) |
| Which workload reproduces it? | [Minimal scene source](../../../tools/macos/renderer_probe.gd), [minimal native raw](probes/minimal-hosted.zip), [controlled full-game experiments](probes/workload.md), [original PCK shadow and backend attempts](exported-experiments/EXPERIMENTS.md) |
| When did Harlow, Warehouse B and fog change? | [Three revisions on one runner](history/README.md), [original and candidate matched over 12 locations and all three presets](candidate/comparison/COMPARISON.md) |
| What passed or failed in the exported candidate? | [Vulkan attempts, crash counts and startup distributions](candidate/stress/STRESS.md), [native Metal](alternatives/metal/STRESS.md), [Mobile](alternatives/mobile/STRESS.md), [independent repetitions](alternatives/repeats/README.md), [release integrity](candidate/release-integrity.json), [independent rebuilt app and matched second frame comparison](confirmation/README.md) |
| What do the renderers look like? | [Forward+, Mobile and Compatibility captures and measurements](backends/README.md), [Vulkan and native Metal from the exact candidate](alternatives/driver-comparison/README.md) |
| Did the player complete the route? | [Default recording](../../recording/milestone353-full-journey.mp4), [native Metal exported recording, gameplay report and sampler warning](alternatives/native-metal-journey-audited.zip) |
| Where are the checks and release decision? | [3.5.3 report](../../PERFORMANCE_MILESTONE353.md), [M1 owner procedure](../../M1_MILESTONE353.md), [primary workflow](https://github.com/oiwdis/last-train-out/actions/runs/44675841777) |

On a Mac with Godot 4.5.1, run these source experiments from the checkout. Set `GODOT` to the executable inside the editor app. Use a new output directory for each group. The minimal scene is standalone. The full-game and history cases require imported assets and local objects for 7df2f5a, cc50670 and 6038bfc. CI fetches those exact revisions and logs each attempt. Experiments stop at the configured deadlines and return a failing status for a device loss or an incomplete workload.

```bash
python3 tools/macos/renderer_lab.py "$GODOT" minimal /tmp/lto353-minimal
python3 tools/macos/renderer_lab.py "$GODOT" workload /tmp/lto353-workload
python3 tools/macos/renderer_lab.py "$GODOT" history /tmp/lto353-history
python3 tools/macos/renderer_lab.py "$GODOT" backends /tmp/lto353-backends
```

The following checks verify the retained ZIP bytes and rebuild the principal performance table without access to a Mac. The raw capture and timing ZIP in this checkout contains the original JSON, partial JSONL, process logs, stage screenshots and media metadata. Its large default MP4 is stored separately in the recording directory. The original GitHub artifact contains both.

```bash
(cd docs/validation/milestone353 && shasum -a 256 -c SHA256SUMS)
check_dir=$(mktemp -d)
unzip -q docs/validation/milestone353/candidate/performance-and-journey-logs.zip 'performance/*' -d "$check_dir"
python3 docs/validation/milestone351/summarize_paired.py "$check_dir/performance" "$check_dir/tables"
diff -r docs/validation/milestone353/candidate/comparison "$check_dir/tables"
```
