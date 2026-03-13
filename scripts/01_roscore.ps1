$ErrorActionPreference = "Stop"

$ContainerName = "orbslam3_a2"

docker exec -it $ContainerName bash -lc "source /opt/ros/noetic/setup.bash && roscore"

