# 为什么完成度 (Completeness) 低？—— 参考案例说明

参考仓库 [Qian9921/AAE5303_assignment2_orbslam3_demo-](https://github.com/Qian9921/AAE5303_assignment2_orbslam3_demo-) 的 README 明确写了：

---

## 参考案例用的轨迹文件

| 项目 | 参考案例 | 你当前 |
|------|----------|--------|
| **估计轨迹文件** | **CameraTrajectory.txt**（全帧轨迹） | KeyFrameTrajectory.txt（仅关键帧） |
| **估计 pose 数量** | **2,826** | ~546 |
| **匹配上的 pose** | 1,701 | 532 |
| **Ground truth pose** | 1,955 | 1,955 |
| **Completeness** | **87.01%** (1701/1955) | ~27% (532/1955) |

README 原文：

- **"Estimated poses: 2,826 — Trajectory poses in `CameraTrajectory.txt`"**
- **"Use the correct trajectory file: `CameraTrajectory.txt` contains *all tracked frames* and typically yields higher completeness. `KeyFrameTrajectory.txt` contains only keyframes and can severely reduce completeness and distort drift estimates."**

所以：**完成度低是因为用了 KeyFrameTrajectory.txt，参考案例用的是 CameraTrajectory.txt。**

---

## 要怎么做才能提高完成度？

1. **用 CameraTrajectory.txt 做评估**  
   需要 ORB-SLAM3 在跑的时候**保存全帧轨迹**（每一帧的位姿都写入 `CameraTrajectory.txt`），而不是只保存关键帧到 `KeyFrameTrajectory.txt`。

2. **当前镜像是否支持**  
   镜像 `liangyu99/orbslam3_ros1:latest` 里的 Mono_Compressed 节点**默认可能只写 KeyFrameTrajectory.txt**。  
   - 跑完一次 demo 后，在容器里检查是否有全帧轨迹：
     ```bash
     docker exec orbslam3_a2 ls -la /root/ORB_SLAM3/CameraTrajectory.txt
     ```
   - 若**没有**这个文件，说明当前镜像没有打开“保存全帧轨迹”的逻辑。

3. **若镜像里没有 CameraTrajectory.txt**  
   - 需要用到**已修改过的 ORB-SLAM3/ROS 节点**（在退出或运行时写入 `CameraTrajectory.txt`），再重新编译、跑一遍，得到 `CameraTrajectory.txt` 后用同一套 evo 命令评估，完成度才会接近参考案例的 ~87%。  
   - 或向老师/课程确认：是否提供会输出 `CameraTrajectory.txt` 的镜像或代码；或是否接受用 KeyFrame 轨迹提交（完成度会偏低）。

---

## 小结

- **完成度低**：是因为用了 **KeyFrameTrajectory.txt**（只有关键帧）。  
- **参考案例**：用的是 **CameraTrajectory.txt**（全帧），所以有 87.01% 完成度。  
- **要提高完成度**：必须用能生成 **CameraTrajectory.txt** 的版本跑一遍，再用该文件做 evo 评估。  
→ 具体做法（改 ROS 节点、加 `SaveTrajectoryEuRoC`、重新编译）：见 **`docs/how_to_generate_CameraTrajectory.md`**。
