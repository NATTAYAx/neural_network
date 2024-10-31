#include <data_preprocessing.mqh>
#include <neural_network.mqh>
#include <trading_logic.mqh>

// Initialization function
int OnInit() {
    Print("Initializing the EA and loading model weights...");
    LoadModelWeights(); // Load model weights and biases
    Print("Model weights loaded.");
    return INIT_SUCCEEDED;
}

// Main trading function that runs on every tick
void OnTick() {
    Print("OnTick triggered");
    double inputs[4];
    
    // Test over the last few historical shifts
    for (int shift = 0; shift < 5; shift++) {  
        
        if (Bars(Symbol(), PERIOD_M1) < shift + 1) {
            Print("Not enough data for shift ", shift);
            continue;
        }
        
        PrepareData(inputs, shift);
        Print("Testing with shift ", shift, ": ", inputs[0], ", ", inputs[1], ", ", inputs[2], ", ", inputs[3]);

        // Only execute trades if shift is 0 (most recent bar)
        if (shift == 0) {
            ExecuteTrade(ForwardPropagation(inputs));  // Executes with prediction directly
        }
    }
}
