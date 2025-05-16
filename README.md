# Anomaly Detection Dashboard

The **Anomaly Detection Dashboard** is an interactive web application built with Plotly Dash to enable real-time anomaly detection on time-series or tabular datasets. This project provides users with the ability to upload their own CSV data, preprocess it automatically, apply multiple machine learning-based anomaly detection algorithms, and visualize the detected anomalies through dynamic, intuitive graphs.

## Features Implemented

* **Dashboard Interface with Plotly Dash:**
  Developed a responsive and user-friendly dashboard UI for data upload, algorithm selection, and visualization.

* **Multiple Anomaly Detection Models:**
  Implemented three popular unsupervised anomaly detection algorithms from Scikit-learn:

  * Isolation Forest
  * One-Class SVM
  * Local Outlier Factor

* **Interactive Visualization:**
  Created line and scatter plots that dynamically highlight detected anomalies for easy interpretation.

* **Data Upload and Preprocessing:**
  Allowed users to upload custom CSV files. Built automated preprocessing including handling missing values and feature scaling to prepare the data for modeling.

* **Result Export:**
  Added functionality to download anomaly detection results for further offline analysis.


## Technology Stack Used

* **Python** for backend logic and machine learning.
* **Plotly Dash** for building the interactive dashboard UI.
* **Scikit-learn** for implementing anomaly detection algorithms.
* **Pandas & NumPy** for data handling and preprocessing.
* **Joblib** for model serialization and efficient loading.


## Usage Instructions

* Upload your time-series or tabular CSV dataset via the dashboard interface.
* Choose one of the implemented anomaly detection algorithms.
* View the interactive plots highlighting detected anomalies.
* Download the processed results if needed.


## Data Handling

* Supported CSV data with time-series or tabular format.
* Automatically preprocesses data by imputing missing values and scaling features to optimize model performance.


## Future Work (Planned Enhancements)

* Integrate performance metrics like precision, recall, and F1-score.
* Add time-series anomaly trend visualizations.
* Support real-time streaming data.
* Implement alerting and notification features.


## Project Structure (Key Components)

* `app.py`: Main dashboard application script built with Dash.
* `detect_anomalies.py`: Implementation of anomaly detection algorithms.
* `preprocess.py`: Data preprocessing functions including missing data handling and scaling.
* `requirements.txt`: List of dependencies.
* Sample datasets and models organized under dedicated folders.
