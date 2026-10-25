module input_buffer (
    input  wire clk,

    // NPU read interface
    input  wire [9:0] addr,
    output reg signed [7:0] activation,

    // External image loading interface
    input  wire       load_en,
    input  wire [9:0] load_addr,
    input  wire [7:0] load_data
);

    // MNIST image: 28 x 28 = 784 pixels
    // Each pixel is represented as signed INT8.
    reg signed [7:0] memory [0:783];

    // Synchronous write
    always @(posedge clk) begin
        if (load_en && load_addr < 10'd784)
            memory[load_addr] <= load_data;
    end

    // Synchronous read (existing behavior)
    always @(posedge clk) begin
        activation <= memory[addr];
    end

endmodule
