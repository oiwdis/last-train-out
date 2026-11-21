# Build 110 shader verification

The revised game passed all 310 tests on Linux and macOS. The exporter observed 28 Metal source stages across the environment matrix and completed the compiler invocations. Its library round-trip check then rejected source hash `8ef3c154805e58db1875b78e78a93522879f10f70a9246d4b9b96a0c87cb4cc6`. The workflow stopped before publishing an application ZIP.

The same signed MSL is present as source in material group `4279a93253` and has a previously compiled library in groups `aa9d0127eb` and `b36709f370`. The verifier compared a source-only occurrence with the library found in a different group. The revised check retains each occurrence's original bytes, adds only requested compatible libraries and verifies the full output and the original library inventory. A local check round-tripped all 97 signed source groups from build 108 and verified all 361 previously compiled stages. Two targeted tests cover mixed storage of one source hash.

[Original job, compiler commands, GPU signposts and gameplay results](shader-verification-failure.zip) · [Hosted workflow](https://github.com/oiwdis/last-train-out/actions/runs/44857514846)
