# Config

- **`HKisland_Mono.yaml`** — Used by `scripts/02_orbslam3_mono_compressed.ps1` for the HKisland Mono_Compressed demo. Copied from the container; edit here for parameter experiments.
- **Official yaml (assignment Config Tip):** [Calibration Results (Google Drive)](https://drive.google.com/drive/folders/1x9o3Qh4EiyJrGCGV55WtiD6Sh0M9EJbq). Compare with `HKisland.yaml` etc. if needed.

To copy the original from the container (with container running):

```powershell
docker cp orbslam3_a2:/root/ORB_SLAM3/Examples/Monocular/HKisland_Mono.yaml .\config\HKisland_Mono.yaml
```
