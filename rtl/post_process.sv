
module post_process #(
    parameter integer SHIFT = 8
)(
    input  wire signed [31:0] acc_in,
    input  wire signed [31:0] bias_in,

    output reg signed [7:0] activation_out
);

    // Bias Addition
    // 33-bit로 확장하여 덧셈 Overflow 방지
    wire signed [32:0] biased;

    assign biased =
        $signed({acc_in[31], acc_in}) +
        $signed({bias_in[31], bias_in});

    // ReLU
    wire signed [32:0] relu_out;

    assign relu_out =
        (biased < 0) ? 33'sd0 : biased;

    // Requantization: Arithmetic Right Shift
    wire signed [32:0] shifted;

    assign shifted = relu_out >>> SHIFT;

    // Saturation: INT8 범위 0~127
    always @(*) begin
        if (shifted > 33'sd127)
            activation_out = 8'sd127;
        else
            activation_out = shifted[7:0];
    end

endmodule
