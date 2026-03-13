$ErrorActionPreference = "Stop"

$ContainerName = "orbslam3_a2"
$Image = "liangyu99/orbslam3_ros1:latest"
$HostAssignment2 = "D:\MSC LAE\sem2\AAE5303 ROBUST CONTROL TECHNOLOGY IN LA AERIAL VEHICLE\2\assignment2"
$ContainerAssignment2 = "/root/assignment2"

Write-Host "Stopping/removing old container (if any): $ContainerName"
docker stop $ContainerName 2>$null | Out-Null
docker rm $ContainerName 2>$null | Out-Null

Write-Host "Creating container: $ContainerName"
Write-Host "Make sure VcXsrv is running (Display :0, Disable access control)."

docker run -it --name $ContainerName `
  -e DISPLAY=host.docker.internal:0.0 `
  -e LIBGL_ALWAYS_INDIRECT=1 `
  -v "$HostAssignment2`:$ContainerAssignment2" `
  $Image bash

