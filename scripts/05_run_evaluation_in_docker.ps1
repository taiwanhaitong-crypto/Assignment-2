# Run VO evaluation inside Docker (evo works in Linux).
# Prefers CameraTrajectory.txt (full-frame, high completeness ~87%). Falls back to KeyFrame if Camera not found.
# Usage: .\scripts\05_run_evaluation_in_docker.ps1
#          → uses output/CameraTrajectory.txt if present, else output/expA_KeyFrameTrajectory.txt
#        .\scripts\05_run_evaluation_in_docker.ps1 -Trajectory expB   → uses output/expB_KeyFrameTrajectory.txt
#        .\scripts\05_run_evaluation_in_docker.ps1 -Trajectory baseline

param(
    [string]$Trajectory = "Camera"
)

$ErrorActionPreference = "Stop"
$ContainerName = "orbslam3_a2"
$Base = "/root/assignment2"
$GT = "$Base/output/ground_truth.txt"

if ($Trajectory -eq "Camera") {
    $Est = "$Base/output/CameraTrajectory.txt"
} else {
    $Est = "$Base/output/${Trajectory}_KeyFrameTrajectory.txt"
}

$WorkDir = "$Base/output/evaluation_results"
$JsonOut = "$Base/output/metrics.json"

$FallbackEst = "$Base/output/expA_KeyFrameTrajectory.txt"
$cmd = @"
set -e
echo '=== Installing evo if needed ==='
pip install evo numpy -q 2>/dev/null || true
USE_EST='$Est'
if [ ! -f "`$USE_EST" ]; then
  if [ '$Trajectory' = 'Camera' ]; then
    echo 'CameraTrajectory.txt not found (this image only saves KeyFrameTrajectory). Using expA_KeyFrameTrajectory.txt.'
    USE_EST='$FallbackEst'
    if [ ! -f "`$USE_EST" ]; then
      echo 'Error: expA_KeyFrameTrajectory.txt also not found in output/.'
      exit 2
    fi
  else
    echo 'Estimated trajectory not found: $Est'
    exit 2
  fi
fi
echo '=== Running evaluation (estimated: '"'"'$USE_EST'"'"') ==='
python3 $Base/scripts/evaluate_vo_accuracy.py \
  --groundtruth '$GT' \
  --estimated "`$USE_EST" \
  --t-max-diff 0.1 \
  --delta-m 10 \
  --workdir '$WorkDir' \
  --json-out '$JsonOut'
echo ''
echo '=== Done. metrics.json is in output/ ==='
"@
$cmd = $cmd -replace "`r`n", "`n" -replace "`r", ""

docker exec -it $ContainerName bash -lc $cmd
