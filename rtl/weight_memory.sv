module weight_memory (
    input  wire        clk,
    input  wire [11:0] addr,
    output reg  [63:0] weight_data,

    // Weight Loading Interface
    input  wire        load_en,
    input  wire [11:0] load_addr,
    input  wire [63:0] load_data
);

    wire [11:0] selected_addr;
    wire [2:0] bank_sel;
    wire [8:0] local_addr;

    wire [63:0] bank_data [0:6];

    reg [2:0] bank_sel_d;

    assign selected_addr = load_en ? load_addr : addr;

    assign bank_sel = selected_addr[11:9];
    assign local_addr = selected_addr[8:0];

    always @(posedge clk) begin
        bank_sel_d <= bank_sel;
    end

    genvar g;

    generate
        for (g = 0; g < 7; g = g + 1) begin : GEN_SRAM

            wire bank_enable;

            assign bank_enable = (bank_sel == g);

            fakeram45_512x64 u_sram (
                .clk(clk),
                .ce_in(bank_enable),
                .we_in(load_en && bank_enable),
                .addr_in(local_addr),
                .wd_in(load_data),
                .w_mask_in(64'hFFFFFFFFFFFFFFFF),
                .rd_out(bank_data[g])
            );

        end
    endgenerate

    always @(*) begin
        case (bank_sel_d)
            3'd0: weight_data = bank_data[0];
            3'd1: weight_data = bank_data[1];
            3'd2: weight_data = bank_data[2];
            3'd3: weight_data = bank_data[3];
            3'd4: weight_data = bank_data[4];
            3'd5: weight_data = bank_data[5];
            3'd6: weight_data = bank_data[6];
            default: weight_data = 64'd0;
        endcase
    end

endmodule