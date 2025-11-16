import numpy as np
import pandas as pd
import csv

#TODO: Link the variables to their indicators in human body and add columns for difference in before/after measurements

def generate_sauna_environmental_data_csv(N,
                                          age_range=(19, 26),
                                          body_mass_range=(58, 110),
                                          bmi_range=(17, 34),
                                          temp_range=(65, 95),  # °C
                                          humidity_range=(5, 20),  # %
                                          session_range=(10, 30),  # minutes
                                          filename="synthetic_sauna_env_data.csv"):
    np.random.seed(42)

    # Baseline variables
    age = np.random.randint(age_range[0], age_range[1] + 1, N)
    body_mass = np.random.uniform(body_mass_range[0], body_mass_range[1], N)
    BMI = np.random.uniform(bmi_range[0], bmi_range[1], N)

    # Environmental variables
    SaunaTemp = np.random.uniform(temp_range[0], temp_range[1], N)
    Humidity = np.random.uniform(humidity_range[0], humidity_range[1], N)
    SessionLength = np.random.uniform(session_range[0], session_range[1], N)

    # Physiological responses

    # Heart rate
    HRavg = 70 + (body_mass - 70) * 0.3 + (age - 22) * 0.5 + (SaunaTemp - 80) * 0.8 + (
                SessionLength - 10) * 0.5 + np.random.normal(0, 5, N)
    HRpeak = HRavg + 20 + 0.2 * (SaunaTemp - 80) + np.random.normal(0, 5, N)

    # Breathing
    RRavg = 16 + (HRavg - 70) * 0.05 + np.random.normal(0, 1, N)
    RRpeak = RRavg + 10 + np.random.normal(0, 2, N)

    # Energy expenditure
    Energy_expenditure = 400 + (body_mass - 70) * 5 + 0.05 * HRavg * body_mass + 5 * (
                SessionLength - 10) + np.random.normal(0, 20, N)

    # Recovery
    Recovery_time = 3 + 0.1 * (HRpeak - 70) + 0.05 * (SessionLength - 10) + np.random.normal(0, 1, N)

    # Temperature change
    Temp_before = 36.5 + np.random.normal(0, 0.2, N)
    Temp_after = Temp_before + 0.05 * (SaunaTemp - 36.5) * SessionLength / 10 + np.random.normal(0, 0.2, N)

    # Blood/metabolism
    HR_before = 70 + (age - 22) * 0.3 + np.random.normal(0, 5, N)
    HR_after = HR_before + (HRavg - 70) * 0.5 + np.random.normal(0, 5, N)

    SBP_before = 120 + (BMI - 25) * 0.8 + np.random.normal(0, 5, N)
    SBP_after = SBP_before - 5 + np.random.normal(0, 5, N)

    DBP_before = 75 + (BMI - 25) * 0.5 + np.random.normal(0, 5, N)
    DBP_after = DBP_before - 3 + np.random.normal(0, 3, N)

    Glucose = 4.5 + (BMI - 25) * 0.05 + np.random.normal(0, 0.3, N)
    HDL = 60 - (BMI - 25) * 0.5 + np.random.normal(0, 5, N)
    TG = 120 + (BMI - 25) * 2 + np.random.normal(0, 20, N)
    Lactic_acid = 1.5 + 0.01 * (HRavg - 70) + 0.02 * (SessionLength - 10) + np.random.normal(0, 0.1, N)

    VO2avg = 14 - (age - 22) * 0.1 + (body_mass - 70) * -0.05 + np.random.normal(0, 2, N)
    VO2max = 30 - (age - 22) * 0.2 + (body_mass - 70) * -0.1 + np.random.normal(0, 3, N)

    # Combine into DataFrame
    df = pd.DataFrame({
        "age": age,
        "body_mass": body_mass,
        "BMI": BMI,
        "SaunaTemp": SaunaTemp,
        "Humidity": Humidity,
        "SessionLength": SessionLength,
        "HRavg": HRavg,
        "HRpeak": HRpeak,
        "RRavg": RRavg,
        "RRpeak": RRpeak,
        "Recovery_time": Recovery_time,
        "Energy_expenditure": Energy_expenditure,
        "Temp_before": Temp_before,
        "Temp_after": Temp_after,
        "HR_before": HR_before,
        "HR_after": HR_after,
        "SBP_before": SBP_before,
        "SBP_after": SBP_after,
        "DBP_before": DBP_before,
        "DBP_after": DBP_after,
        "Glucose": Glucose,
        "HDL": HDL,
        "TG": TG,
        "Lactic_acid": Lactic_acid,
        "VO2avg": VO2avg,
        "VO2max": VO2max
    })

    # Save to CSV
    df.to_csv(filename, index=False)
    print(f"Synthetic sauna dataset saved as '{filename}' with {N} samples.")

    return df

if __name__ == "__main__":
    df = generate_sauna_environmental_data_csv(N=1000)

