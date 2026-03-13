# AAE5303 Assignment 2: ORB-SLAM3 Demo

**Cursor adaptation and practice for the ORB-SLAM3 demo to show the performance (without running a ROS bag from another repository).**

---

## Table of Contents

1. [Executive Summary](#-executive-summary)
2. [Introduction](#-introduction)
3. [Methodology](#-methodology)
4. [Dataset Description](#-dataset-description)
5. [Implementation Details](#-implementation-details)
6. [Results and Analysis](#-results-and-analysis)
7. [Visualizations](#-visualizations)
8. [Discussion](#-discussion)
9. [Conclusions](#-conclusions)
10. [References](#-references)
11. [Appendix](#-appendix)

---

## Executive Summary

This report documents the **ORB-SLAM3 Mono_Compressed** demo run on the **HKisland_GNSS03** UAV aerial imagery dataset inside Docker (`liangyu99/orbslam3_ros1:latest`), with baseline and two YAML parameter experiments.

### Key Results

| Item | Description |
|------|--------------|
| **Environment** | Docker + ROS Noetic; bag from image (`data/HKisland_GNSS03.bag`) |
| **Config** | `config/HKisland_Mono.yaml` (baseline); experiments: nFeatures 2500, nLevels 6 |
| **Tracking** | Baseline and Exp A/B complete; occasional LOST and map resets (see docs/EXPERIMENTS.md) |
| **Evidence** | `figures/` (screenshots), `output/` (KeyFrame trajectories), `docs/EXPERIMENTS.md` |

---

## Introduction

### Background

ORB-SLAM3 supports monocular, stereo, and visual-inertial SLAM. This assignment uses **monocular mode** (Mono_Compressed) with the image’s built-in ROS bag—no external bag repository.

### Objectives

1. Run the ORB-SLAM3 demo in Docker using the provided image and bag.
2. Show performance via baseline run and parameter changes (YAML).
3. Record observations and evidence in the expected repository structure.

### Scope

- **Baseline:** Default `HKisland_Mono.yaml`.
- **Experiment A:** `ORBextractor.nFeatures`: 1500 → 2500.
- **Experiment B:** `ORBextractor.nLevels`: 8 → 6.

---

## Methodology

### ORB-SLAM3 Pipeline

Input images → ORB feature extraction → feature matching → pose estimation / local map optimization → trajectory output. Config (e.g. `nFeatures`, `nLevels`) affects robustness and speed.

### Evaluation (This Assignment)

Qualitative comparison: tracking stability, LOST/reset frequency, FPS, and trajectory appearance (see `docs/EXPERIMENTS.md`). Optional: trajectory accuracy with evo (ATE, RPE, completeness) if ground truth is available.

---

## Dataset Description

### HKisland_GNSS03

| Property | Value |
|----------|--------|
| **Source** | Built-in in Docker image `liangyu99/orbslam3_ros1:latest` |
| **Path in container** | `data/HKisland_GNSS03.bag` |
| **Topic remap** | `/left_camera/image/compressed` → `/camera/image_raw/compressed` |

Official dataset info: MARS-LVIG / UAVScenes (see References).

---

## Implementation Details

### System Configuration

| Component | Specification |
|-----------|----------------|
| **Image** | `liangyu99/orbslam3_ros1:latest` |
| **ROS** | Noetic |
| **Mode** | Mono_Compressed |
| **Config** | `config/HKisland_Mono.yaml` |
| **Host** | Windows + Docker Desktop; display via VcXsrv (X11) |

### Camera and ORB Parameters

See `config/HKisland_Mono.yaml` and `docs/camera_config.yaml`. Key ORB defaults: nFeatures 1500, nLevels 8, scaleFactor 1.2.

### How to Run (Three Terminals)

All from project root in PowerShell:

1. **Terminal 1 — ROS master**
   ```powershell
   docker start orbslam3_a2
   .\scripts\01_roscore.ps1
   ```
2. **Terminal 2 — ORB-SLAM3**
   ```powershell
   .\scripts\02_orbslam3_mono_compressed.ps1
   ```
3. **Terminal 3 — Play bag**
   ```powershell
   .\scripts\03_play_bag.ps1
   ```
   Press **Space** to start/pause playback.

If the container does not exist, create it with `.\scripts\00_recreate_container.ps1` (requires VcXsrv on Display :0, access control disabled).

---

## Results and Analysis

### Baseline

- Tracking completes; occasional “Fail to track local map!” and LOST; automatic reset/new map.
- FPS ~10 (Pangolin), limited by VcXsrv/Docker.
- Evidence: `figures/baseline_map.png`, `figures/baseline_image.png`, `output/baseline_KeyFrameTrajectory.txt`.

### Experiment A (nFeatures 1500 → 2500)

- Denser point cloud and smoother trajectory; fewer LOST/resets; FPS slightly lower.
- Evidence: `figures/expA_*`, `output/expA_KeyFrameTrajectory.txt`.

### Experiment B (nLevels 8 → 6)

- Slightly higher FPS; more LOST/resets on large scale or fast motion; trajectory less stable than A.
- Evidence: `figures/expB_*`, `output/expB_KeyFrameTrajectory.txt`.

Full text: `docs/EXPERIMENTS.md`.

### Performance Analysis (评分)

示例仓库中的**评分**写在本小节：用 evo 得到 ATE / RPE / Completeness 后，在下面表格中填写数值并给出等级（Grade）。若你尚未用 ground truth 跑 evo，可先保留 N/A，或按课程要求填写。

| Metric | Value | Grade | Interpretation |
|--------|-------|-------|-----------------|
| **ATE RMSE** | **2.0069 m** | **B** | Global trajectory error after Sim(3) alignment (KeyFrameTrajectory，误差在 ~2 m 量级) |
| **RPE Trans Drift** | **1.9044 m/m** | **D** | Translation drift per meter (delta=10 m)，局部平移漂移较大 |
| **RPE Rot Drift** | **126.96 deg/100m** | **F** | Rotation drift per 100 m，航向漂移较大 |
| **Completeness** | **27.21% (532 / 1955)** | **F** | Fraction of sequence evaluated；本镜像仅输出 KeyFrameTrajectory，导致完成度显著低于参考 CameraTrajectory (~87%) |

**如何得到上表数据（在哪评）：**

1. **准备 ground truth**：从 bag 或课程提供的 RTK 数据得到 TUM 格式的 `ground_truth.txt`。
2. **准备估计轨迹**：参考案例要求用 **CameraTrajectory.txt**（全帧轨迹，约 2800+ 条 pose）才能得到高完成度（~87%）；用 **KeyFrameTrajectory.txt**（仅关键帧，约 500+ 条）会严重拉低完成度（~27%）。见 `docs/completeness_and_trajectory_file.md`。
3. **在 WSL/Linux 或 Docker 内安装 evo**，然后运行：
   ```bash
   evo_ape tum ground_truth.txt CameraTrajectory.txt --align --correct_scale --t_max_diff 0.1 -va
   evo_rpe tum ground_truth.txt CameraTrajectory.txt --align --correct_scale --t_max_diff 0.1 --delta 10 --delta_unit m --pose_relation trans_part -va
   evo_rpe tum ground_truth.txt CameraTrajectory.txt --align --correct_scale --t_max_diff 0.1 --delta 10 --delta_unit m --pose_relation angle_deg -va
   ```
4. 把 evo 输出的 RMSE、RPE 均值、匹配 pose 数填到上表，并按课程标准或自定档次给出 **Grade**。  
**评分位置**：即本 README 的 **「Results and Analysis」→「Performance Analysis (评分)」** 表格；若课程有 leaderboard，则到 `leaderboard/` 按说明提交。

---

## Visualizations

| Figure | Description |
|--------|-------------|
| `figures/baseline_map.png` | Map Viewer (trajectory) — baseline |
| `figures/baseline_image.png` | Current Frame — baseline |
| `figures/expA_map.png`, `figures/expA_image.png` | Experiment A |
| `figures/expB_map.png`, `figures/expB_image.png` | Experiment B |

---

## Discussion

### Strengths

- Demo runs end-to-end in Docker with built-in bag; no external bag repo.
- Parameter experiments (nFeatures, nLevels) show expected trade-offs (robustness vs speed).

### Limitations

- Tracking instability (LOST, resets) in baseline and Exp B.
- No loop closure; drift over long sequence.
- Display and FPS limited by VcXsrv and Docker.

### Error Sources

- Fast UAV motion, motion blur, large inter-frame displacement.
- Default or reduced ORB levels (Exp B) can reduce robustness on scale changes.

---

## Conclusions

1. ORB-SLAM3 Mono_Compressed runs successfully with `liangyu99/orbslam3_ros1:latest` and HKisland_GNSS03.
2. Increasing nFeatures (Exp A) improves robustness at higher compute cost; reducing nLevels (Exp B) improves speed but can reduce stability.
3. Observations and evidence are recorded in `docs/EXPERIMENTS.md`, `figures/`, and `output/`.

### Assignment Checklist

| Requirement | Status |
|-------------|--------|
| Cursor adaptation and ORB-SLAM3 demo | Done — scripts in `scripts/` |
| Show performance | Done — baseline + Exp A + Exp B in docs/figures/output |
| No ROS bag from another repository | Done — only image-internal bag |
| Learning material (Docker image) | Used |
| Expected outcome (reference repo structure) | Aligned — docs/, figures/, leaderboard/, output/, scripts/ |
| Config Tip (official YAML) | Referenced; experiments use `config/HKisland_Mono.yaml` |

---

## References

1. [Qian9921/AAE5303_assignment2_orbslam3_demo-](https://github.com/Qian9921/AAE5303_assignment2_orbslam3_demo-) — expected outcome structure.
2. [AAE5303 Assignment2 Video](https://www.youtube.com/watch?v=pcLHRnFIK2Q&feature=youtu.be).
3. [Official YAML / calibration (Google Drive)](https://drive.google.com/drive/folders/1x9o3Qh4EiyJrGCGV55WtiD6Sh0M9EJbq).
4. ORB-SLAM3: [UZ-SLAMLab/ORB_SLAM3](https://github.com/UZ-SLAMLab/ORB_SLAM3).
5. MARS-LVIG / UAVScenes — HKisland dataset.

---

## Appendix

### A. Repository Structure (aligned with expected outcome)

```
assignment2/
├── README.md                 # This report
├── requirements.txt
├── config/
│   ├── README.md
│   └── HKisland_Mono.yaml    # YAML for demo and experiments
├── docs/
│   ├── EXPERIMENTS.md        # Baseline + Experiment A + B log
│   └── camera_config.yaml    # Camera calibration reference
├── figures/
│   ├── README.md
│   ├── baseline_map.png, baseline_image.png
│   ├── expA_map.png, expA_image.png
│   └── expB_map.png, expB_image.png
├── leaderboard/
│   ├── README.md
│   ├── LEADERBOARD_SUBMISSION_GUIDE.md
│   └── submission_template.json
├── output/
│   ├── README.md
│   ├── baseline_KeyFrameTrajectory.txt
│   ├── expA_KeyFrameTrajectory.txt
│   ├── expB_KeyFrameTrajectory.txt
│   └── evaluation_report.json
└── scripts/
    ├── README.md
    ├── 00_recreate_container.ps1
    ├── 01_roscore.ps1
    ├── 02_orbslam3_mono_compressed.ps1
    ├── 03_play_bag.ps1
    └── 04_x_test.ps1
```

### B. Copy trajectory from container

```powershell
docker cp orbslam3_a2:/root/ORB_SLAM3/KeyFrameTrajectory.txt .\output\<name>_KeyFrameTrajectory.txt
```

### C. Optional — evo evaluation

If you have ground truth in TUM format:

```bash
evo_ape tum ground_truth.txt CameraTrajectory.txt --align --correct_scale --t_max_diff 0.1 -va
evo_rpe tum ground_truth.txt CameraTrajectory.txt --align --correct_scale --t_max_diff 0.1 --delta 10 --delta_unit m -va
```

---

**AAE5303 - Robust Control Technology in Low-Altitude Aerial Vehicle**
