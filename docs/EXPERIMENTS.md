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

- **Tracking:** Run completes with tracking; occasional "Fail to track local map!" with automatic reset and recovery.
- **LOST / relocalization:** Occasional LOST; system creates new maps ("New Map created with XXX points" in log).
- **FPS:** ~10 FPS (Pangolin); limited by VcXsrv and Docker.

**Evidence**

- Screenshots: `figures/baseline_map.png`, `figures/baseline_image.png`
- Trajectory: `output/baseline_KeyFrameTrajectory.txt`

---

## Experiment A — More ORB Features

| Item | Description |
|------|--------------|
| **Change** | `ORBextractor.nFeatures`: **1500 → 2500** |
| **Hypothesis** | More features per frame may improve tracking robustness at higher compute cost. |

**Observations**

- Compared with the baseline, the **map point cloud is noticeably denser and the trajectory is smoother**; LOST / reset events are slightly fewer and the system tends to recover more easily after short occlusions.
- The Pangolin window shows many more feature points and local-map optimisations occur more frequently in the console output; **FPS drops slightly** because of the increased computation.

**Evidence**

- Screenshots: `figures/expA_map.png`, `figures/expA_image.png`
- Trajectory: `output/expA_KeyFrameTrajectory.txt`

---

## Experiment B — Fewer Pyramid Levels

| Item | Description |
|------|--------------|
| **Change** | `ORBextractor.nLevels`: **8 → 6** |
| **Hypothesis** | Fewer scale levels reduce computation and may improve FPS, at the cost of scale invariance (tracking may be less robust at large scale changes). |

**Observations**

- Compared with the baseline, the **frame rate is slightly higher** (fewer pyramid levels per frame, so less computation), and the console shows more frames processed per second.
- However, when the viewing distance changes significantly or the camera moves forward quickly, the system **is more likely to go LOST and occasionally needs a reset / new map**; the trajectory is a bit more jittery in these segments and overall slightly less stable than Experiment A.

**Evidence**

- Screenshots: `figures/expB_map.png`, `figures/expB_image.png`
- Trajectory: `output/expB_KeyFrameTrajectory.txt`
