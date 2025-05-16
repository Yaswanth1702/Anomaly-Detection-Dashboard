# Anomaly Detection Dashboard

An interactive, real-time dashboard for anomaly detection using machine learning techniques. This project allows users to upload time-series or tabular datasets, apply various anomaly detection models, and visualize the results through dynamic and intuitive graphs. It is suitable for monitoring sensor data, financial data, server logs, and other applications requiring anomaly identification.

## Features

* Dashboard UI built with Plotly Dash for interactive data exploration.
* Supports multiple machine learning models: Isolation Forest, One-Class SVM, and Local Outlier Factor.
* Visualization includes anomaly highlighting using line and scatter plots.
* Upload and analyze custom CSV datasets.
* Data preprocessing with handling for missing values and feature scaling.

## Technology Stack

* Python
* Dash by Plotly
* Scikit-learn
* Pandas and NumPy
* Joblib (for model serialization)

## Usage Instructions

* Upload a CSV dataset or select a provided sample dataset.
* Choose the anomaly detection algorithm from the available options.
* View the interactive visualization showing detected anomalies.
* Download results for further analysis if needed.

## Future Work

* Incorporate performance metrics such as precision, recall, and F1-score.
* Add time-series anomaly trend visualizations.
* Support real-time streaming data.
* Implement alerting and notification features upon anomaly detection.
