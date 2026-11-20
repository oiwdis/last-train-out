# Extending Metal library coverage through the route

The Low-first trace of build 99 found 46 more source stages than an ordinary High start. Apple’s offline Metal compiler built those exact input hashes and preserved all 319 existing library payloads byte for byte. The release-format archive now contains 365 distinct libraries in 83 read-only groups. It adds 2,435,952 bytes of compiled library data. All 94 signed source groups remain available for fallback. [Compiler coverage and archive SHA-256](coverage.json) · [All 46 Apple compiler logs](compiler-logs.zip) · [Original compile and two-host comparison](https://github.com/oiwdis/last-train-out/actions/runs/44816904771)

Two freshly provisioned Macs received the same frozen build 99. One copy on each host received the extended inventory and was re-signed. The native player, launcher and PCK were identical. Each host reversed which copy ran first. For each inventory the first complete 36-view matrix used a private empty application cache and native signposts. The second matrix reused that cache without an observer. The two variants shared the host driver cache. Each had a separate screenshot pass. All 12 processes completed, selected the actual native Metal player and recorded zero engine diagnostics. [Shipped-first raw archive](../raw/entry-shipped-first.zip) · [Extended-first raw archive](../raw/entry-extended-first.zip)

| First matrix on each host | Shipped first, original / extended | Extended first, original / extended |
|---|---:|---:|
| Native source compilations | 46 / 0 | 46 / 0 |
| Compute and render pipelines | 184 and 538 with either inventory | 184 and 538 with either inventory |
| Low Harlow worst entry | 60.655 / 8.744 ms | 1,221.532 / 18.199 ms |
| Low Warehouse A worst entry | 107.706 / 50.562 ms | 1,517.104 / 72.622 ms |
| All views, worst entry | 205.535 / 175.939 ms | 1,517.104 / 280.862 ms |
| All views, steady p99 | 55.126 / 36.577 ms | 31.702 / 48.881 ms |
| All views, worst steady | 248.980 / 106.184 ms | 87.858 / 216.011 ms |
| Entry frames above 100 ms | 5 / 3 | 12 / 6 |

Every native begin/end interval paired on both hosts. Extending the archive removed the same 46 source compilations on each, and both first-use target locations improved even when the extended copy ran first. That host’s remaining 280.862 ms entry and 216.011 ms steady frames both occurred in the passenger car, on High and Medium respectively. The extended first-pass steady p99 regressed there. On the shipped-first host the extended warm matrix was slightly worse at the maximum entry and steady intervals. RSS in the extended first passes rose by about 9 and 27 MiB. The measurements support delivering the extra libraries for first-use responsiveness. They do not establish the under-100 ms target throughout the game. [All 16 distributions, outlier locations, thresholds and memory](frames.csv)

Among 72 pairs, three were identical. The maximum frame-wide mean absolute channel difference was 4.44/255 on the High curve and 2.27/255 on the other host’s High approaching-fog view. The largest curve difference includes the appearance of the timed boarding banner between captures. The inspected pairs retained the same rails, train surfaces, brickwork, shadows and fog boundary. The original full-resolution pairs remain in both raw archives. [Selected pairs](comparison.jpg) · [Every pixel comparison](pixels.csv)

The additional libraries are selected by the existing compatible-device, OS and source-hash checks. No render scale, model, material, preset or gameplay setting changes with this inventory. The development ZIP of build 99 remains the 319-stage control for this comparison.
