# 🚗 Kerala Fuel Price Analysis (2024–2025)

![GitHub stars](https://img.shields.io/github/stars/Sivaprasad-creator/Kerala-Fuel-Price-Prediction)
![GitHub forks](https://img.shields.io/github/forks/Sivaprasad-creator/Kerala-Fuel-Price-Prediction)
![GitHub license](https://img.shields.io/github/license/Sivaprasad-creator/Kerala-Fuel-Price-Prediction)

![image alt](https://github.com/Sivaprasad-creator/Kerala-Fuel-Price-Prediction/blob/077e0b8cae2146ca6ec7c34c976a8df3f5cd8eb0/petrol-pump.jpg)

## 📌 Project Overview

This project presents a **comprehensive analysis of daily petrol and diesel prices** across all districts in Kerala from **January 1, 2024, to April 30, 2025**. It explores trends, detects anomalies, clusters districts based on fuel price behavior, and forecasts future prices using advanced **Machine Learning** and **Deep Learning** models.

> 🔧 **Tools Used:** SQL, Python, Power BI, Streamlit, Machine Learning, Deep Learning

---

## 📁 Dataset Information

- **Source:** Live internship data from public fuel website (GoodReturns)  
- **Time Period:** 01-01-2024 to 30-04-2025  
- **Records:** 13,608+  
- **Granularity:** Daily prices for 14 districts in Kerala  
- **Key Columns:**
  - `Date` – Date of record  
  - `District` – Kerala district name  
  - `Fuel Type` – Petrol or Diesel  
  - `Price` – Daily fuel price  
  - `Price_Change` – Change in price from previous day

---

## 🎯 Objectives

- Visualize fuel price trends and seasonal variations  
- Detect anomalies in price changes (spikes or drops)  
- Identify most expensive and cheapest districts  
- Cluster districts by fuel price similarity  
- Forecast future fuel prices using ML and DL models  
- Build a Streamlit app for real-time interaction

---

## 📊 Analysis Breakdown

### 🔹 Power BI Dashboard

- 📍 **District-wise Map**: Prices shown geographically  
- 📈 **Monthly Trends**: Fuel price movements across districts  
- 🔄 **Volatility Monitor**: Most fluctuating districts  
- 🎛️ **Filters**: Time slicers, fuel types, district selectors

### 🔹 SQL Insights

- District-wise average fuel prices  
- Most expensive and cheapest districts  
- Price volatility rankings  
- Year-over-year comparisons  
- Price spike detection (change ≥ ₹1)

### 🔹 Python Statistical Analysis

- Monthly mean price trends  
- Fuel change counts (↑ / ↓ / ↔)  
- Highest/lowest prices with dates  
- Most frequently occurring prices  
- Total price fluctuations per district  

---

## 📈 Exploratory Data Analysis (EDA)

- **Distribution Plots**: Frequency of price change  
- **Heatmaps**: District-wise volatility comparison  
- **Stacked Bar Charts**: Petrol vs Diesel variation  

---

## Dashboard Preview
![image alt](https://github.com/Sivaprasad-creator/Kerala-Fuel-Price-Prediction/blob/689f9ae78027072021f9bbf40a77cc3f4dceddda/Fuel%20Dashboard.png) 

---

## 🤖 Machine Learning & Deep Learning Models

| Category           | Techniques                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| **Regression**     | Linear, Ridge, Lasso, ElasticNet, Decision Tree, Random Forest, XGBoost     |
| **Clustering**     | KMeans, DBSCAN                                                              |
| **Time Series**    | ARIMA, SARIMA                                                               |
| **Deep Learning**  | LSTM (Petrol), GRU (Diesel)                                                 |
| **Anomaly Detection** | Isolation Forest, Z-Score, IQR                                           |

---

## 🚀 Streamlit Deployment

This project includes a **Streamlit web app** for:

- Real-time district and fuel selection  
- Trend exploration  
- Model-based predictions  
- Anomaly detection and clustering insights  

---

## Dashboard Preview
![image alt](https://github.com/Sivaprasad-creator/Kerala-Fuel-Price-Prediction/blob/main/petrol_deployment.png)


## 🛠️ How to Run Locally

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/Sivaprasad-creator/fuel-price-trend-kerala.git
   cd fuel-price-trend-kerala
2. **Create and activate a virtual environment (optional but recommended)**  
   - On Windows:  
     ```bash
     python -m venv venv
     venv\Scripts\activate
     ```  
   - On macOS/Linux:  
     ```bash
     python3 -m venv venv
     source venv/bin/activate
     ```

3. **Install dependencies**  
   ```bash
   pip install -r requirements.txt

---

## 📬 Author Info

**Sivaprasad T.R**  
📧 Email: sivaprasadtrwork@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/sivaprasad-t-r)  
💻 [GitHub](https://github.com/Sivaprasad-creator)

---

## 📜 Data Source

Data sourced from: [GoodReturns Kerala Petrol Price](https://www.goodreturns.in/petrol-price-in-kerala-s18.html)

---

## 🙏 Acknowledgements

Thanks to GoodReturns and Kerala government portals for providing the data.

---

## 💬 Feedback

Feel free to reach out for questions, suggestions, or collaborations!
