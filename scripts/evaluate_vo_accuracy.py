#!/usr/bin/env python3
"""
AAE5303 Visual Odometry Accuracy Evaluation Script

Evaluates monocular VO trajectories using evo with four parallel metrics:
1. ATE RMSE (m) with Sim(3) alignment + scale correction
2. RPE translation drift (m/m), delta=10 m
3. RPE rotation drift (deg/100m), delta=10 m
4. Completeness (%) = matched poses / total ground-truth poses

Usage:
  python3 evaluate_vo_accuracy.py --groundtruth ground_truth.txt --estimated CameraTrajectory.txt
"""

import argparse
import json
import os
import site
import subprocess
import sys
import zipfile
from dataclasses import dataclass
from io import BytesIO
from typing import Dict, List, Tuple

import numpy as np


def _find_evo_executables() -> Tuple[str, str]:
    """Return (evo_ape, evo_rpe) full paths. On Windows pip often puts them in Scripts not on PATH."""
    exe = "evo_ape.exe" if sys.platform == "win32" else "evo_ape"
    rpe = "evo_rpe.exe" if sys.platform == "win32" else "evo_rpe"
    candidates = []
    # 1) Scripts next to this Python executable
    scripts_next_to_python = os.path.join(os.path.dirname(sys.executable), "Scripts")
    candidates.append(scripts_next_to_python)
    # 2) sys.prefix (virtualenv or system)
    candidates.append(os.path.join(sys.prefix, "Scripts"))
    # 3) user site (pip install --user)
    try:
        user_scripts = os.path.join(site.USER_BASE, "Scripts")
        candidates.append(user_scripts)
    except Exception:
        pass
    for d in candidates:
        if not os.path.isdir(d):
            continue
        ape_path = os.path.join(d, exe)
        rpe_path = os.path.join(d, rpe)
        if os.path.isfile(ape_path) and os.path.isfile(rpe_path):
            return (ape_path, rpe_path)
    # 4) try which (if already on PATH)
    try:
        import shutil
        ape_which = shutil.which("evo_ape") or shutil.which(exe)
        rpe_which = shutil.which("evo_rpe") or shutil.which(rpe)
        if ape_which and rpe_which:
            return (ape_which, rpe_which)
    except Exception:
        pass
    raise FileNotFoundError(
        "evo_ape / evo_rpe not found. Install with: pip install evo numpy. "
        "On Windows, ensure the Python Scripts folder is on PATH or reinstall evo."
    )


@dataclass(frozen=True)
class EvoStats:
    rmse: float
    mean: float
    std: float


def _count_valid_tum_poses(path: str) -> int:
    count = 0
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) < 8:
                continue
            try:
                float(parts[0])
            except ValueError:
                continue
            count += 1
    return count


def _read_evo_stats(zip_path: str) -> EvoStats:
    with zipfile.ZipFile(zip_path, "r") as zf:
        stats = json.loads(zf.read("stats.json").decode("utf-8"))
    return EvoStats(rmse=float(stats["rmse"]), mean=float(stats["mean"]), std=float(stats["std"]))


def _read_evo_timestamps_count(zip_path: str) -> int:
    with zipfile.ZipFile(zip_path, "r") as zf:
        data = zf.read("timestamps.npy")
    arr = np.load(BytesIO(data), allow_pickle=False)
    return int(arr.shape[0])


