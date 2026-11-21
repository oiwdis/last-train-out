# Matched environment frame times

Times are milliseconds. Each cell shows the PR 6 reference followed by the Milestone 4 candidate. Two runs per revision contribute 360 steady frames and 120 entry frames per view. The comparison uses all observed intervals. Percentiles use nearest rank and medians use the sample median.

[Frame intervals, poses, logs and cache counters](raw-environment.zip) · [Location metrics and FPS distributions](locations.csv) · [Pooled results by preset](presets.csv) · [Player startup](launches.csv) · [Machine and memory](runs.json)

[Every frame above 50 ms with its callback timings](slow-frames.csv)

## Low

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 6.8 / 7.8 | 14.2 / 15.1 | 22.4 / 25.3 | 29.9 / 33.7 | 18.7 / 20.6 | 19.4 / 31.6 |
| Harlow track | 7.6 / 8.1 | 12.6 / 12.2 | 19.1 / 17.9 | 51.3 / 34.2 | 44.6 / 63.7 | 75.6 / 66.6 |
| Bonded Stores exterior | 8.2 / 9.0 | 15.0 / 14.8 | 23.7 / 20.7 | 29.8 / 42.4 | 16.4 / 18.9 | 29.1 / 21.7 |
| Bonded Stores interior | 5.8 / 6.0 | 10.3 / 9.6 | 13.3 / 18.8 | 20.5 / 22.8 | 16.1 / 35.4 | 17.0 / 54.9 |
| Warehouse A | 7.0 / 8.1 | 9.9 / 13.6 | 13.2 / 23.7 | 16.0 / 36.4 | 23.9 / 34.6 | 26.3 / 48.5 |
| Warehouse B | 7.3 / 7.3 | 11.9 / 12.7 | 14.6 / 19.8 | 19.4 / 30.3 | 10.1 / 13.4 | 10.3 / 13.9 |
| Curved embankment | 6.0 / 8.6 | 8.7 / 16.1 | 13.7 / 31.5 | 14.7 / 52.2 | 26.5 / 20.4 | 37.1 / 46.9 |
| Ashford Depot | 6.2 / 6.4 | 10.7 / 10.8 | 17.4 / 16.3 | 49.7 / 30.6 | 13.4 / 47.0 | 14.0 / 48.8 |
| Ashford workshop | 5.4 / 5.9 | 9.0 / 11.4 | 13.9 / 17.5 | 19.5 / 61.3 | 11.7 / 19.7 | 19.4 / 21.3 |
| Blackwater Crossing | 5.4 / 6.3 | 9.5 / 10.7 | 17.3 / 12.3 | 26.2 / 13.5 | 13.3 / 16.9 | 29.3 / 20.5 |
| Crossing Stores | 5.8 / 5.6 | 9.5 / 9.3 | 18.2 / 14.4 | 27.5 / 19.7 | 25.2 / 12.6 | 36.1 / 18.1 |
| Locomotive cab | 8.2 / 8.9 | 13.2 / 12.8 | 17.5 / 18.0 | 23.7 / 30.8 | 125.0 / 122.6 | 152.5 / 135.0 |
| Passenger car | 8.4 / 8.8 | 13.3 / 12.9 | 22.3 / 15.6 | 29.0 / 19.9 | 17.6 / 28.0 | 19.9 / 30.8 |
| Distant fog | 6.1 / 6.3 | 11.2 / 9.1 | 18.1 / 13.0 | 21.4 / 16.7 | 19.8 / 14.2 | 37.6 / 17.9 |
| Near advancing fog | 6.5 / 5.9 | 9.9 / 7.7 | 14.7 / 13.4 | 25.7 / 15.5 | 15.5 / 10.6 | 19.5 / 11.6 |
| Inside dangerous fog | 6.6 / 6.4 | 12.4 / 11.1 | 21.2 / 17.7 | 38.5 / 21.4 | 21.9 / 13.3 | 28.0 / 14.6 |

