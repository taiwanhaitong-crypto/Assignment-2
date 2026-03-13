# ORB-SLAM3 Parameter Experiments

Baseline and YAML parameter changes for the HKisland Mono_Compressed demo.

---

## Baseline (Default Config)

| Item | Description |
|------|--------------|
| **Config** | `config/HKisland_Mono.yaml` (original from container, unmodified) |
| **Bag** | `data/HKisland_GNSS03.bag` |
| **Run** | `scripts/01_roscore.ps1` → `02_orbslam3_mono_compressed.ps1` → `03_play_bag.ps1` |

**Observations**

- **Tracking:** Run completes with tracking; occasional “Fail to track local map!” with automatic reset and recovery.
- **LOST / relocalization:** Occasional LOST; system creates new maps (“New Map created with XXX points” in log).
- **FPS:** ~10 FPS (Pangolin); limited by VcXsrv and Docker.

**Evidence**

- Screenshots: `results/baseline_map.png`, `results/baseline_image.png`
- Trajectory: `results/baseline_KeyFrameTrajectory.txt` (~53.2 kB)

---

## Experiment A — More ORB Features

| Item | Description |
|------|--------------|
| **Change** | `ORBextractor.nFeatures`: **1500 → 2500** |
| **Hypothesis** | More features per frame may improve tracking robustness at higher compute cost. |

**Observations**

- Compared with the baseline, the **map point cloud is visibly denser and the trajectory appears smoother**; LOST / reset events are slightly fewer and short occlusions are handled more robustly.
- The Pangolin viewer shows more feature points and the terminal reports more frequent local-map optimisations; **FPS decreases slightly** due to the increased feature-processing cost.

**Evidence**

- Screenshots: `results/expA_map.png`, `results/expA_image.png`
- Trajectory: `results/expA_KeyFrameTrajectory.txt` (~53.2 kB)

---

## Experiment B — Fewer Pyramid Levels

| Item | Description |
|------|--------------|
| **Change** | `ORBextractor.nLevels`: **8 → 6** |
| **Hypothesis** | Fewer scale levels reduce computation and may improve FPS, at the cost of scale invariance (tracking may be less robust at large scale changes). |

**Observations**

- Compared with the baseline, the **frame rate is slightly higher** (fewer pyramid levels per frame, so less computation) and the logs show more frames processed per second.
- However, when there are large scale changes or fast forward motion, the system **is more prone to LOST events and occasional resets / new maps**; in those segments the trajectory is more jittery and overall slightly less stable than in Experiment A.

**Evidence**

- Screenshots: `results/expB_map.png`, `results/expB_image.png`
- Trajectory: `results/expB_KeyFrameTrajectory.txt` (optional, copy with `docker cp orbslam3_a2:/root/ORB_SLAM3/KeyFrameTrajectory.txt .\results\expB_KeyFrameTrajectory.txt`)
