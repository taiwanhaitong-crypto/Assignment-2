# Scripts

PowerShell scripts to run the ORB-SLAM3 HKisland demo inside Docker. Execute from the project root in **Windows PowerShell**.

| Script | Purpose |
|--------|---------|
| `00_recreate_container.ps1` | (Re)create container `orbslam3_a2` with DISPLAY and volume mount |
| `01_roscore.ps1` | Start roscore in the container (Terminal 1) |
| `02_orbslam3_mono_compressed.ps1` | Run Mono_Compressed with `config/HKisland_Mono.yaml` (Terminal 2) |
| `03_play_bag.ps1` | Play `data/HKisland_GNSS03.bag`; Space to start/pause (Terminal 3) |
| `04_x_test.ps1` | Optional: test X11 with `xclock` |
| `evaluate_vo_accuracy.py` | Python: 用 evo 计算 ATE/RPE/Completeness，输出 metrics.json |
| `05_run_evaluation_in_docker.ps1` | 在容器内跑评估；**默认用 output/CameraTrajectory.txt**（高完成度），无则提示先拷出；可选 `-Trajectory expA` / `expB` / `baseline` 用 KeyFrame |
| `06_copy_camera_trajectory.ps1` | 跑完 demo 后从容器拷出 CameraTrajectory.txt 到 output/ |

Run order: ensure container is running (`docker start orbslam3_a2`), then 01 → 02 → 03 in separate terminals.

After each run, copy trajectory to `output/` and save Pangolin screenshots to `figures/` (see main README Appendix B).
