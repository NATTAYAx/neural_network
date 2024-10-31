// Define the size of each layer in the neural network
double weights_input_hidden[4][5];
double weights_hidden_output[5][1];
double biases_hidden[5];
double bias_output[1];

// Function to load 4x5 weights from CSV for input to hidden layer
void LoadWeightsInputHidden() {
    int fileHandle = FileOpen("weights_input_hidden.csv", FILE_READ | FILE_CSV);
    if (fileHandle == INVALID_HANDLE) {
        Print("Error opening file: weights_input_hidden.csv - ", GetLastError());
        return;
    }

    for (int i = 0; i < 4; i++) {
        string line = FileReadString(fileHandle); // Read the entire line as a string
        string values[];                          // Create an array to hold the split values
        StringSplit(line, ',', values);           // Split the line by commas

        // Parse each value and assign it to weights_input_hidden
        for (int j = 0; j < 5; j++) {
            weights_input_hidden[i][j] = StringToDouble(values[j]);
        }
    }
    FileClose(fileHandle);
}

// Function to load 5x1 weights from CSV for hidden to output layer
void LoadWeightsHiddenOutput() {
    int fileHandle = FileOpen("weights_hidden_output.csv", FILE_READ | FILE_CSV);
    if (fileHandle == INVALID_HANDLE) {
        Print("Error opening file: weights_hidden_output.csv - ", GetLastError());
        return;
    }

    for (int i = 0; i < 5; i++) {
        weights_hidden_output[i][0] = FileReadNumber(fileHandle);
    }
    FileClose(fileHandle);
}

// Function to load biases from a CSV file
void LoadBiasesFromFile(string filename, double &biases[], int size) {
    int fileHandle = FileOpen(filename, FILE_READ | FILE_CSV);
    if (fileHandle == INVALID_HANDLE) {
        Print("Error opening file: ", filename, " - ", GetLastError());
        return;
    }

    for (int i = 0; i < size; i++) {
        biases[i] = FileReadNumber(fileHandle);
    }
    FileClose(fileHandle);
}

// Function to convert a 1D array to string for printing
string ArrayToString1D(double &array[], int size) {
    string result = "[";
    for (int i = 0; i < size; i++) {
        result += DoubleToString(array[i], 6); // Use DoubleToString to control decimal places
        if (i < size - 1) {
            result += ", ";
        }
    }
    result += "]";
    return result;
}

// Function to convert a 2D array to string for printing
string ArrayToString2D(double &array[][], int rows, int cols) {
    string result = "[";
    for (int i = 0; i < rows; i++) {
        result += "[";
        for (int j = 0; j < cols; j++) {
            result += DoubleToString(array[i][j], 6);
            if (j < cols - 1) {
                result += ", ";
            }
        }
        result += "]";
        if (i < rows - 1) {
            result += ", ";
        }
    }
    result += "]";
    return result;
}

// Updated LoadModelWeights function with debugging prints
void LoadModelWeights() {
    Print("Initializing LoadModelWeights...");
    
    LoadWeightsInputHidden();
    Print("Loaded weights_input_hidden: ", ArrayToString2D(weights_input_hidden, 4, 5));

    LoadWeightsHiddenOutput();
    Print("Loaded weights_hidden_output: ", ArrayToString2D(weights_hidden_output, 5, 1));

    LoadBiasesFromFile("biases_hidden.csv", biases_hidden, 5);
    Print("Loaded biases_hidden: ", ArrayToString1D(biases_hidden, 5));

    LoadBiasesFromFile("bias_output.csv", bias_output, 1);
    Print("Loaded bias_output: ", ArrayToString1D(bias_output, 1));

    Print("Model weights successfully loaded.");
}

// Sigmoid activation function
double Sigmoid(double x) {
    return 1.0 / (1.0 + MathExp(-x));
}

// Forward propagation function for the neural network
double ForwardPropagation(double &inputs[]) {
    double hidden_layer[5];
    
    // Calculate hidden layer values
    for (int i = 0; i < 5; i++) {
        hidden_layer[i] = biases_hidden[i]; // Start with bias
        for (int j = 0; j < 4; j++) {
            hidden_layer[i] += inputs[j] * weights_input_hidden[j][i]; // Weighted sum
        }
        hidden_layer[i] = Sigmoid(hidden_layer[i]); // Apply activation function
        
        // Log each hidden layer neuron's result
        Print("Hidden layer neuron ", i, " value: ", hidden_layer[i]);
    }

    // Calculate output layer value
    double output = bias_output[0]; // Start with output bias
    for (int i = 0; i < 5; i++) {
        output += hidden_layer[i] * weights_hidden_output[i][0]; // Weighted sum from hidden to output layer
    }
    Print("Output before activation: ", output);

    output = Sigmoid(output); // Final output with activation function
    Print("Final output after activation: ", output);
    return output;
}
