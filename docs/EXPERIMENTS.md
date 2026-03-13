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

- 相比 baseline，**地图点云明显更密、轨迹更平滑**，LOST / reset 次数略有减少，短时间遮挡后也更容易恢复。
- Pangolin 窗口中特征点数目增多，终端输出中局部地图优化更频繁，**FPS 略有下降**（计算量增加）。

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

- 相比 baseline，**帧率略有提升**（每帧金字塔层数减少，计算量下降），终端日志中每秒处理帧数更高。
- 但在视距变化较大或摄像机快速前进的路段，**更容易出现 LOST，偶尔需要 reset / 新地图**，轨迹在这些位置略有抖动，稳定性略差于 Experiment A。

**Evidence**

- Screenshots: `figures/expB_map.png`, `figures/expB_image.png`
- Trajectory: `output/expB_KeyFrameTrajectory.txt`
