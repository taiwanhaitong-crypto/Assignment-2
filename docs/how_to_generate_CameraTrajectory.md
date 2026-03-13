# 如何生成 CameraTrajectory.txt（全帧轨迹）

当前镜像只保存 **KeyFrameTrajectory.txt**（关键帧），所以完成度约 27%。要得到 **CameraTrajectory.txt**（每一帧都保存），需要改 ORB-SLAM3 的 ROS 节点源码并重新编译。

---

## 原理

- **SaveKeyFrameTrajectoryTUM()**：只写关键帧 → 当前节点在退出时调用的就是这个，得到 KeyFrameTrajectory.txt。
- **SaveTrajectoryEuRoC()**：按帧写所有跟踪到的相机位姿（用相对关键帧的变换算出来）→ 得到的就是“全帧”轨迹，行数远多于 KeyFrame，对应参考案例里的 CameraTrajectory。

官方 System.h 里 **SaveTrajectoryTUM** 注明仅用于 stereo/RGB-D，**单目用 SaveTrajectoryEuRoC** 即可；输出格式与 TUM 兼容，evo 可评估。

---

## 操作步骤（在容器内完成）

### 1. 进入容器并找到 Mono_Compressed 的源码

```powershell
docker exec -it orbslam3_a2 bash
```

在容器内：

```bash
cd /root/ORB_SLAM3
find . -name "*.cc" | xargs grep -l "SaveKeyFrameTrajectory\|Mono_Compressed\|Shutdown"
```

通常会是 **Examples_old/ROS/ORB_SLAM3/src/ros_mono_compressed.cc** 或类似路径下的 `.cc` 文件。用 `cat` 或 `vi` 打开该文件。

### 2. 在“退出 / 保存轨迹”处加一行

在源码里找到 **Shutdown()** 以及 **SaveKeyFrameTrajectoryTUM**（或 SaveKeyFrameTrajectoryEuRoC）的调用位置，在 **Shutdown() 之后**、程序退出前增加保存全帧轨迹，例如：

```cpp
// 在 Shutdown() 之后添加（路径可写成当前工作目录下的文件名）
pSLAM->Shutdown();
pSLAM->SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");   // 原有
pSLAM->SaveTrajectoryEuRoC("CameraTrajectory.txt");           // 新增：全帧轨迹
```

若节点里用的是 `SLAM.` 而不是 `pSLAM->`，则写成：

```cpp
SLAM.Shutdown();
SLAM.SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");
SLAM.SaveTrajectoryEuRoC("CameraTrajectory.txt");
```

保存后退出编辑器。

### 3. 重新编译

在容器内、ORB_SLAM3 根目录下：

```bash
cd /root/ORB_SLAM3
./build.sh
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:/root/ORB_SLAM3/Examples_old/ROS
./build_ros.sh
```

若镜像里没有 `build_ros.sh`，可用：

```bash
cd Examples_old/ROS
mkdir -p build && cd build
cmake .. -DROS_BUILD_TYPE=Release
make -j4
```

具体以镜像内实际目录和 CMake 列表为准。

### 4. 再跑一遍 demo 并正常退出

按你原来的三终端流程跑（roscore → Mono_Compressed → rosbag play）。**播完 bag 后，在运行 Mono_Compressed 的终端里用 Ctrl+C 退出**。  
轨迹会写在 **运行 Mono_Compressed 时的当前工作目录**（一般是 `/root/ORB_SLAM3/`），应同时出现：

- `KeyFrameTrajectory.txt`
- **`CameraTrajectory.txt`**

### 5. 拷出并评估

在本机 PowerShell（项目根目录）执行：

```powershell
.\scripts\06_copy_camera_trajectory.ps1
.\scripts\05_run_evaluation_in_docker.ps1
```

若 06 成功，05 会用到 `output/CameraTrajectory.txt`，完成度会明显提高（可接近参考案例的 ~87%）。

---

## 若找不到源码或编译失败

- 镜像可能把 ROS 节点预编译好了、未带源码，或路径不在 `Examples_old`。可在容器内用：
  ```bash
  find /root -name "*.cc" 2>/dev/null | head -20
  ```
  再根据文件名用 `grep -l SaveKeyFrameTrajectory` 定位到具体 `.cc`。
- 若无法改镜像内的代码，只能继续用 **KeyFrameTrajectory.txt** 做评估（完成度约 27%），在报告里说明：本环境仅提供 KeyFrame 轨迹，参考案例使用全帧 CameraTrajectory，故完成度差异见 `docs/completeness_and_trajectory_file.md`。

---

## 参考

- ORB-SLAM3 官方：[UZ-SLAMLab/ORB_SLAM3](https://github.com/UZ-SLAMLab/ORB_SLAM3)
- Issue #273：[Difference between SaveTrajectory and SaveKeyFrameTrajectory?](https://github.com/UZ-SLAMLab/ORB_SLAM3/issues/273)
