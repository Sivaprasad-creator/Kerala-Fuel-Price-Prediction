import streamlit as st
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.linear_model import LinearRegression
import numpy as np
import datetime

@st.cache_data
def load_and_train_models():
    df = pd.read_csv(r"C:/Users/Acer/Downloads/Python/Intership/Petrol Disel Trend Kerala/Kerala_Fuel_Prices.csv")
    df['Date'] = pd.to_datetime(df['Date'], dayfirst=True)
    districts = df['District'].unique()
    district_to_code = {district: i for i, district in enumerate(districts)}
    df['District_Code'] = df['District'].map(district_to_code)

    df_petrol = df[df['Fuel_Type'] == 'Petrol']
    df_diesel = df[df['Fuel_Type'] == 'Diesel']

    def prepare_features(df_subset):
        X = pd.DataFrame({
            'Date_Ordinal': df_subset['Date'].map(pd.Timestamp.toordinal),
            'District_Code': df_subset['District_Code']
        })
        y = df_subset['Price']
        return X, y

    X_petrol, y_petrol = prepare_features(df_petrol)
    X_diesel, y_diesel = prepare_features(df_diesel)

    scaler = StandardScaler()
    X_petrol_scaled = scaler.fit_transform(X_petrol)
    X_diesel_scaled = scaler.transform(X_diesel)

    pca = PCA(n_components=2)
    X_petrol_pca = pca.fit_transform(X_petrol_scaled)
    X_diesel_pca = pca.transform(X_diesel_scaled)

    model_petrol = LinearRegression()
    model_petrol.fit(X_petrol_pca, y_petrol)

    model_diesel = LinearRegression()
    model_diesel.fit(X_diesel_pca, y_diesel)

    return districts, district_to_code, scaler, pca, model_petrol, model_diesel


def predict_price(date, district, fuel_type, district_to_code, scaler, pca, model_petrol, model_diesel):
    if date is None:
        st.error("Please select a date.")
        return None
    if district == "Select district":
        st.error("Please select a district.")
        return None
    date_ord = pd.Timestamp(date).toordinal()
    district_code = district_to_code.get(district, -1)
    if district_code == -1:
        st.error("District not found.")
        return None

    X = np.array([[date_ord, district_code]])
    X_scaled = scaler.transform(X)
    X_pca = pca.transform(X_scaled)

    if fuel_type == 'Petrol':
        price = model_petrol.predict(X_pca)[0]
    else:
        price = model_diesel.predict(X_pca)[0]

    return price


def main():
    st.title("Kerala Fuel Price Prediction")

    with st.spinner("Loading data and training models..."):
        districts, district_to_code, scaler, pca, model_petrol, model_diesel = load_and_train_models()

    # Step 1: Select Fuel Type
    fuel_type = st.selectbox("Select Fuel Type", ["Select fuel type", "Petrol", "Diesel"])

    if fuel_type != "Select fuel type":
        # Show chosen fuel type label
        st.markdown(f"**Selected Fuel Type:** {fuel_type}")

        # DateTime picker with default empty state
        start_date = datetime.date(2024, 1, 1)
        end_date = datetime.date(2034, 12, 31)

        selected_date = st.date_input(
            "Select Date",
            value=None,
            min_value=start_date,
            max_value=end_date,
            key="date_input"
        )

        # To allow “no date” selected, use a trick with session state (Streamlit does not support no default date natively)
        # But for simplicity, if user picks a date, it will be stored, otherwise error shown on predict.

        # District dropdown with default option
        district_options = ["Select district"] + sorted(districts)
        selected_district = st.selectbox("Select District", district_options)

        if st.button("Predict Price"):
            price = predict_price(selected_date, selected_district, fuel_type,
                                  district_to_code, scaler, pca, model_petrol, model_diesel)
            if price is not None:
                st.success(f"Predicted {fuel_type} price on {selected_date} in {selected_district}: ₹{price:.2f}")


if __name__ == "__main__":
    main()
