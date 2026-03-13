# Add SaveTrajectoryEuRoC("CameraTrajectory.txt") to ros_mono_compressed.cc in container, then rebuild.
# Run once; after that, each demo run will produce both KeyFrameTrajectory.txt and CameraTrajectory.txt.
# Usage: .\scripts\08_patch_and_build_camera_trajectory.ps1

$ErrorActionPreference = "Stop"
$ContainerName = "orbslam3_a2"
$Src = "/root/ORB_SLAM3/Examples_old/ROS/ORB_SLAM3/src/ros_mono_compressed.cc"

$cmd = @'
set -e
echo "=== Patching ros_mono_compressed.cc ==="
if grep -q "SaveTrajectoryEuRoC" /root/ORB_SLAM3/Examples_old/ROS/ORB_SLAM3/src/ros_mono_compressed.cc; then
  echo "Already patched (SaveTrajectoryEuRoC found). Skipping patch."
else
  sed -i '/SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");/a\    SLAM.SaveTrajectoryEuRoC("CameraTrajectory.txt");' /root/ORB_SLAM3/Examples_old/ROS/ORB_SLAM3/src/ros_mono_compressed.cc
  echo "Added: SLAM.SaveTrajectoryEuRoC(\"CameraTrajectory.txt\");"
fi
echo ""
echo "=== Rebuilding ORB_SLAM3 ==="
cd /root/ORB_SLAM3
./build.sh
echo ""
echo "=== Rebuilding ROS node ==="
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:/root/ORB_SLAM3/Examples_old/ROS
./build_ros.sh
echo ""
echo "=== Done. Next run of Mono_Compressed will save CameraTrajectory.txt on Ctrl+C exit. ==="
'@
$cmd = $cmd -replace "`r`n", "`n" -replace "`r", ""

docker exec -it $ContainerName bash -lc $cmd
