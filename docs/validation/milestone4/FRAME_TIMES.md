# Matched environment frame times

Times are milliseconds. Each cell shows the PR 6 reference followed by the Milestone 4 candidate. Two runs per revision contribute 360 steady frames and 120 entry frames per view. The comparison uses all observed intervals. Percentiles use nearest rank and medians use the sample median.

[Frame intervals, poses, logs and cache counters](raw-environment.zip) · [Location metrics and FPS distributions](locations.csv) · [Pooled results by preset](presets.csv) · [Player startup](launches.csv) · [Machine and memory](runs.json)

[Every frame above 50 ms with its callback timings](slow-frames.csv)

## Low

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 2.6 / 2.6 | 3.2 / 3.1 | 4.4 / 3.7 | 4.7 / 4.6 | 4.3 / 3.2 | 4.9 / 3.3 |
| Harlow track | 3.3 / 3.2 | 4.3 / 3.8 | 4.8 / 4.1 | 5.3 / 4.2 | 6.7 / 6.9 | 7.1 / 7.5 |
| Bonded Stores exterior | 3.0 / 3.0 | 3.6 / 3.6 | 4.3 / 3.7 | 5.4 / 4.0 | 5.5 / 4.0 | 5.6 / 4.2 |
| Bonded Stores interior | 2.3 / 2.4 | 2.5 / 2.6 | 2.6 / 2.7 | 2.6 / 2.8 | 4.1 / 4.4 | 4.3 / 4.7 |
| Warehouse A | 3.0 / 3.1 | 3.6 / 3.5 | 4.2 / 3.7 | 5.4 / 3.9 | 3.7 / 3.6 | 3.9 / 3.6 |
| Warehouse B | 2.7 / 2.7 | 3.1 / 3.1 | 3.3 / 3.3 | 3.4 / 3.7 | 3.7 / 3.9 | 4.1 / 4.1 |
| Curved embankment | 2.6 / 2.5 | 3.0 / 2.7 | 3.2 / 2.8 | 3.3 / 3.0 | 6.1 / 7.5 | 6.6 / 9.3 |
| Ashford Depot | 2.4 / 2.5 | 2.9 / 2.8 | 3.2 / 3.0 | 4.6 / 3.1 | 3.2 / 3.6 | 3.2 / 3.7 |
| Ashford workshop | 2.3 / 2.5 | 2.5 / 2.8 | 2.6 / 2.9 | 2.8 / 2.9 | 3.8 / 3.2 | 3.8 / 3.4 |
| Blackwater Crossing | 2.4 / 2.6 | 3.2 / 3.1 | 3.5 / 3.3 | 4.0 / 3.4 | 4.8 / 7.3 | 5.2 / 8.6 |
| Crossing Stores | 2.4 / 2.4 | 3.0 / 2.6 | 3.6 / 2.7 | 3.8 / 2.8 | 3.6 / 3.2 | 3.8 / 3.2 |
| Locomotive cab | 3.5 / 3.8 | 4.0 / 4.9 | 4.2 / 5.1 | 4.3 / 5.4 | 20.2 / 19.7 | 44.2 / 25.1 |
| Passenger car | 3.7 / 4.0 | 4.3 / 5.3 | 5.0 / 5.8 | 13.0 / 6.3 | 6.3 / 6.5 | 6.4 / 7.0 |
| Distant fog | 2.5 / 2.6 | 3.0 / 3.9 | 3.4 / 4.2 | 3.5 / 4.4 | 4.3 / 4.7 | 5.3 / 4.8 |
| Near advancing fog | 2.8 / 3.1 | 3.6 / 4.2 | 4.5 / 4.6 | 5.5 / 5.1 | 3.2 / 4.7 | 3.5 / 5.2 |
| Inside dangerous fog | 2.5 / 2.7 | 3.0 / 3.7 | 3.3 / 4.0 | 4.8 / 4.3 | 3.3 / 4.1 | 4.4 / 4.5 |

