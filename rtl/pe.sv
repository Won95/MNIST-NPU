module pe (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire clear,

    input wire signed [7:0] A_in,
    input wire signed [7:0] B_in,

    output reg signed [31:0] acc
);

    always @(posedge clk) begin
        if (!rst_n)
            acc <= 0;
        else if (clear)
            acc <= 0;
        else if (valid_in)
            acc <= acc + A_in * B_in;
    end

endmodule