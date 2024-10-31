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

// Profit-taking targets
double initialProfitTarget = 2.5; // Increased from 2.0
double partialProfitLevel = 2.0;  // Take partial profit at 2.0
double trailingProfitLevel = 1.5; // Start trailing stop at 1.5 profit
double finalProfitTarget = 4.0;   // Ultimate target if the trend continues

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

// Function to count active buy positions
int CountBuyPositions() {
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == MySymbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            count++;
        }
    }
    return count;
}

// Adjusted ExecuteTrade function to include Sell logic and multiple buys
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

    // Adjusted uptrend and downtrend conditions
    bool uptrend = (fastMA >= slowMA - MAThreshold);
    bool downtrend = (fastMA < slowMA + MAThreshold); // Add a downtrend condition
    bool buyAllowed = (rsi < RSIOverSold + 5);        // Buy condition
    bool sellAllowed = (rsi > RSIOverbought - 5);     // Sell condition

    int buyCount = CountBuyPositions();  // Count current buy positions

    // Log trade conditions
    Print("Checking trade conditions...");
    Print("Prediction: ", prediction, " NeuralThreshold: ", NeuralThreshold);
    Print("Fast MA: ", fastMA, ", Slow MA: ", slowMA);
    Print("RSI: ", rsi, ", Uptrend: ", uptrend, ", Downtrend: ", downtrend);
    Print("Buy Allowed: ", buyAllowed, ", Sell Allowed: ", sellAllowed);
    Print("Current Buy Positions: ", buyCount);

    // Buy logic - allow up to 3 buy positions
    if (prediction > NeuralThreshold && uptrend && buyAllowed && buyCount < 3) { 
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

    // Sell logic - check and manage open buy positions
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == MySymbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            double currentProfit = PositionGetDouble(POSITION_PROFIT);

            // Partial profit-taking condition
            if (currentProfit >= partialProfitLevel) {
                Print("Partial profit target reached. Closing half of Buy Position.");
                bool success = trade.PositionClosePartial(ticket, LotSize / 2);
                if (success) {
                    Print("Partial profit taken.");
                }
            }

            // Trailing stop activation condition
            if (currentProfit >= trailingProfitLevel) {
                trade.PositionModify(ticket, 0, PositionGetDouble(POSITION_PRICE_OPEN) + TrailingStopPoints * Point());
                Print("Trailing stop activated to secure profit.");
            }

            // Final profit target
            if (currentProfit >= finalProfitTarget) {
                Print("Final profit target reached. Closing Buy Position.");
                bool success = trade.PositionClose(ticket);
                if (success) {
                    Print("Buy Position Closed Successfully at final target.");
                } else {
                    Print("Error closing Buy Position at final target: ", GetLastError());
                }
            }

            // Sell condition to exit existing buy positions
            if (prediction < NeuralThreshold && downtrend && sellAllowed) {
                Print("Sell conditions met, closing Buy Position.");
                bool success = trade.PositionClose(ticket);
                if (success) {
                    Print("Buy Position Closed due to Sell Conditions.");
                } else {
                    Print("Error closing Buy Position: ", GetLastError());
                }
            }
        }
    }
}
