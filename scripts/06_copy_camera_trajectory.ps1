# Copy CameraTrajectory.txt from container to output/ (run after demo with Ctrl+C exit).
# Usage: .\scripts\06_copy_camera_trajectory.ps1
# If this fails (file not found), the image only saves KeyFrameTrajectory.txt — use 05 with -Trajectory expA instead.

$ErrorActionPreference = "Stop"
$ContainerName = "orbslam3_a2"
$Dest = ".\output\CameraTrajectory.txt"

docker cp "${ContainerName}:/root/ORB_SLAM3/CameraTrajectory.txt" $Dest
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: CameraTrajectory.txt not found in container. This image only saves KeyFrameTrajectory.txt."
    Write-Host "Run evaluation with KeyFrame: .\scripts\05_run_evaluation_in_docker.ps1 -Trajectory expA"
    exit 1
}
Write-Host "Copied to $Dest. Run .\scripts\05_run_evaluation_in_docker.ps1 to evaluate."