## Medium

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 3.5 / 3.9 | 4.1 / 5.5 | 4.6 / 6.1 | 5.0 / 7.5 | 5.1 / 8.0 | 10.6 / 9.5 |
| Harlow track | 4.5 / 4.5 | 5.3 / 5.8 | 5.6 / 6.3 | 5.8 / 6.5 | 14.5 / 10.6 | 15.7 / 17.4 |
| Bonded Stores exterior | 3.9 / 4.1 | 4.5 / 5.7 | 4.8 / 6.2 | 4.9 / 7.2 | 4.6 / 5.5 | 5.2 / 5.6 |
| Bonded Stores interior | 3.3 / 3.2 | 3.8 / 4.8 | 3.9 / 5.4 | 4.2 / 6.5 | 7.6 / 7.0 | 8.2 / 8.9 |
| Warehouse A | 4.0 / 3.9 | 4.7 / 5.8 | 4.9 / 6.1 | 5.1 / 6.9 | 5.2 / 6.8 | 6.5 / 7.8 |
| Warehouse B | 3.3 / 3.6 | 3.6 / 5.2 | 3.8 / 5.5 | 4.1 / 6.0 | 4.8 / 5.2 | 4.9 / 5.6 |
| Curved embankment | 3.4 / 3.3 | 4.8 / 5.6 | 5.6 / 6.0 | 6.5 / 6.4 | 5.2 / 6.2 | 7.4 / 16.5 |
| Ashford Depot | 3.0 / 3.3 | 4.4 / 5.4 | 4.8 / 6.1 | 5.2 / 7.0 | 5.8 / 6.0 | 5.9 / 6.2 |
| Ashford workshop | 3.1 / 3.3 | 4.4 / 5.6 | 5.3 / 6.2 | 7.0 / 6.4 | 5.2 / 5.7 | 5.8 / 6.8 |
| Blackwater Crossing | 3.2 / 3.3 | 4.7 / 4.6 | 5.0 / 4.9 | 5.2 / 5.2 | 4.8 / 7.6 | 5.6 / 9.0 |
| Crossing Stores | 3.1 / 2.9 | 4.9 / 4.4 | 5.7 / 5.7 | 7.0 / 6.9 | 5.3 / 4.7 | 5.4 / 5.0 |
| Locomotive cab | 5.3 / 4.7 | 8.0 / 5.7 | 8.5 / 6.1 | 8.7 / 6.5 | 24.8 / 14.7 | 31.7 / 39.2 |
| Passenger car | 5.2 / 5.2 | 6.8 / 6.3 | 8.1 / 6.7 | 8.9 / 7.0 | 8.9 / 7.4 | 9.3 / 7.6 |
| Distant fog | 3.7 / 3.0 | 6.2 / 3.5 | 7.1 / 3.7 | 8.5 / 4.2 | 6.4 / 5.6 | 7.0 / 6.2 |
| Near advancing fog | 4.1 / 3.3 | 5.5 / 3.7 | 6.2 / 4.0 | 7.2 / 4.3 | 8.1 / 4.0 | 8.8 / 4.3 |
| Inside dangerous fog | 3.8 / 3.0 | 4.4 / 3.4 | 4.6 / 3.5 | 5.6 / 3.8 | 4.7 / 3.8 | 4.8 / 3.9 |

## High

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 4.1 / 3.8 | 5.8 / 4.5 | 7.2 / 4.6 | 7.8 / 4.7 | 12.2 / 97.2 | 288.9 / 247.9 |
| Harlow track | 5.1 / 4.7 | 7.0 / 5.5 | 7.9 / 5.8 | 8.1 / 6.1 | 16.9 / 15.3 | 17.5 / 17.5 |
| Bonded Stores exterior | 5.5 / 4.5 | 7.7 / 5.4 | 8.6 / 5.6 | 9.2 / 5.6 | 6.5 / 5.2 | 6.9 / 5.4 |
| Bonded Stores interior | 5.1 / 3.6 | 6.3 / 3.9 | 7.3 / 4.1 | 8.5 / 4.4 | 8.8 / 8.1 | 9.0 / 8.6 |
| Warehouse A | 5.4 / 4.4 | 9.2 / 4.9 | 10.1 / 5.2 | 11.0 / 5.9 | 13.7 / 8.9 | 15.3 / 9.1 |
| Warehouse B | 4.8 / 4.0 | 6.7 / 5.3 | 7.4 / 6.3 | 7.6 / 7.1 | 8.0 / 6.5 | 10.8 / 6.8 |
| Curved embankment | 5.3 / 3.6 | 6.8 / 4.5 | 7.4 / 5.0 | 8.7 / 5.6 | 6.7 / 7.2 | 7.6 / 13.3 |
| Ashford Depot | 4.0 / 3.3 | 5.1 / 3.8 | 5.5 / 4.0 | 5.7 / 4.3 | 6.5 / 5.5 | 6.5 / 6.0 |
| Ashford workshop | 4.6 / 3.4 | 6.1 / 3.8 | 6.7 / 4.0 | 7.2 / 4.1 | 5.4 / 5.2 | 5.9 / 5.3 |
| Blackwater Crossing | 4.0 / 3.5 | 6.7 / 3.8 | 7.3 / 4.0 | 8.2 / 4.2 | 6.7 / 7.3 | 9.6 / 7.6 |
| Crossing Stores | 4.0 / 3.2 | 6.7 / 3.6 | 7.3 / 3.8 | 8.5 / 3.9 | 7.8 / 4.4 | 8.3 / 4.5 |
| Locomotive cab | 5.8 / 5.3 | 9.6 / 6.1 | 10.5 / 6.6 | 12.1 / 7.2 | 36.2 / 28.8 | 111.8 / 35.9 |
| Passenger car | 6.1 / 5.6 | 9.2 / 6.3 | 10.4 / 6.6 | 11.3 / 6.7 | 11.0 / 8.7 | 17.8 / 9.3 |
| Distant fog | 3.5 / 3.6 | 4.7 / 4.3 | 5.6 / 4.7 | 6.4 / 5.0 | 12.0 / 11.0 | 12.8 / 11.1 |
| Near advancing fog | 3.5 / 3.7 | 5.0 / 4.2 | 5.5 / 4.6 | 5.8 / 4.7 | 7.7 / 5.7 | 8.2 / 5.9 |
| Inside dangerous fog | 3.5 / 3.4 | 4.9 / 3.9 | 5.6 / 4.0 | 6.1 / 4.6 | 4.9 / 3.9 | 4.9 / 4.5 |
