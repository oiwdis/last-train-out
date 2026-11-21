# Matched environment frame times

Times are milliseconds. Each cell shows the PR 6 reference followed by the Milestone 4 candidate. Two runs per revision contribute 360 steady frames and 120 entry frames per view. The comparison uses all observed intervals. Percentiles use nearest rank and medians use the sample median.

[Frame intervals, poses, logs and cache counters](raw-environment.zip) · [Location metrics and FPS distributions](locations.csv) · [Pooled results by preset](presets.csv) · [Player startup](launches.csv) · [Machine and memory](runs.json)

## Low

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 6.9 / 6.3 | 11.4 / 9.2 | 15.7 / 11.7 | 23.6 / 16.4 | 12.5 / 16.3 | 15.0 / 19.0 |
| Harlow track | 7.0 / 6.7 | 11.1 / 10.3 | 14.1 / 15.7 | 19.1 / 32.2 | 33.9 / 27.1 | 51.0 / 37.4 |
| Bonded Stores exterior | 6.3 / 5.7 | 9.4 / 7.5 | 12.2 / 8.8 | 17.3 / 9.4 | 11.1 / 9.5 | 11.2 / 10.6 |
| Bonded Stores interior | 6.0 / 4.2 | 9.8 / 6.2 | 14.2 / 7.4 | 19.4 / 9.9 | 13.5 / 19.1 | 17.2 / 19.9 |
| Warehouse A | 6.8 / 5.9 | 10.0 / 8.2 | 14.8 / 11.2 | 15.7 / 15.2 | 30.2 / 15.5 | 51.6 / 20.9 |
| Warehouse B | 6.1 / 5.5 | 9.2 / 7.8 | 16.2 / 9.6 | 38.1 / 14.4 | 15.3 / 8.8 | 18.7 / 8.8 |
| Curved embankment | 5.9 / 4.6 | 9.0 / 6.1 | 19.4 / 7.5 | 31.0 / 8.8 | 36.0 / 13.0 | 53.4 / 38.1 |
| Ashford Depot | 5.1 / 5.1 | 7.7 / 8.9 | 9.8 / 11.8 | 14.9 / 23.6 | 9.9 / 14.2 | 12.3 / 24.8 |
| Ashford workshop | 4.8 / 4.6 | 7.0 / 6.3 | 13.4 / 7.6 | 14.8 / 9.4 | 12.6 / 10.5 | 18.5 / 16.0 |
| Blackwater Crossing | 4.4 / 4.5 | 6.4 / 6.2 | 9.2 / 8.9 | 12.1 / 12.8 | 14.0 / 14.7 | 15.8 / 17.3 |
| Crossing Stores | 4.6 / 4.1 | 6.6 / 5.5 | 8.5 / 6.3 | 12.5 / 7.5 | 9.2 / 13.3 | 14.7 / 17.2 |
| Locomotive cab | 7.6 / 6.8 | 11.4 / 10.4 | 19.4 / 13.5 | 24.5 / 14.6 | 124.4 / 78.3 | 342.9 / 82.6 |
| Passenger car | 8.5 / 6.4 | 13.5 / 10.7 | 22.9 / 14.9 | 25.8 / 16.6 | 15.0 / 20.2 | 16.5 / 22.1 |
| Distant fog | 5.3 / 5.2 | 7.2 / 8.2 | 8.6 / 11.8 | 11.3 / 16.1 | 9.5 / 9.1 | 12.7 / 11.4 |
| Near advancing fog | 5.6 / 4.3 | 7.9 / 6.1 | 12.7 / 7.8 | 19.6 / 15.3 | 10.7 / 11.1 | 10.8 / 11.3 |
| Inside dangerous fog | 5.6 / 4.1 | 8.5 / 6.4 | 11.0 / 8.7 | 15.7 / 10.9 | 10.7 / 10.3 | 10.8 / 11.2 |

