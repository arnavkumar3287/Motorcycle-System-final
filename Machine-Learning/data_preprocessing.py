"""
CEP Motorcycle Telemetry System - Data Preprocessing & Synchronization Pipeline
Aligns asynchronous packets from OBD-II, BLE TPMS, and Smartphone IMU/GPS streams
across uniform millisecond timestamps and engineers edge features.
"""

import os
import numpy as np
import pandas as pd


class TelemetryPreprocessor:
    def __init__(self, sample_rate_hz: int = 10):
        self.sample_rate_hz = sample_rate_hz
        self.time_delta_ms = int(1000 / sample_rate_hz)

    def synchronize_streams(self, obd_df: pd.DataFrame, tpms_df: pd.DataFrame, imu_df: pd.DataFrame) -> pd.DataFrame:
        """
        Merge asynchronous sensor streams into uniform millisecond time buckets
        using forward-fill interpolation.
        """
        # Determine common time window
        min_time = max(obd_df['timestamp_ms'].min(), tpms_df['timestamp_ms'].min(), imu_df['timestamp_ms'].min())
        max_time = min(obd_df['timestamp_ms'].max(), tpms_df['timestamp_ms'].max(), imu_df['timestamp_ms'].max())

        uniform_timeline = pd.DataFrame({
            'timestamp_ms': np.arange(min_time, max_time + 1, self.time_delta_ms)
        })

        merged = pd.merge_asof(uniform_timeline, obd_df.sort_values('timestamp_ms'), on='timestamp_ms', direction='nearest')
        merged = pd.merge_asof(merged, tpms_df.sort_values('timestamp_ms'), on='timestamp_ms', direction='nearest')
        merged = pd.merge_asof(merged, imu_df.sort_values('timestamp_ms'), on='timestamp_ms', direction='nearest')

        return self.engineer_features(merged)

    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Extract safety, performance, and wear-and-tear engineering features.
        """
        df = df.copy()

        # 1. Rolling derivatives: Throttle Roll-On Rate (% / sec)
        time_diff_sec = df['timestamp_ms'].diff().fillna(self.time_delta_ms) / 1000.0
        time_diff_sec = time_diff_sec.replace(0, 0.1)
        df['throttle_rate_pct_s'] = (df['throttle_pos_pct'].diff().fillna(0) / time_diff_sec).clip(-300, 300)

        # 2. Engine Lugging Indicator: High load at low RPM
        df['is_lugging'] = (
            (df['engine_rpm'] < 2500) &
            (df['engine_load_pct'] > 50.0) &
            (df['current_gear'] > 1)
        ).astype(int)

        # 3. Excessive Revving Indicator (> 7,500 RPM on Scrambler 400x)
        df['is_over_revving'] = (df['engine_rpm'] > 7500).astype(int)

        # 4. Contextual Cold Tire Hazard Flag: Extreme Lean (>25 deg) with Cold Rubber (<25 deg C)
        df['cold_tire_hazard'] = (
            (df['lean_angle_deg'].abs() > 25.0) &
            (df['tire_temp_c'] < 25.0)
        ).astype(int)

        # 5. Mechanical Stress Index
        df['mechanical_stress'] = (df['engine_load_pct'] * df['engine_rpm']) / 10000.0

        # 6. Corner Exit Throttle Aggression
        df['corner_exit_aggression'] = np.where(
            (df['lean_angle_deg'].abs() > 15.0) & (df['throttle_rate_pct_s'] > 60.0),
            1,
            0
        )

        return df

    def load_dataset(self, csv_path: str) -> pd.DataFrame:
        """Load and clean telemetry dataset."""
        df = pd.read_csv(csv_path)
        # Apply feature engineering
        df = self.engineer_features(df)
        return df


if __name__ == "__main__":
    dataset_path = os.path.join(os.path.dirname(__file__), "cep_telemetry_prototype_dataset.csv")
    if os.path.exists(dataset_path):
        preprocessor = TelemetryPreprocessor()
        processed_df = preprocessor.load_dataset(dataset_path)
        print(f"Loaded and preprocessed {len(processed_df)} telemetry rows.")
        print(f"Features: {list(processed_df.columns)}")
        print(f"Cold tire hazard count: {processed_df['cold_tire_hazard'].sum()}")
        print(f"Engine lugging events: {processed_df['is_lugging'].sum()}")
    else:
        print(f"Dataset not found at: {dataset_path}")
