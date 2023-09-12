import openai
import json
import requests
import streamlit as st



openai.api_key = "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"

def BasicGeneration(userPrompt):
    completion = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "user", "content": userPrompt}]
    )
    return completion.choices[0].message.content


st.title('Bitcoin Analyzer With ChatGPT')
st.subheader(
    'Subscribe to my channel!')

def GetBitCoinPrices():
    
    
    # Define the API endpoint and query parameters
    url = "https://coinranking1.p.rapidapi.com/coin/Qwsogvtv82FCd/history"
    querystring = {
        "referenceCurrencyUuid": "yhjMzLPhuIDl",
        "timePeriod": "7d"
    }
    # Define the request headers with API key and host
    headers = {
        "X-RapidAPI-Key": "a617d6467dmshac84323ce581a72p11caa9jsn1adf8bbcbd47",
        "X-RapidAPI-Host": "coinranking1.p.rapidapi.com"
    }
    # Send a GET request to the API endpoint with query parameters and headers
    response = requests.request(
        "GET", url, headers=headers, params=querystring)
    # Parse the response data as a JSON object
    JSONResult = json.loads(response.text)
    # Extract the "history" field from the JSON response
    history = JSONResult["data"]["history"]
    # Extract the "price" field from each element in the "history" array and add to a list
    prices = []
    for change in history:
        prices.append(change["price"])
    # Join the list of prices into a comma-separated string
    pricesList = ','.join(prices)
    # Return the comma-separated string of prices
    return pricesList



    
if st.button('Analyze'):
    with st.spinner('Getting Bitcoin Prices...'):
        bitcoinPrices = GetBitCoinPrices()
        st.success('Done!')
    with st.spinner('Analyzing Bitcoin Prices...'):
        chatGPTPrompt = f"""You are an expert crypto trader with more than 10 years of experience, 
                    I will provide you with a list of bitcoin prices for the last 7 days
                    can you provide me with a technical analysis
                    of Bitcoin based on these prices. here is what I want: 
                    Price Overview, 
                    Moving Averages, 
                    Relative Strength Index (RSI),
                    Moving Average Convergence Divergence (MACD),
                    Advice and Suggestion,
                    Do I buy or sell?
                    Please be as detailed as much as you can, and explain in a way any beginner can understand. and make sure to use headings
                    Here is the price list: {bitcoinPrices}"""
    
        analysis = BasicGeneration(chatGPTPrompt)
        st.text_area("Analysis", analysis,
                     height=500)
        st.success('Done!')








    
    

    
    







