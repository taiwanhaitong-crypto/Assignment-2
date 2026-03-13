$ErrorActionPreference = "Stop"

$ContainerName = "orbslam3_a2"

$cmd = @'
source /opt/ros/noetic/setup.bash
cd /root/ORB_SLAM3
rosbag play --pause data/HKisland_GNSS03.bag /left_camera/image/compressed:=/camera/image_raw/compressed
'@
$cmd = $cmd -replace "`r`n", "`n" -replace "`r", ""

docker exec -it $ContainerName bash -lc $cmd

