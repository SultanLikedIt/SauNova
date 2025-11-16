"""
Neural Network for Sauna Settings Recommendation
Takes user data (age, gender, height, weight, selectedGoals) and recommends
optimal temperature, humidity, and session length.
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
import pickle
import os
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')


class SaunaDataset(Dataset):
    """PyTorch Dataset for sauna recommendation data"""
    
    def __init__(self, features: np.ndarray, targets: np.ndarray):
        self.features = torch.FloatTensor(features)
        self.targets = torch.FloatTensor(targets)
    
    def __len__(self):
        return len(self.features)
    
    def __getitem__(self, idx):
        return self.features[idx], self.targets[idx]


class SaunaRecommendationModel(nn.Module):
    """Neural Network for predicting optimal sauna settings"""
    
    def __init__(self, input_size: int, hidden_sizes: List[int] = [128, 64, 32], dropout_rate: float = 0.3):
        super(SaunaRecommendationModel, self).__init__()
        
        layers = []
        prev_size = input_size
        
        # Build hidden layers
        for hidden_size in hidden_sizes:
            layers.append(nn.Linear(prev_size, hidden_size))
            layers.append(nn.ReLU())
            layers.append(nn.BatchNorm1d(hidden_size))
            layers.append(nn.Dropout(dropout_rate))
            prev_size = hidden_size
        
        # Output layer: temperature, humidity, session_length
        layers.append(nn.Linear(prev_size, 3))
        
        self.network = nn.Sequential(*layers)
    
    def forward(self, x):
        return self.network(x)


class SaunaRecommendationEngine:
    """Main engine for sauna recommendations using neural network"""
    
    def __init__(self, model_path: Optional[str] = None, scaler_path: Optional[str] = None):
        self.model = None
        self.scaler = StandardScaler()
        self.goal_encoder = LabelEncoder()
        self.gender_encoder = LabelEncoder()
        
        # Goal mapping from frontend to CSV
        self.goal_mapping = {
            'stress_reduction': 'stress_relief',
            'improving_sleep_quality': 'sleep_quality',
            'cardiovascular_health': 'cardiovascular_health',
            'muscle_recovery': 'muscle_recovery',
            'longevity': 'longevity',
            'cold_recovery': 'cold_recovery',
        }
        
        # Reverse mapping
        self.reverse_goal_mapping = {v: k for k, v in self.goal_mapping.items()}
        
        # All possible goals in the dataset (sorted alphabetically to match pd.get_dummies)
        self.all_goals = sorted(['stress_relief', 'muscle_recovery', 'cold_recovery', 
                         'longevity', 'sleep_quality', 'cardiovascular_health'])
        
        # Goal columns order (will be set during training)
        self.goal_columns = None
        
        self.model_path = model_path or 'sauna_recommendation_model.pth'
        self.scaler_path = scaler_path or 'sauna_scaler.pkl'
        
        if model_path and os.path.exists(model_path):
            self.load_model(model_path, scaler_path)
    
    def load_data(self, csv_path: str) -> pd.DataFrame:
        """Load and prepare data from CSV"""
        df = pd.read_csv(csv_path)
        return df
    
    def prepare_features(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """
        Prepare features and targets from DataFrame
        Features: age, BMI, body_mass, height, goal (one-hot encoded)
        Targets: best_temp, best_humidity, best_session
        """
        # Encode goals
        df['goal_encoded'] = self.goal_encoder.fit_transform(df['goal'])
        
        # One-hot encode goals - ensure consistent column order
        goal_onehot = pd.get_dummies(df['goal'], prefix='goal')
        
        # Sort goal columns alphabetically to ensure consistent order
        goal_cols_sorted = sorted(goal_onehot.columns)
        goal_onehot = goal_onehot[goal_cols_sorted]
        
        # Store the goal column order for prediction (extract goal names without prefix)
        self.goal_columns = goal_cols_sorted
        # Also store the goal names in sorted order
        self.all_goals = sorted([col.replace('goal_', '') for col in goal_cols_sorted])
        
        # Prepare features: age, BMI, body_mass, height + goal one-hot
        feature_cols = ['age', 'BMI', 'body_mass', 'height']
        features = df[feature_cols].values
        
        # Concatenate with one-hot encoded goals
        goal_features = goal_onehot.values
        features = np.hstack([features, goal_features])
        
        # Prepare targets
        targets = df[['best_temp', 'best_humidity', 'best_session']].values
        
        return features, targets
    
    def train(self, csv_path: str, epochs: int = 100, batch_size: int = 32, 
              learning_rate: float = 0.001, test_size: float = 0.2, 
              validation_size: float = 0.1, save_model: bool = True, ):
        """
        Train the neural network model
        """
        print("Loading data...")
        df = self.load_data(csv_path)
        print(f"Loaded {len(df)} samples")
        
        print("Preparing features...")
        features, targets = self.prepare_features(df)
        
        # Split data: train -> validation -> test
        X_train, X_temp, y_train, y_temp = train_test_split(
            features, targets, test_size=(test_size + validation_size), random_state=42
        )
        
        val_size_adjusted = validation_size / (test_size + validation_size)
        X_val, X_test, y_val, y_test = train_test_split(
            X_temp, y_temp, test_size=(1 - val_size_adjusted), random_state=42
        )
        
        print(f"Train samples: {len(X_train)}")
        print(f"Validation samples: {len(X_val)}")
        print(f"Test samples: {len(X_test)}")
        
        # Scale features
        print("Scaling features...")
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_val_scaled = self.scaler.transform(X_val)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Create datasets and data loaders
        train_dataset = SaunaDataset(X_train_scaled, y_train)
        val_dataset = SaunaDataset(X_val_scaled, y_val)
        test_dataset = SaunaDataset(X_test_scaled, y_test)
        
        train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
        val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)
        test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
        
        # Initialize model
        input_size = features.shape[1]
        self.model = SaunaRecommendationModel(input_size=input_size)
        
        # Loss and optimizer
        criterion = nn.MSELoss()
        optimizer = optim.Adam(self.model.parameters(), lr=learning_rate, weight_decay=1e-5)
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=10)
        
        # Training loop
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model.to(device)
        print(f"Using device: {device}")
        
        best_val_loss = float('inf')
        patience_counter = 0
        patience = 20
        
        print("\nStarting training...")
        for epoch in range(epochs):
            # Training
            self.model.train()
            train_loss = 0.0
            for batch_features, batch_targets in train_loader:
                batch_features = batch_features.to(device)
                batch_targets = batch_targets.to(device)
                
                optimizer.zero_grad()
                outputs = self.model(batch_features)
                loss = criterion(outputs, batch_targets)
                loss.backward()
                optimizer.step()
                
                train_loss += loss.item()
            
            # Validation
            self.model.eval()
            val_loss = 0.0
            with torch.no_grad():
                for batch_features, batch_targets in val_loader:
                    batch_features = batch_features.to(device)
                    batch_targets = batch_targets.to(device)
                    
                    outputs = self.model(batch_features)
                    loss = criterion(outputs, batch_targets)
                    val_loss += loss.item()
            
            train_loss /= len(train_loader)
            val_loss /= len(val_loader)
            
            scheduler.step(val_loss)
            
            # Early stopping
            if val_loss < best_val_loss:
                best_val_loss = val_loss
                patience_counter = 0
                if save_model:
                    self.save_model(self.model_path, self.scaler_path)
            else:
                patience_counter += 1
            
            if (epoch + 1) % 10 == 0:
                print(f"Epoch [{epoch+1}/{epochs}] - Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}")
            
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch+1}")
                break
        
        # Test evaluation
        print("\nEvaluating on test set...")
        self.model.eval()
        test_loss = 0.0
        predictions = []
        actuals = []
        
        with torch.no_grad():
            for batch_features, batch_targets in test_loader:
                batch_features = batch_features.to(device)
                batch_targets = batch_targets.to(device)
                
                outputs = self.model(batch_features)
                loss = criterion(outputs, batch_targets)
                test_loss += loss.item()
                
                predictions.append(outputs.cpu().numpy())
                actuals.append(batch_targets.cpu().numpy())
        
        test_loss /= len(test_loader)
        predictions = np.vstack(predictions)
        actuals = np.vstack(actuals)
        
        # Calculate metrics
        mae_temp = np.mean(np.abs(predictions[:, 0] - actuals[:, 0]))
        mae_humidity = np.mean(np.abs(predictions[:, 1] - actuals[:, 1]))
        mae_session = np.mean(np.abs(predictions[:, 2] - actuals[:, 2]))
        
        print(f"\nTest Results:")
        print(f"Test Loss: {test_loss:.4f}")
        print(f"MAE - Temperature: {mae_temp:.2f}°C")
        print(f"MAE - Humidity: {mae_humidity:.2f}%")
        print(f"MAE - Session Length: {mae_session:.2f} minutes")
        
        return {
            'test_loss': test_loss,
            'mae_temp': mae_temp,
            'mae_humidity': mae_humidity,
            'mae_session': mae_session
        }
    
    def predict(self, age: float, gender: str, height: float, weight: float, 
                selected_goals: List[str]) -> Dict[str, float]:
        """
        Predict optimal sauna settings for a user
        
        Args:
            age: User's age
            gender: User's gender (Male, Female, Other, Prefer not to say)
            height: User's height in meters
            weight: User's weight in kg
            selected_goals: List of goal IDs from frontend
        
        Returns:
            Dictionary with 'temperature', 'humidity', 'session_length'
        """
        if self.model is None:
            raise ValueError("Model not loaded. Please train or load a model first.")
        
        # Calculate BMI
        bmi = weight / (height ** 2)
        
        # Map frontend goals to CSV goals
        csv_goals = []
        for goal in selected_goals:
            if goal in self.goal_mapping:
                csv_goals.append(self.goal_mapping[goal])
            elif goal in self.all_goals:
                csv_goals.append(goal)
        
        # If multiple goals, we'll use the first one for now
        # Future enhancement: could average predictions or use multi-goal encoding
        if not csv_goals:
            # Default to stress_relief if no goals provided
            csv_goals = ['stress_relief']
        
        primary_goal = csv_goals[0]
        
        # Create one-hot encoding for goals using the same column order as training
        if self.goal_columns is None:
            # Fallback to sorted goals if goal_columns not set (shouldn't happen if model was trained)
            goal_cols = sorted([f'goal_{g}' for g in self.all_goals])
        else:
            goal_cols = self.goal_columns
        
        # Create feature vector in the same order as training
        feature_order = ['age', 'BMI', 'body_mass', 'height'] + goal_cols
        
        # Build feature dict with all goals set to 0, then set the primary goal to 1
        feature_dict = {
            'age': age,
            'BMI': bmi,
            'body_mass': weight,
            'height': height
        }
        
        # Initialize all goal columns to 0
        for goal_col in goal_cols:
            feature_dict[goal_col] = 0.0
        
        # Set the primary goal to 1
        primary_goal_col = f'goal_{primary_goal}'
        if primary_goal_col in feature_dict:
            feature_dict[primary_goal_col] = 1.0
        
        # Create feature array in the correct order
        features = np.array([[feature_dict[col] for col in feature_order]], dtype=np.float32)
        
        # Scale features
        features_scaled = self.scaler.transform(features)
        
        # Predict
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model.to(device)
        self.model.eval()
        
        with torch.no_grad():
            features_tensor = torch.FloatTensor(features_scaled).to(device)
            prediction = self.model(features_tensor)
            prediction = prediction.cpu().numpy()[0]
        
        # Ensure reasonable bounds
        temperature = max(60, min(100, prediction[0]))  # 60-100°C
        humidity = max(5, min(25, prediction[1]))       # 5-25%
        session_length = max(10, min(30, prediction[2])) # 10-30 minutes
        
        return {
            'temperature': round(temperature, 1),
            'humidity': round(humidity, 1),
            'session_length': round(session_length, 1)
        }
    
    def save_model(self, model_path: str, scaler_path: str):
        """Save model and scaler"""
        if self.model is None:
            raise ValueError("No model to save")
        
        torch.save(self.model.state_dict(), model_path)
        
        with open(scaler_path, 'wb') as f:
            pickle.dump(self.scaler, f)
        
        # Save encoders
        encoder_path = scaler_path.replace('.pkl', '_encoders.pkl')
        with open(encoder_path, 'wb') as f:
            pickle.dump({
                'goal_encoder': self.goal_encoder,
                'goal_mapping': self.goal_mapping,
                'all_goals': self.all_goals,
                'goal_columns': self.goal_columns
            }, f)
        
        print(f"Model saved to {model_path}")
        print(f"Scaler saved to {scaler_path}")
    
    def load_model(self, model_path: str, scaler_path: str):
        """Load model and scaler"""
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        if not os.path.exists(scaler_path):
            raise FileNotFoundError(f"Scaler file not found: {scaler_path}")
        
        # Load scaler
        with open(scaler_path, 'rb') as f:
            self.scaler = pickle.load(f)
        
        # Load encoders
        encoder_path = scaler_path.replace('.pkl', '_encoders.pkl')
        if os.path.exists(encoder_path):
            with open(encoder_path, 'rb') as f:
                encoders = pickle.load(f)
                self.goal_encoder = encoders.get('goal_encoder', self.goal_encoder)
                self.goal_mapping = encoders.get('goal_mapping', self.goal_mapping)
                self.all_goals = encoders.get('all_goals', self.all_goals)
                self.goal_columns = encoders.get('goal_columns', None)
                
                # If goal_columns not saved, reconstruct from all_goals
                if self.goal_columns is None:
                    self.goal_columns = sorted([f'goal_{g}' for g in self.all_goals])
        
        # Determine input size from scaler
        input_size = self.scaler.n_features_in_
        
        # Initialize and load model
        self.model = SaunaRecommendationModel(input_size=input_size)
        self.model.load_state_dict(torch.load(model_path, map_location='cpu'))
        self.model.eval()
        
        print(f"Model loaded from {model_path}")


if __name__ == "__main__":
    # Example usage
    engine = SaunaRecommendationEngine()
    
    # Train the model
    csv_path = "optimal_sauna_settings_with_height.csv"
    if os.path.exists(csv_path):
        print("Training model...")
        engine.train(
            csv_path=csv_path,
            epochs=200,
            batch_size=32,
            learning_rate=0.001,
            test_size=0.2,
            validation_size=0.1,
            save_model=True
        )
        
        # Test prediction
        print("\nTesting prediction...")
        prediction = engine.predict(
            age=25,
            gender="Male",
            height=1.75,
            weight=75,
            selected_goals=['stress_reduction', 'muscle_recovery']
        )
        print(f"Predicted settings: {prediction}")
    else:
        print(f"CSV file not found: {csv_path}")