## Medium

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 9.4 / 8.8 | 14.7 / 14.4 | 25.9 / 19.9 | 54.7 / 27.2 | 32.7 / 802.7 | 691.3 / 833.4 |
| Harlow track | 10.0 / 11.7 | 18.0 / 20.7 | 23.3 / 32.5 | 31.4 / 36.3 | 54.5 / 75.6 | 118.5 / 84.4 |
| Bonded Stores exterior | 10.8 / 10.8 | 17.8 / 18.8 | 29.9 / 28.2 | 31.1 / 48.8 | 27.5 / 24.2 | 32.4 / 28.6 |
| Bonded Stores interior | 8.3 / 8.7 | 14.2 / 15.2 | 26.4 / 21.5 | 46.4 / 27.5 | 28.2 / 34.7 | 46.0 / 48.1 |
| Warehouse A | 9.2 / 10.7 | 12.7 / 17.9 | 18.5 / 25.9 | 26.1 / 40.0 | 51.9 / 52.7 | 55.2 / 76.1 |
| Warehouse B | 8.7 / 9.7 | 12.3 / 17.7 | 16.0 / 30.0 | 30.2 / 47.4 | 19.5 / 39.2 | 19.9 / 91.4 |
| Curved embankment | 8.1 / 7.9 | 13.1 / 12.5 | 24.7 / 15.5 | 49.5 / 21.5 | 70.5 / 20.8 | 74.8 / 52.6 |
| Ashford Depot | 7.5 / 7.4 | 12.2 / 13.6 | 17.6 / 25.7 | 45.7 / 28.8 | 17.9 / 19.2 | 26.0 / 24.1 |
| Ashford workshop | 6.8 / 8.0 | 11.2 / 13.3 | 15.2 / 19.8 | 22.2 / 21.2 | 27.2 / 25.7 | 36.1 / 26.1 |
| Blackwater Crossing | 6.6 / 7.6 | 10.5 / 13.7 | 17.6 / 21.8 | 41.2 / 81.5 | 18.9 / 34.6 | 38.3 / 37.8 |
| Crossing Stores | 6.7 / 7.4 | 10.5 / 12.3 | 23.6 / 19.1 | 42.2 / 23.6 | 14.4 / 22.7 | 33.2 / 40.4 |
| Locomotive cab | 10.9 / 11.8 | 15.8 / 17.9 | 18.4 / 30.4 | 22.2 / 43.0 | 175.5 / 173.7 | 198.9 / 255.3 |
| Passenger car | 11.0 / 13.7 | 17.1 / 24.7 | 21.0 / 56.8 | 26.5 / 59.4 | 44.8 / 43.6 | 44.9 / 66.6 |
| Distant fog | 7.5 / 8.0 | 10.6 / 12.7 | 18.5 / 24.2 | 23.5 / 41.7 | 15.9 / 20.7 | 16.0 / 35.4 |
| Near advancing fog | 7.5 / 8.5 | 12.1 / 13.2 | 18.7 / 18.5 | 23.2 / 21.6 | 27.4 / 13.9 | 31.9 / 16.0 |
| Inside dangerous fog | 8.6 / 8.3 | 15.3 / 13.3 | 21.8 / 30.7 | 82.9 / 41.6 | 13.9 / 15.9 | 17.7 / 15.9 |

## High

| Location | Steady median | Steady p95 | Steady p99 | Steady worst | Entry p99 | Entry worst |
|---|---:|---:|---:|---:|---:|---:|
| Harlow platform | 10.3 / 9.8 | 16.4 / 12.5 | 22.6 / 16.4 | 24.7 / 18.3 | 819.0 / 49.7 | 1183.5 / 278.6 |
| Harlow track | 14.2 / 12.6 | 23.5 / 19.5 | 32.9 / 29.2 | 88.8 / 58.5 | 95.4 / 71.0 | 99.0 / 92.0 |
| Bonded Stores exterior | 11.3 / 11.3 | 17.4 / 18.9 | 20.3 / 28.4 | 30.8 / 39.1 | 50.2 / 30.6 | 66.7 / 40.0 |
| Bonded Stores interior | 9.4 / 9.3 | 13.9 / 13.2 | 19.6 / 20.7 | 28.5 / 28.4 | 34.8 / 34.3 | 39.8 / 46.7 |
| Warehouse A | 10.7 / 11.7 | 15.0 / 18.5 | 28.2 / 25.5 | 33.4 / 47.9 | 59.6 / 40.9 | 82.9 / 42.4 |
| Warehouse B | 11.3 / 10.2 | 15.5 / 17.0 | 18.8 / 24.9 | 28.2 / 36.9 | 39.4 / 19.1 | 124.0 / 27.2 |
| Curved embankment | 9.0 / 9.3 | 14.2 / 16.6 | 26.5 / 23.3 | 31.5 / 37.3 | 52.4 / 47.3 | 54.7 / 51.5 |
| Ashford Depot | 7.8 / 8.2 | 12.9 / 13.6 | 19.8 / 16.5 | 21.8 / 22.2 | 30.7 / 53.2 | 45.9 / 57.3 |
| Ashford workshop | 8.7 / 8.6 | 12.1 / 12.6 | 23.7 / 15.5 | 30.3 / 16.6 | 15.0 / 26.5 | 19.5 / 27.9 |
| Blackwater Crossing | 7.8 / 9.3 | 14.1 / 13.8 | 22.6 / 26.3 | 91.4 / 36.7 | 45.9 / 30.6 | 53.2 / 39.0 |
| Crossing Stores | 7.8 / 7.7 | 14.3 / 10.9 | 20.8 / 14.2 | 47.4 / 24.6 | 17.0 / 30.8 | 17.3 / 31.5 |
| Locomotive cab | 13.5 / 13.8 | 20.3 / 22.1 | 25.9 / 31.4 | 26.8 / 59.4 | 219.4 / 191.1 | 238.5 / 208.8 |
| Passenger car | 13.7 / 14.0 | 21.6 / 22.6 | 34.6 / 27.1 | 48.3 / 36.1 | 36.4 / 37.6 | 43.5 / 43.1 |
| Distant fog | 8.9 / 9.5 | 17.1 / 14.1 | 32.0 / 25.9 | 54.5 / 38.2 | 21.2 / 29.1 | 35.0 / 37.3 |
| Near advancing fog | 9.2 / 9.9 | 15.5 / 14.7 | 28.1 / 23.5 | 29.2 / 31.4 | 19.5 / 18.3 | 21.0 / 18.4 |
| Inside dangerous fog | 9.7 / 9.5 | 17.9 / 15.7 | 35.0 / 24.1 | 59.0 / 31.2 | 13.2 / 29.3 | 18.7 / 31.4 |
