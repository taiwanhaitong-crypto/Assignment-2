$ErrorActionPreference = "Stop"

$ContainerName = "orbslam3_a2"

$cmd = @'
set -e
echo "DISPLAY=$DISPLAY"
apt-get update >/dev/null
apt-get install -y x11-apps >/dev/null
echo "Launching xclock (close the window to continue)..."
xclock
'@
$cmd = $cmd -replace "`r`n", "`n" -replace "`r", ""

docker exec -it $ContainerName bash -lc $cmd

