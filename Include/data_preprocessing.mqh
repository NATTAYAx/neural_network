void PrepareData(double &inputs[], int shift = 0) {
    // Fetch historical or current price data based on shift
    double closePrice = iClose(Symbol(), PERIOD_M1, shift); // Close price for specified shift
    double high = iHigh(Symbol(), PERIOD_M1, shift);        // High price for specified shift
    double low = iLow(Symbol(), PERIOD_M1, shift);          // Low price for specified shift
    double volume = iVolume(Symbol(), PERIOD_M1, shift);    // Volume for specified shift

    // Normalize inputs to bring them to a comparable range (adjust normalization factors as needed)
    inputs[0] = closePrice / 1000.0;     // Adjusted normalization for close price
    inputs[1] = high / 1000.0;           // Adjusted normalization for high price
    inputs[2] = low / 1000.0;            // Adjusted normalization for low price
    inputs[3] = volume / 10000.0;        // Adjusted normalization for volume

    // Optional: Log inputs to check for variations
    Print("Inputs prepared with shift ", shift, ": ", inputs[0], ", ", inputs[1], ", ", inputs[2], ", ", inputs[3]);
}
