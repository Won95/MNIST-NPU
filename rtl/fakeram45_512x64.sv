module fakeram45_512x64 (
    input  wire        clk,
    input  wire        ce_in,
    input  wire        we_in,
    input  wire [8:0]  addr_in,
    input  wire [63:0] wd_in,
    input  wire [63:0] w_mask_in,
    output reg  [63:0] rd_out
);

    reg [63:0] mem [0:511];

    integer b;

    always @(posedge clk) begin
        if (ce_in) begin
            if (we_in) begin
                for (b = 0; b < 64; b = b + 1) begin
                    if (w_mask_in[b])
                        mem[addr_in][b] <= wd_in[b];
                end
            end
            else begin
                rd_out <= mem[addr_in];
            end
        end
    end

endmodule