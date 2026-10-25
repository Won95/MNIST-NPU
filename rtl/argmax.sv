
module argmax (
    input  wire signed [31:0] score [0:9],
    output reg  [3:0] digit
);

    integer i;
    reg signed [31:0] max_value;

    always @(*) begin
        max_value = score[0];
        digit = 4'd0;

        for (i = 1; i < 10; i = i + 1) begin
            if (score[i] > max_value) begin
                max_value = score[i];
                digit = i;
            end
        end
    end

endmodule
