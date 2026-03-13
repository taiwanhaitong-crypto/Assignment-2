# How to generate `CameraTrajectory.txt` (full-frame trajectory)

In the unmodified Docker image only **`KeyFrameTrajectory.txt`** (keyframes) is saved, which yields completeness of about 27%. To obtain **`CameraTrajectory.txt`** (poses for all tracked frames), the ORB-SLAM3 ROS node must be patched and recompiled.

> Note: On this particular machine and image, even after adding the call to `SaveTrajectoryEuRoC("CameraTrajectory.txt")` and rebuilding, the image still did not reliably produce `CameraTrajectory.txt`. The steps below describe the *intended* procedure; if the image still does not write the file, you should fall back to `KeyFrameTrajectory.txt` and explain the limitation in your report.

---

## Principle

- **`SaveKeyFrameTrajectoryTUM()`**: writes only keyframe poses → this is what the ROS node calls by default, producing `KeyFrameTrajectory.txt`.
- **`SaveTrajectoryEuRoC()`**: computes and writes camera poses for all tracked frames (using their relative transforms to reference keyframes) → this produces the “full-frame” trajectory with many more rows, corresponding to the reference repo’s `CameraTrajectory.txt`.

In the official `System.h`, **`SaveTrajectoryTUM`** is documented for stereo/RGB-D only; for monocular, **`SaveTrajectoryEuRoC`** is the recommended choice. Its output is compatible with the TUM / EuRoC formats that evo can evaluate.

---

## Steps (to be done inside the container)

### 1. Enter the container and locate the Mono_Compressed source file

```powershell
docker exec -it orbslam3_a2 bash
```

Inside the container:

```bash
cd /root/ORB_SLAM3
find . -name "*.cc" | xargs grep -l "SaveKeyFrameTrajectory\|Mono_Compressed\|Shutdown"
```

The file of interest is typically **`Examples_old/ROS/ORB_SLAM3/src/ros_mono_compressed.cc`** (or a similarly named `.cc` file). Open it with `cat`, `vi`, or another editor.

### 2. Add a line where the trajectory is saved on shutdown

In the source file, find the call to **`Shutdown()`** and **`SaveKeyFrameTrajectoryTUM`** (or `SaveKeyFrameTrajectoryEuRoC`). Immediately after `Shutdown()` and the existing keyframe save, add a call that saves the full-frame trajectory, for example:

```cpp
// After Shutdown(), add the following (paths can be relative)
pSLAM->Shutdown();
pSLAM->SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");   // existing behaviour
pSLAM->SaveTrajectoryEuRoC("CameraTrajectory.txt");           // new: full-frame trajectory
```

If the node uses `SLAM.` instead of `pSLAM->`, write:

```cpp
SLAM.Shutdown();
SLAM.SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");
SLAM.SaveTrajectoryEuRoC("CameraTrajectory.txt");
```

Save the file and exit the editor.

### 3. Rebuild inside the container

From the ORB_SLAM3 root:

```bash
cd /root/ORB_SLAM3
./build.sh
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:/root/ORB_SLAM3/Examples_old/ROS
./build_ros.sh
```

If the image does not provide `build_ros.sh`, use:

```bash
cd Examples_old/ROS
mkdir -p build && cd build
cmake .. -DROS_BUILD_TYPE=Release
make -j4
```

Details may vary slightly depending on the actual CMake configuration in the image.

### 4. Run the demo again and exit cleanly

Run the usual three-terminal pipeline (roscore → Mono_Compressed → rosbag play). **After the bag finishes, press Ctrl+C in the Mono_Compressed terminal** to trigger a clean shutdown.  
The trajectories should be written into **the current working directory of Mono_Compressed** (typically `/root/ORB_SLAM3/`), and you should see both:

- `KeyFrameTrajectory.txt`  
- **`CameraTrajectory.txt`**

### 5. Copy out and evaluate

On the host, from the project root in PowerShell:

```powershell
.\scripts\06_copy_camera_trajectory.ps1
.\scripts\05_run_evaluation_in_docker.ps1
```

If step 06 succeeds, script 05 will use `output/CameraTrajectory.txt` and completeness should increase significantly (potentially approaching the reference ~87%, depending on tracking quality).

---

## If you cannot find the source or the build fails

- The image may contain only pre-built ROS nodes without source code, or the relevant `.cc` file may not live under `Examples_old`. In that case you can search within the container:
  ```bash
  find /root -name "*.cc" 2>/dev/null | head -20
  ```
  Then use `grep -l SaveKeyFrameTrajectory` to locate the exact `.cc` file.
- If you cannot modify the code inside the image, you must continue to evaluate **`KeyFrameTrajectory.txt`** (completeness ≈ 27%) and clearly explain this limitation in your report: the environment only exposes a keyframe trajectory, whereas the reference uses a full-frame `CameraTrajectory`, so the completeness is not directly comparable (see `docs/completeness_and_trajectory_file.md`).

---

## References

- ORB-SLAM3 official repo: [UZ-SLAMLab/ORB_SLAM3](https://github.com/UZ-SLAMLab/ORB_SLAM3)
- Issue #273: [Difference between SaveTrajectory and SaveKeyFrameTrajectory?](https://github.com/UZ-SLAMLab/ORB_SLAM3/issues/273)
