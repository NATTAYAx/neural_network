#include <Trade\Trade.mqh>
#include "neural_network.mqh"

CTrade trade;

// Inputs for trading parameters
input string MySymbol = "EURUSD";
input int FastMAPeriod = 5;
input int SlowMAPeriod = 25;
input int RSIPeriod = 14;
input double RSIOverbought = 70;
input double RSIOverSold = 30;
input double LotSize = 0.1;
input double TakeProfitPoints = 200;
input double StopLossPoints = 150;
input double NeuralThreshold = 0.65;  // Lowered threshold for testing
input double MAThreshold = 1.0;       // Increased threshold to further loosen conditions
input double TrailingStopPoints = 50;

// Function to get a neural network prediction
double NeuralNetworkPrediction(double &inputs[]) {
    double prediction = ForwardPropagation(inputs); // Ensure ForwardPropagation is implemented
    Print("Neural Network Prediction: ", prediction);  // Logging prediction value
    return prediction;
}

// Function to retrieve and log market data
void RetrieveMarketData(double &fastMA, double &slowMA, double &rsi) {
    fastMA = iMA(MySymbol, PERIOD_M5, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    slowMA = iMA(MySymbol, PERIOD_M5, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
    rsi = iRSI(MySymbol, PERIOD_M5, RSIPeriod, PRICE_CLOSE);
    Print("Market Data - FastMA: ", fastMA, ", SlowMA: ", slowMA, ", RSI: ", rsi);  // Log market data
}

// Adjusted ExecuteTrade function to include Sell logic
void ExecuteTrade(double prediction) {
    double askPrice, bidPrice;

    // Retrieve current bid and ask prices
    if (!SymbolInfoDouble(MySymbol, SYMBOL_ASK, askPrice) || 
        !SymbolInfoDouble(MySymbol, SYMBOL_BID, bidPrice)) {
        Print("Failed to retrieve bid or ask price for symbol: ", MySymbol);
        return;
    }

    // Calculate market data
    double fastMA, slowMA, rsi;
    RetrieveMarketData(fastMA, slowMA, rsi);

    // Define conditions for buy and sell
    bool uptrend = (fastMA >= slowMA - MAThreshold);  // Uptrend with relaxed tolerance
    bool downtrend = (fastMA <= slowMA + MAThreshold); // Downtrend with tolerance
    bool buyAllowed = (rsi < RSIOverSold + 5);        // Buy condition based on RSI
    bool sellAllowed = (rsi > RSIOverbought - 5);     // Sell condition based on RSI

    bool existingBuy = PositionSelect(MySymbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
    bool existingSell = PositionSelect(MySymbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL;

    // Detailed logging for trade conditions
    Print("Checking trade conditions...");
    Print("Prediction: ", prediction, " NeuralThreshold: ", NeuralThreshold);
    Print("Fast MA: ", fastMA, ", Slow MA: ", slowMA);
    Print("RSI: ", rsi, ", Uptrend: ", uptrend, ", Downtrend: ", downtrend);
    Print("Buy Allowed: ", buyAllowed, ", Sell Allowed: ", sellAllowed);
    Print("Existing Buy: ", existingBuy, ", Existing Sell: ", existingSell);

    // Buy condition
    if (prediction > NeuralThreshold && uptrend && buyAllowed && !existingBuy) { 
        Print("Attempting Buy Order - Conditions Met");
        bool success = trade.Buy(LotSize, MySymbol, askPrice, askPrice - StopLossPoints * Point(), askPrice + TakeProfitPoints * Point());
        
        if (success) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            if (ticket > 0) {
                trade.PositionModify(ticket, 0, askPrice - TrailingStopPoints * Point());
                Print("Buy Order Placed with Trailing Stop");
            } else {
                Print("Error retrieving position ticket after Buy order: ", GetLastError());
            }
        } else {
            Print("Error placing Buy Order: ", GetLastError());
        }
    }
    // Sell condition
    else if (prediction < (1 - NeuralThreshold) && downtrend && sellAllowed && !existingSell) { 
        Print("Attempting Sell Order - Conditions Met");
        bool success = trade.Sell(LotSize, MySymbol, bidPrice, bidPrice + StopLossPoints * Point(), bidPrice - TakeProfitPoints * Point());
        
        if (success) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            if (ticket > 0) {
                trade.PositionModify(ticket, 0, bidPrice + TrailingStopPoints * Point());
                Print("Sell Order Placed with Trailing Stop");
            } else {
                Print("Error retrieving position ticket after Sell order: ", GetLastError());
            }
        } else {
            Print("Error placing Sell Order: ", GetLastError());
        }
    }
    // Close Buy Position when Sell conditions met
    else if (existingBuy && sellAllowed) {
        Print("Closing Buy Position as Sell conditions are met");
        trade.PositionClose(PositionGetInteger(POSITION_TICKET));
    }
    // Close Sell Position when Buy conditions met
    else if (existingSell && buyAllowed) {
        Print("Closing Sell Position as Buy conditions are met");
        trade.PositionClose(PositionGetInteger(POSITION_TICKET));
    }
    else {
        Print("No trade executed - Conditions not met.");
    }
}
