# Inspect container: find Mono_Compressed source and whether SaveTrajectoryEuRoC exists / is called.
# Usage: .\scripts\07_inspect_container_for_camera_trajectory.ps1

$ErrorActionPreference = "Stop"
$ContainerName = "orbslam3_a2"

$cmd = @'
set -e
echo "=== ORB_SLAM3 root ==="
ls -la /root/ORB_SLAM3/ 2>/dev/null || true
echo ""
echo "=== Looking for Mono_Compressed executable ==="
find /root/ORB_SLAM3 -name "Mono_Compressed" -type f 2>/dev/null
echo ""
echo "=== All .cc files under Examples_old/ROS ==="
find /root/ORB_SLAM3 -path "*Examples*" -name "*.cc" 2>/dev/null | head -30
echo ""
echo "=== Grep SaveKeyFrameTrajectory / SaveTrajectory / Shutdown in .cc ==="
for f in $(find /root/ORB_SLAM3 -name "*.cc" 2>/dev/null); do
  if grep -q "SaveKeyFrameTrajectory\|SaveTrajectory\|Shutdown" "$f" 2>/dev/null; then
    echo "--- $f ---"
    grep -n "SaveKeyFrameTrajectory\|SaveTrajectory\|Shutdown" "$f" 2>/dev/null || true
  fi
done
echo ""
echo "=== System.h / System.cc trajectory declarations ==="
grep -n "SaveTrajectory\|SaveKeyFrame" /root/ORB_SLAM3/include/System.h /root/ORB_SLAM3/src/System.cc 2>/dev/null || true
'@
$cmd = $cmd -replace "`r`n", "`n" -replace "`r", ""

docker exec $ContainerName bash -lc $cmd