## Medium

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 7.3 / 6.5 | 11.9 / 9.1 | 17.3 / 11.5 | 31.0 / 13.2 | 50.9 / 17.0 | 768.9 / 21.4 |
| Harlow track | 8.4 / 7.8 | 12.8 / 10.0 | 17.7 / 11.4 | 21.6 / 14.0 | 78.7 / 30.1 | 82.7 / 34.4 |
| Bonded Stores exterior | 8.9 / 6.6 | 17.1 / 9.6 | 27.1 / 13.8 | 39.4 / 21.5 | 20.4 / 14.5 | 22.5 / 14.5 |
| Bonded Stores interior | 6.0 / 5.1 | 9.0 / 7.6 | 14.8 / 8.3 | 17.9 / 9.8 | 26.8 / 14.9 | 31.1 / 30.3 |
| Warehouse A | 8.2 / 6.4 | 17.4 / 11.3 | 22.6 / 12.8 | 45.6 / 14.5 | 18.0 / 14.3 | 64.3 / 17.9 |
| Warehouse B | 7.3 / 5.7 | 12.2 / 8.1 | 14.8 / 9.5 | 20.6 / 10.5 | 20.3 / 8.7 | 35.8 / 9.4 |
| Curved embankment | 7.1 / 5.3 | 12.1 / 7.6 | 20.5 / 9.7 | 34.6 / 11.0 | 35.6 / 11.5 | 51.1 / 12.6 |
| Ashford Depot | 5.9 / 6.1 | 8.2 / 8.5 | 10.1 / 10.9 | 13.3 / 15.6 | 17.4 / 12.5 | 29.4 / 17.3 |
| Ashford workshop | 5.4 / 5.2 | 7.3 / 8.3 | 9.4 / 12.1 | 15.2 / 15.2 | 19.0 / 13.6 | 28.5 / 20.5 |
| Blackwater Crossing | 6.0 / 4.9 | 8.0 / 7.9 | 10.4 / 9.1 | 13.4 / 12.1 | 19.5 / 18.0 | 24.3 / 18.3 |
| Crossing Stores | 6.2 / 5.2 | 10.1 / 7.2 | 13.2 / 8.9 | 15.4 / 10.1 | 18.4 / 14.5 | 19.1 / 21.1 |
| Locomotive cab | 9.8 / 8.5 | 14.4 / 11.2 | 17.8 / 13.2 | 25.3 / 17.7 | 96.2 / 79.6 | 155.7 / 165.7 |
| Passenger car | 8.9 / 9.6 | 12.5 / 14.3 | 15.6 / 18.6 | 17.4 / 42.0 | 25.6 / 20.1 | 32.0 / 24.0 |
| Distant fog | 6.5 / 6.6 | 8.6 / 10.2 | 12.1 / 13.6 | 18.8 / 33.6 | 10.8 / 12.9 | 11.1 / 15.4 |
| Near advancing fog | 6.4 / 6.2 | 9.1 / 8.7 | 12.6 / 11.5 | 15.3 / 17.9 | 12.9 / 9.7 | 25.0 / 12.7 |
| Inside dangerous fog | 6.0 / 6.7 | 8.5 / 11.3 | 11.0 / 31.2 | 11.5 / 58.8 | 9.3 / 18.4 | 17.0 / 22.2 |

## High

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 9.7 / 8.5 | 16.3 / 13.9 | 28.3 / 20.3 | 45.1 / 42.2 | 249.4 / 229.0 | 599.5 / 758.3 |
| Harlow track | 10.5 / 8.7 | 14.5 / 11.1 | 17.6 / 12.9 | 22.0 / 13.6 | 110.8 / 57.9 | 127.8 / 112.1 |
| Bonded Stores exterior | 10.0 / 8.6 | 13.4 / 11.6 | 19.5 / 14.6 | 21.2 / 34.8 | 16.4 / 15.8 | 18.4 / 19.2 |
| Bonded Stores interior | 7.8 / 7.3 | 10.9 / 10.5 | 14.6 / 12.9 | 19.7 / 14.8 | 29.2 / 14.3 | 32.7 / 31.4 |
| Warehouse A | 9.8 / 9.2 | 16.4 / 11.6 | 23.8 / 14.0 | 32.8 / 14.5 | 42.4 / 40.9 | 45.0 / 41.1 |
| Warehouse B | 9.6 / 8.2 | 15.0 / 11.7 | 19.2 / 14.2 | 25.9 / 17.7 | 26.1 / 17.7 | 82.3 / 27.2 |
| Curved embankment | 7.9 / 8.3 | 12.9 / 11.9 | 19.3 / 16.2 | 21.6 / 16.6 | 9.8 / 11.8 | 12.7 / 22.8 |
| Ashford Depot | 6.2 / 7.3 | 8.4 / 9.7 | 9.8 / 12.7 | 11.8 / 16.2 | 21.5 / 21.8 | 26.0 / 21.9 |
| Ashford workshop | 7.5 / 7.3 | 11.4 / 10.4 | 18.5 / 12.7 | 32.9 / 21.4 | 13.1 / 10.8 | 21.5 / 14.5 |
| Blackwater Crossing | 6.7 / 8.1 | 10.0 / 15.3 | 14.4 / 26.9 | 15.2 / 36.6 | 21.5 / 21.2 | 24.9 / 24.5 |
| Crossing Stores | 6.7 / 6.8 | 9.4 / 9.8 | 12.4 / 12.9 | 20.6 / 14.3 | 10.3 / 12.9 | 14.0 / 19.0 |
| Locomotive cab | 10.9 / 11.4 | 16.9 / 17.5 | 22.0 / 22.7 | 25.2 / 25.9 | 196.3 / 156.3 | 197.4 / 208.1 |
| Passenger car | 11.7 / 11.6 | 18.6 / 19.9 | 30.4 / 28.1 | 53.9 / 66.0 | 35.2 / 19.5 | 39.5 / 36.6 |
| Distant fog | 8.3 / 8.1 | 12.5 / 12.7 | 16.7 / 19.1 | 20.5 / 22.3 | 21.4 / 40.7 | 28.4 / 43.4 |
| Near advancing fog | 7.5 / 8.4 | 10.0 / 14.1 | 12.0 / 19.9 | 13.4 / 37.2 | 15.9 / 21.5 | 17.5 / 25.1 |
| Inside dangerous fog | 7.6 / 8.1 | 10.3 / 12.1 | 15.6 / 17.7 | 17.3 / 22.0 | 15.7 / 12.5 | 17.4 / 13.6 |

