"""
Training script for the Sauna Recommendation Neural Network
Run this script to train the model on the optimal_sauna_settings_with_height.csv data
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.predictive_model.neural_network import SaunaRecommendationEngine


def main():
    """Train the sauna recommendation model"""
    
    # Get the path to the CSV file
    script_dir = Path(__file__).parent
    csv_path = script_dir / "optimal_sauna_settings_with_height.csv"
    
    if not csv_path.exists():
        print(f"Error: CSV file not found at {csv_path}")
        print("Please ensure optimal_sauna_settings_with_height.csv exists in the predictive_model directory")
        return
    
    # Initialize the engine
    model_path = script_dir / "sauna_recommendation_model.pth"
    scaler_path = script_dir / "sauna_scaler.pkl"
    
    engine = SaunaRecommendationEngine(
        model_path=str(model_path) if model_path.exists() else None,
        scaler_path=str(scaler_path) if scaler_path.exists() else None
    )
    
    # Train the model
    print("=" * 60)
    print("Training Sauna Recommendation Neural Network")
    print("=" * 60)
    
    results = engine.train(
        csv_path=str(csv_path),
        epochs=200,
        batch_size=32,
        learning_rate=0.001,
        test_size=0.2,
        validation_size=0.1,
        save_model=True
    )
    
    print("\n" + "=" * 60)
    print("Training completed!")
    print("=" * 60)
    print(f"\nModel saved to: {model_path}")
    print(f"Scaler saved to: {scaler_path}")
    print(f"\nFinal Test Results:")
    print(f"  - Test Loss: {results['test_loss']:.4f}")
    print(f"  - MAE Temperature: {results['mae_temp']:.2f}°C")
    print(f"  - MAE Humidity: {results['mae_humidity']:.2f}%")
    print(f"  - MAE Session Length: {results['mae_session']:.2f} minutes")
    
    # Test with a sample prediction
    print("\n" + "=" * 60)
    print("Testing prediction with sample data...")
    print("=" * 60)
    
    sample_prediction = engine.predict(
        age=25,
        gender="Male",
        height=1.75,  # meters
        weight=75,    # kg
        selected_goals=['stress_reduction', 'muscle_recovery']
    )
    
    print(f"\nSample Prediction (Age: 25, Height: 1.75m, Weight: 75kg, Goals: stress_reduction, muscle_recovery):")
    print(f"  - Temperature: {sample_prediction['temperature']}°C")
    print(f"  - Humidity: {sample_prediction['humidity']}%")
    print(f"  - Session Length: {sample_prediction['session_length']} minutes")


if __name__ == "__main__":
    main()

