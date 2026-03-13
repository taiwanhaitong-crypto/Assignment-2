# Output

Trajectory and evaluation outputs.

| File | Description |
|------|--------------|
| `baseline_KeyFrameTrajectory.txt` | KeyFrame trajectory — baseline |
| `expA_KeyFrameTrajectory.txt` | KeyFrame trajectory — Experiment A |
| `expB_KeyFrameTrajectory.txt` | KeyFrame trajectory — Experiment B |
| `evaluation_report.json` | (Optional) evo metrics if you run trajectory evaluation |

Copy from container after run:
```powershell
docker cp orbslam3_a2:/root/ORB_SLAM3/KeyFrameTrajectory.txt .\output\<name>_KeyFrameTrajectory.txt
```
