$ErrorActionPreference = "Stop"

$ContainerName = "orbslam3_a2"
$cfg = "/root/assignment2/config/HKisland_Mono.yaml"

docker exec -it $ContainerName bash -lc "source /opt/ros/noetic/setup.bash && cd /root/ORB_SLAM3 && if [ ! -f '$cfg' ]; then echo 'Config not found: $cfg'; exit 2; fi && ./Examples_old/ROS/ORB_SLAM3/Mono_Compressed Vocabulary/ORBvoc.txt '$cfg'"
