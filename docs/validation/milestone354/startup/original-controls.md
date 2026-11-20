# Repeated original 3.5.3 library controls

Six independently provisioned Apple Silicon runners used the verified original export and an empty writable directory per cold condition. Both policies ran on every host. All 30 processes completed cleanly, including six separate traced processes. The driver and operating-system caches can retain work across processes on a host.

| Host and first policy | Immediate cold (s) | First-use cold (s) | Immediate warm (s) | First-use warm (s) |
|---|---:|---:|---:|---:|
| original-metal immediate first | 90.849 | 20.102 | 14.695 | 15.687 |
| original-metal lazy first | 91.309 | 103.250 | 25.046 | 27.133 |
| repeat-87 immediate first | 146.172 | 45.067 | 24.284 | 26.920 |
| repeat-87 lazy first | 54.540 | 80.335 | 33.303 | 35.652 |
| repeat-88 immediate first | 145.075 | 33.094 | 31.361 | 29.845 |
| repeat-88 lazy first | 64.824 | 92.072 | 30.570 | 30.307 |

[Every phase and first playable frame](startup-attempts.csv) · [Original archives and commands](../README.md)
