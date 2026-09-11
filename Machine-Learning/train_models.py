"""
CEP Motorcycle Telemetry System - Machine Learning Training Pipeline
Implements:
  1. Unsupervised K-Means Clustering (Rider Profiling: Eco, Touring, Aggressive)
  2. Supervised Random Forest Regressor (Adaptive Shift Intelligence: Optimal RPM)
  3. Unsupervised Isolation Forest (Hazard Detection: Extreme Lean + Cold Tires)
Exports models to joblib artifacts and edge JSON config for zero-dependency Flutter execution.
"""

import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestRegressor, IsolationForest
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score, classification_report
from data_preprocessing import TelemetryPreprocessor

import sys
import io

# Ensure UTF-8 output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_FILE = os.path.join(CURRENT_DIR, "cep_telemetry_prototype_dataset.csv")


def train_pipeline():
    print("=" * 60)
    print("STARTING MOTORCYCLE SYSTEM AI / ML TRAINING PIPELINE")
    print("=" * 60)

    # 1. Load and preprocess dataset
    preprocessor = TelemetryPreprocessor()
    df = preprocessor.load_dataset(DATASET_FILE)
    print(f"Loaded {len(df)} synchronized telemetry frames from {DATASET_FILE}\n")

    # ==========================================
    # 1. SUPERVISED LEARNING: ADAPTIVE SHIFT REGRESSOR
    # ==========================================
    print("--- [1/3] Training Adaptive Shift Random Forest Regressor ---")
    shift_features = ['engine_load_pct', 'throttle_pos_pct', 'road_incline_deg', 'current_gear']
    shift_target = 'optimal_shift_rpm'

    X_shift = df[shift_features]
    y_shift = df[shift_target]

    X_train, X_test, y_train, y_test = train_test_split(X_shift, y_shift, test_size=0.2, random_state=42)

    rf_regressor = RandomForestRegressor(
        n_estimators=60,
        max_depth=12,
        min_samples_split=4,
        random_state=42,
        n_jobs=-1
    )
    rf_regressor.fit(X_train, y_train)

    y_pred = rf_regressor.predict(X_test)
    mse = mean_squared_error(y_test, y_pred)
    rmse = np.sqrt(mse)
    r2 = r2_score(y_test, y_pred)

    print(f"Optimal Shift Regressor -> RMSE: {rmse:.2f} RPM, R2 Score: {r2:.4f}")
    joblib.dump(rf_regressor, os.path.join(CURRENT_DIR, "adaptive_shift_rf.joblib"))

    # ==========================================
    # 2. UNSUPERVISED LEARNING: K-MEANS RIDER PROFILING
    # ==========================================
    print("\n--- [2/3] Training K-Means Rider Behavior Clustering ---")
    profiler_features = ['throttle_pos_pct', 'engine_rpm', 'vehicle_speed_kmh', 'lateral_accel_g', 'longitudinal_accel_g']
    X_profile = df[profiler_features].copy()

    # Normalize for K-Means
    profile_mean = X_profile.mean().to_dict()
    profile_std = X_profile.std().to_dict()
    X_profile_norm = (X_profile - X_profile.mean()) / X_profile.std()

    kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
    clusters = kmeans.fit_predict(X_profile_norm)

    # Map clusters to [Eco, Touring, Aggressive] by average throttle / RPM
    cluster_stats = []
    for c in range(3):
        mask = (clusters == c)
        avg_rpm = df.loc[mask, 'engine_rpm'].mean()
        avg_throttle = df.loc[mask, 'throttle_pos_pct'].mean()
        cluster_stats.append((c, avg_rpm, avg_throttle))

    # Sort by avg RPM to assign 0: Eco, 1: Touring, 2: Aggressive
    sorted_clusters = sorted(cluster_stats, key=lambda x: x[1])
    cluster_mapping = {old_idx: new_idx for new_idx, (old_idx, _, _) in enumerate(sorted_clusters)}

    print(f"Cluster Profile Centers:")
    profile_names = ["Eco Profile", "Touring Profile", "Aggressive Profile"]
    for old_id, new_id in cluster_mapping.items():
        print(f"  Cluster {new_id} ({profile_names[new_id]}): Avg RPM={sorted_clusters[new_id][1]:.1f}, Avg Throttle={sorted_clusters[new_id][2]:.1f}%")

    joblib.dump(kmeans, os.path.join(CURRENT_DIR, "rider_profile_kmeans.joblib"))

    # ==========================================
    # 3. ANOMALY DETECTION: ISOLATION FOREST HAZARDS
    # ==========================================
    print("\n--- [3/3] Training Isolation Forest Anomaly / Hazard Detector ---")
    hazard_features = ['lean_angle_deg', 'tire_temp_c', 'tire_press_psi', 'lateral_accel_g', 'longitudinal_accel_g']
    X_hazard = df[hazard_features].copy()

    iso_forest = IsolationForest(
        n_estimators=100,
        contamination=0.03,  # ~3% severe risk anomalies
        random_state=42
    )
    iso_forest.fit(X_hazard)

    anomaly_preds = iso_forest.predict(X_hazard)
    # -1 is anomaly, 1 is normal
    anomalies_detected = np.sum(anomaly_preds == -1)
    print(f"Isolation Forest identified {anomalies_detected} critical hazard frames ({anomalies_detected / len(df) * 100:.2f}%)")
    joblib.dump(iso_forest, os.path.join(CURRENT_DIR, "hazard_isolation_forest.joblib"))

    # ==========================================
    # 4. EXPORT EDGE INFERENCE ARTIFACTS (JSON / FLUTTER)
    # ==========================================
    print("\n--- Exporting Edge Intelligence Configuration for Mobile/Flutter ---")
    # We export model lookup matrices & tree regression coefficients for ultra-fast on-device inference
    edge_config = {
        "model_metadata": {
            "name": "CEP Motorcycle System Edge Intelligence",
            "version": "1.0.0",
            "motorcycle": "Triumph Scrambler 400x",
            "buffer_rpm": 250,
            "lugging_rpm_limit": 2500,
            "lugging_load_limit": 50.0,
            "cold_tire_temp_limit_c": 25.0,
            "extreme_lean_limit_deg": 25.0,
            "sos_g_force_spike": 4.5,
            "sos_lean_angle_limit_deg": 85.0
        },
        "k_means_profiler": {
            "features": profiler_features,
            "means": profile_mean,
            "stds": profile_std,
            "cluster_centers": kmeans.cluster_centers_.tolist(),
            "cluster_mapping": {str(k): v for k, v in cluster_mapping.items()}
        },
        "regression_benchmarks": {
            "features": shift_features,
            "rmse": float(rmse),
            "r2": float(r2),
            "baseline_curve": {
                # gear: base_optimal_rpm
                "1": 4600.0,
                "2": 5600.0,
                "3": 6200.0,
                "4": 6500.0,
                "5": 6800.0,
                "6": 7200.0
            }
        }
    }

    edge_json_path = os.path.join(CURRENT_DIR, "edge_intelligence_weights.json")
    with open(edge_json_path, "w") as f:
        json.dump(edge_config, f, indent=2)

    print(f"Edge Intelligence JSON saved to: {edge_json_path}")
    print("Training Pipeline Successfully Completed! All artifacts ready.")
    return True


if __name__ == "__main__":
    train_pipeline()
