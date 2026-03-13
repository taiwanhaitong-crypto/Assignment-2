# Why is the completeness low? — Explanation vs. reference repo

The reference repository [Qian9921/AAE5303_assignment2_orbslam3_demo-](https://github.com/Qian9921/AAE5303_assignment2_orbslam3_demo-) states in its README:

---

## Trajectory files used in the reference vs. in this repo

| Item | Reference repo | This repo (current environment) |
|------|----------------|----------------------------------|
| **Estimated trajectory file** | **CameraTrajectory.txt** (all tracked frames) | `KeyFrameTrajectory.txt` (keyframes only) |
| **Number of estimated poses** | **2,826** | ~546 |
| **Matched poses** | 1,701 | 532 |
| **Ground-truth poses** | 1,955 | 1,955 |
| **Completeness** | **87.01%** (1701 / 1955) | ~27% (532 / 1955) |

Relevant lines in the reference README:

- **“Estimated poses: 2,826 — Trajectory poses in `CameraTrajectory.txt`”**  
- **“Use the correct trajectory file: `CameraTrajectory.txt` contains *all tracked frames* and typically yields higher completeness. `KeyFrameTrajectory.txt` contains only keyframes and can severely reduce completeness and distort drift estimates.”**

Therefore: **our completeness is low because we are evaluating `KeyFrameTrajectory.txt`, whereas the reference evaluates `CameraTrajectory.txt`.**

---

## How to increase completeness

1. **Evaluate using `CameraTrajectory.txt`**  
   ORB-SLAM3 needs to **save a full-frame trajectory** (every tracked frame written to `CameraTrajectory.txt`), not just keyframes to `KeyFrameTrajectory.txt`.

2. **Does the current Docker image support this?**  
   In `liangyu99/orbslam3_ros1:latest`, the `Mono_Compressed` node **by default only writes `KeyFrameTrajectory.txt`**.  
   - After a demo run, you can check for a full-frame trajectory inside the container:
     ```bash
     docker exec orbslam3_a2 ls -la /root/ORB_SLAM3/CameraTrajectory.txt
     ```
   - If this file does **not** exist, the image is not configured to save the full-frame trajectory.

3. **If the image does not produce `CameraTrajectory.txt`**  
   - You need a **patched ORB-SLAM3 ROS node** that calls `SaveTrajectoryEuRoC("CameraTrajectory.txt")` (or an equivalent function) on shutdown, then recompile and re-run the demo. With a valid `CameraTrajectory.txt`, evo can achieve completeness close to the reference (~87%).  
   - Alternatively, ask the course staff whether they provide a Docker image / code that already outputs `CameraTrajectory.txt`, or whether they accept a KeyFrame-only evaluation (with lower completeness) as long as it is properly documented.

---

## Summary

- **Low completeness**: caused by using **`KeyFrameTrajectory.txt`** (keyframes only).  
- **Reference completeness**: uses **`CameraTrajectory.txt`** (all tracked frames), which yields 87.01% completeness.  
- **Improving completeness**: requires a version of ORB-SLAM3 that can generate **`CameraTrajectory.txt`**, followed by evo evaluation on that file.  
→ For concrete patching steps (modify ROS node, add `SaveTrajectoryEuRoC`, rebuild), see **`docs/how_to_generate_CameraTrajectory.md`**.
