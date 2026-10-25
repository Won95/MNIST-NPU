module input_buffer (
    input  wire       clk,
    input  wire [9:0] addr,
    output reg signed [7:0] activation
);

    reg signed [7:0] memory [0:783];

    always @(posedge clk) begin
        activation <= memory[addr]; //하나의 입력전달
    end

endmodule