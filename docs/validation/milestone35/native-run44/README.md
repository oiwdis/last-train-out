# Initial native cohort — run 44

Source head `4fbb22a03cdbfbe23ad2c0a9654ff98ef32b151f`; [workflow](https://github.com/oiwdis/last-train-out/actions/runs/44454434954). Performance data are complete. Build and fresh-download self-tests passed: 46 ARM headless, 49 ARM windowed, 46 Intel headless. The packaged benchmark smoke validates all 72 entry/steady matrix cases with short samples; it is not the 600-frame performance cohort.

**The recording did not finish.** `incomplete-recording` preserves the failure at Save/Continue: the saved file was at Blackwater, but render preparation paused physics while restoration resolved rider/cargo positions against unsynchronized Harlow train bodies. The recorded journey stopped at 21:33.5. No full MP4 was produced by this run. The workflow's former `continue-on-error` handling displayed success; this was not gameplay acceptance.

Commit `140ce820c087d8a28734b7bab3ed14135d7cc527` adds a regression reproducing rider and cargo displacement, waits for rendering preparation before resolving physical supports, strengthens saved-world/position assertions, and makes failed evidence fail finalization after artifact uploads. Refer to the main review for the completed replacement run.
