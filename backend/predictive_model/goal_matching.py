def inverse_dataset():
    import numpy as np
    import pandas as pd

    # Load your forward dataset
    df = pd.read_csv("synthetic_sauna_env_data.csv")

    # Define goal functions
    def stress_reduction(row):
        return -row['HRavg'] - row['HRpeak'] - 0.5*row['DBP_after'] - row['Lactic_acid'] + 0.2*(row['Temp_after'] - row['Temp_before'])

    def cardiovascular_health(row):
        return row['VO2avg'] + row['VO2max'] + 0.5*row['Energy_expenditure'] - 0.3*abs(row['HRavg']-120) - 0.2*abs(row['SBP_after']-120)


    def muscle_recovery(row):
        return row['VO2max'] + 0.05*row['Energy_expenditure'] - 0.5*row['Lactic_acid'] - 0.2*abs(row['HRpeak']-130)

    def sleep_quality(row):
        return -row['HRavg'] - row['HRpeak'] - 0.5*row['DBP_after'] + row['Recovery_time'] - 0.3*row['Lactic_acid']


    def cold_recovery(row):
        return -abs(row['HRpeak']-110) + 0.05*row['Energy_expenditure'] + 0.3*(row['Temp_after']-row['Temp_before']) + 0.2*(row['RRavg']-16)


    def longevity(row):
        return row['VO2max'] + row['HDL'] - row['Glucose'] - 0.2*abs(row['HRavg']-80) - 0.2*abs(row['SBP_after']-120) + 0.1*row['Energy_expenditure']


    # Map goal names to functions
    goal_functions = {
        "stress_relief": stress_reduction,
        "muscle_recovery": muscle_recovery,
        "cold_recovery": cold_recovery,
        "longevity": longevity,
        "sleep_quality": sleep_quality,
        "cardiovascular_health": cardiovascular_health,
    }

    # Create a new column for each goal
    for goal_name, func in goal_functions.items():
        df[goal_name + "_score"] = df.apply(func, axis=1)

    optimal_settings = []

    # Loop through each unique user (age, BMI, body_mass)
    users = df[['age', 'BMI', 'body_mass']].drop_duplicates()

    for _, user in users.iterrows():
        user_data = df[(df['age'] == user['age']) &
                       (df['BMI'] == user['BMI']) &
                       (df['body_mass'] == user['body_mass'])]

        for goal_name in goal_functions.keys():
            best_row = user_data.loc[user_data[goal_name + '_score'].idxmax()]

            optimal_settings.append({
                'age': user['age'],
                'BMI': user['BMI'],
                'body_mass': user['body_mass'],
                'goal': goal_name,
                'best_temp': best_row['SaunaTemp'],
                'best_humidity': best_row['Humidity'],
                'best_session': best_row['SessionLength']
            })

    optimal_df = pd.DataFrame(optimal_settings)


    print(optimal_df.head())
    # Optional: save to CSV
    optimal_df.to_csv("optimal_sauna_settings.csv", index=False)


def edit_dataset():
    import numpy as np
    import pandas as pd

    # Load inverse dataset
    inverse_df = pd.read_csv("optimal_sauna_settings.csv")

    # Assume some realistic height range (m)
    # If original dataset didn't include height, we can sample it to match BMI
    np.random.seed(42)
    inverse_df['height'] = np.sqrt(inverse_df['body_mass'] / inverse_df['BMI'])

    # Recalculate BMI just to be consistent
    inverse_df['BMI'] = inverse_df['body_mass'] / (inverse_df['height'] ** 2)

    # Check
    inverse_df[['body_mass', 'height', 'BMI']].head()

    # Save updated dataset
    inverse_df.to_csv("optimal_sauna_settings_with_height.csv", index=False)


if __name__ == "__main__":
    inverse_dataset()
    edit_dataset()