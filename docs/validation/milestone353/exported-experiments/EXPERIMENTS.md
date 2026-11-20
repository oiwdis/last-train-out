# Experiments on the original release pack

All cases ran the same exported 6038bfcd game at 960×540, High. Each runner used isolated writable application caches. The shadow cohorts rotated control and three covered atlas configurations. All original camera, material, and geometry work remained in place. Full preset shadow sizes were restored before the final camera drain. Backend cohorts paired a fresh cache with a warm launch on that same cache. A method/driver mismatch or inability to write a full report fails the attempt.

| Raw archive | Method/driver | Covered atlas change | Cache | Passed / attempted | GPU loss | Other failure | Ready min / median / max, s |
|---|---|---|---|---:|---:|---:|---|
| [followup-shadow-replica-a.zip](followup-shadow-replica-a.zip) | forward_plus/vulkan | control | cold | 3/4 | 1 | 0 | 22.623 / 22.722 / 63.807 |
| [followup-shadow-replica-a.zip](followup-shadow-replica-a.zip) | forward_plus/vulkan | directional | cold | 3/4 | 1 | 0 | 22.960 / 23.252 / 23.856 |
| [followup-shadow-replica-a.zip](followup-shadow-replica-a.zip) | forward_plus/vulkan | local | cold | 0/4 | 4 | 0 | — |
| [followup-shadow-replica-a.zip](followup-shadow-replica-a.zip) | forward_plus/vulkan | both | cold | 3/4 | 1 | 0 | 22.919 / 22.963 / 33.522 |
| [followup-shadow-replica-b.zip](followup-shadow-replica-b.zip) | forward_plus/vulkan | control | cold | 3/4 | 1 | 0 | 19.081 / 19.414 / 91.870 |
| [followup-shadow-replica-b.zip](followup-shadow-replica-b.zip) | forward_plus/vulkan | directional | cold | 3/4 | 1 | 0 | 18.277 / 19.775 / 23.464 |
| [followup-shadow-replica-b.zip](followup-shadow-replica-b.zip) | forward_plus/vulkan | local | cold | 3/4 | 1 | 0 | 18.370 / 18.572 / 20.920 |
| [followup-shadow-replica-b.zip](followup-shadow-replica-b.zip) | forward_plus/vulkan | both | cold | 3/4 | 1 | 0 | 18.964 / 19.758 / 19.811 |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | forward_plus/vulkan | control | cold | 3/3 | 0 | 0 | 21.674 / 22.279 / 65.448 |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | forward_plus/vulkan | control | warm | 3/3 | 0 | 0 | 19.182 / 20.439 / 21.850 |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | mobile/vulkan | control | cold | 2/3 | 0 | 1 | 15.309 / 16.324 / 17.339 |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | mobile/vulkan | control | warm | 3/3 | 0 | 0 | 12.771 / 13.895 / 20.983 |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | gl_compatibility/opengl3 | control | cold | 0/3 | 0 | 3 | — |
| [original-export-packaged-backends.zip](original-export-packaged-backends.zip) | gl_compatibility/opengl3 | control | warm | 0/3 | 0 | 3 | — |
| [original-export-shadows.zip](original-export-shadows.zip) | forward_plus/vulkan | control | cold | 3/4 | 1 | 0 | 19.004 / 19.539 / 59.332 |
| [original-export-shadows.zip](original-export-shadows.zip) | forward_plus/vulkan | directional | cold | 3/4 | 1 | 0 | 19.051 / 19.205 / 20.533 |
| [original-export-shadows.zip](original-export-shadows.zip) | forward_plus/vulkan | local | cold | 3/4 | 1 | 0 | 18.763 / 19.908 / 30.141 |
| [original-export-shadows.zip](original-export-shadows.zip) | forward_plus/vulkan | both | cold | 4/4 | 0 | 0 | 18.694 / 20.521 / 27.685 |

[All attempted processes, diagnostics, last phase and RSS](attempts.csv)