def _run(cmd: List[str]) -> None:
    proc = subprocess.run(cmd, stdout=sys.stdout, stderr=sys.stderr, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed (exit={proc.returncode}): {' '.join(cmd)}")


def evaluate_with_evo(
    gt_path: str,
    est_path: str,
    t_max_diff_s: float,
    delta_m: float,
    workdir: str,
    evo_ape_cmd: str,
    evo_rpe_cmd: str,
) -> Dict[str, float]:
    os.makedirs(workdir, exist_ok=True)
    ate_zip = os.path.join(workdir, "ate.zip")
    rpe_trans_zip = os.path.join(workdir, "rpe_trans.zip")
    rpe_rot_zip = os.path.join(workdir, "rpe_rot.zip")

    _run([
        evo_ape_cmd, "tum", gt_path, est_path,
        "--align", "--correct_scale", "--t_max_diff", str(t_max_diff_s),
        "--save_results", ate_zip, "--no_warnings", "-va",
    ])
    ate = _read_evo_stats(ate_zip)

    _run([
        evo_rpe_cmd, "tum", gt_path, est_path,
        "--align", "--correct_scale", "--t_max_diff", str(t_max_diff_s),
        "--delta", str(delta_m), "--delta_unit", "m",
        "--pose_relation", "trans_part", "--save_results", rpe_trans_zip, "--no_warnings", "-va",
    ])
    rpe_trans = _read_evo_stats(rpe_trans_zip)

    _run([
        evo_rpe_cmd, "tum", gt_path, est_path,
        "--align", "--correct_scale", "--t_max_diff", str(t_max_diff_s),
        "--delta", str(delta_m), "--delta_unit", "m",
        "--pose_relation", "angle_deg", "--save_results", rpe_rot_zip, "--no_warnings", "-va",
    ])
    rpe_rot = _read_evo_stats(rpe_rot_zip)

    gt_total = _count_valid_tum_poses(gt_path)
    matched = _read_evo_timestamps_count(ate_zip)
    completeness = 0.0 if gt_total <= 0 else 100.0 * matched / gt_total
    rpe_trans_drift_m_per_m = rpe_trans.mean / delta_m
    rpe_rot_drift_deg_per_100m = (rpe_rot.mean / delta_m) * 100.0

    return {
        "ate_rmse_m": float(ate.rmse),
        "ate_mean_m": float(ate.mean),
        "ate_std_m": float(ate.std),
        "rpe_trans_mean_m": float(rpe_trans.mean),
        "rpe_trans_rmse_m": float(rpe_trans.rmse),
        "rpe_trans_drift_m_per_m": float(rpe_trans_drift_m_per_m),
        "rpe_rot_mean_deg": float(rpe_rot.mean),
        "rpe_rot_rmse_deg": float(rpe_rot.rmse),
        "rpe_rot_drift_deg_per_100m": float(rpe_rot_drift_deg_per_100m),
        "matched_poses": int(matched),
        "gt_poses": int(gt_total),
        "completeness_pct": float(completeness),
        "t_max_diff_s": float(t_max_diff_s),
        "delta_m": float(delta_m),
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate monocular VO with evo (ATE/RPE/Completeness).")
    parser.add_argument("--groundtruth", required=True, help="Ground truth trajectory (TUM format).")
    parser.add_argument("--estimated", required=True, help="Estimated trajectory (TUM format).")
    parser.add_argument("--t-max-diff", type=float, default=0.1, help="Max timestamp association difference (s).")
    parser.add_argument("--delta-m", type=float, default=10.0, help="Distance delta for RPE (m).")
    parser.add_argument("--workdir", default="evaluation_results", help="Directory to store evo result zips.")
    parser.add_argument("--json-out", default="", help="Optional path to write a JSON report.")
    args = parser.parse_args()

    print("=" * 80)
    print("AAE5303 MONOCULAR VO EVALUATION (evo)")
    print("=" * 80)
    print(f"Ground truth: {args.groundtruth}")
    print(f"Estimated: {args.estimated}")
    print(f"Association: t_max_diff = {args.t_max_diff:.3f} s")
    print(f"RPE delta: {args.delta_m:.3f} m")
    print()

    try:
        evo_ape_cmd, evo_rpe_cmd = _find_evo_executables()
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        return 1

    try:
        metrics = evaluate_with_evo(
            gt_path=args.groundtruth,
            est_path=args.estimated,
            t_max_diff_s=args.t_max_diff,
            delta_m=args.delta_m,
            workdir=args.workdir,
            evo_ape_cmd=evo_ape_cmd,
            evo_rpe_cmd=evo_rpe_cmd,
        )
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        print("Hint: pip install evo numpy.")
        return 1
    except RuntimeError as e:
        print(f"ERROR: {e}")
        return 1

    print()
    print("=" * 80)
    print("PARALLEL METRICS (for leaderboard)")
    print("=" * 80)
    print(f"ATE RMSE (m): {metrics['ate_rmse_m']:.6f}")
    print(f"RPE trans drift (m/m): {metrics['rpe_trans_drift_m_per_m']:.6f}")
    print(f"RPE rot drift (deg/100m): {metrics['rpe_rot_drift_deg_per_100m']:.6f}")
    print(f"Completeness (%): {metrics['completeness_pct']:.2f} ({metrics['matched_poses']} / {metrics['gt_poses']})")

    if args.json_out:
        os.makedirs(os.path.dirname(args.json_out) or ".", exist_ok=True)
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2, sort_keys=True)
        print(f"\nSaved JSON report to: {args.json_out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
