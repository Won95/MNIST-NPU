
module npu_top (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input wire        weight_load_en,
    input wire [11:0] weight_load_addr,
    input wire [63:0] weight_load_data,

    output wire [3:0] digit,
    output wire done
);

    wire [9:0] input_addr;
    wire [11:0] weight_addr;
    wire [1:0] group_addr;

    wire valid_in;
    wire clear;
    wire result_valid;
    wire layer;

    wire signed [7:0] fc1_activation;
    wire signed [7:0] fc2_activation;
    wire signed [7:0] activation;

    wire [63:0] weight_data;

    wire signed [31:0] acc [0:7];
    wire signed [7:0] post_out [0:7];

    reg signed [7:0] fc1_output [0:31];
    reg signed [31:0] fc2_score [0:9];

    wire signed [31:0] score_wire [0:9];

    integer i;

    controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .input_addr(input_addr),
        .weight_addr(weight_addr),
        .valid_in(valid_in),
        .clear(clear),
        .result_valid(result_valid),
        .done(done),
        .group_addr(group_addr),
        .layer(layer)
    );

    input_buffer u_input_buffer (
        .clk(clk),
        .addr(input_addr),
        .activation(fc1_activation)
    );

    weight_memory u_weight_memory (
    .clk(clk),
    .addr(weight_addr),
    .weight_data(weight_data),
    .load_en(weight_load_en),
    .load_addr(weight_load_addr),
    .load_data(weight_load_data)
    );

    // FC1: Input Buffer
    // FC2: FC1 Output Buffer
    assign activation = (layer == 0) ?
                        fc1_activation :
                        fc2_activation;

    // FC2 Output Buffer Read
    reg signed [7:0] fc2_read_data;

    always @(posedge clk) begin
        fc2_read_data <= fc1_output[input_addr[4:0]];
    end

    assign fc2_activation = fc2_read_data;

    pe_array u_pe_array (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .clear(clear),
        .activation(activation),

        .weight1(weight_data[7:0]),
        .weight2(weight_data[15:8]),
        .weight3(weight_data[23:16]),
        .weight4(weight_data[31:24]),
        .weight5(weight_data[39:32]),
        .weight6(weight_data[47:40]),
        .weight7(weight_data[55:48]),
        .weight8(weight_data[63:56]),

        .acc1(acc[0]), .acc2(acc[1]),
        .acc3(acc[2]), .acc4(acc[3]),
        .acc5(acc[4]), .acc6(acc[5]),
        .acc7(acc[6]), .acc8(acc[7])
    );

    // FC1 Post Processing
    genvar p;
    generate
        for (p = 0; p < 8; p = p + 1) begin : GEN_POST
            post_process #(
                .SHIFT(8)
            ) u_post (
                .acc_in(acc[p]),
                .bias_in(32'sd0),
                .activation_out(post_out[p])
            );
        end
    endgenerate

    // FC1 Output / FC2 Score Storage
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                fc1_output[i] <= 0;

            for (i = 0; i < 10; i = i + 1)
                fc2_score[i] <= 0;
        end
        else if (result_valid) begin

            if (layer == 0) begin
                for (i = 0; i < 8; i = i + 1)
                    fc1_output[group_addr * 8 + i]
                        <= post_out[i];
            end
            else begin
                if (group_addr == 0) begin
                    for (i = 0; i < 8; i = i + 1)
                        fc2_score[i] <= acc[i];
                end
                else begin
                    fc2_score[8] <= acc[0];
                    fc2_score[9] <= acc[1];
                end
            end
        end
    end

    genvar s;
    generate
        for (s = 0; s < 10; s = s + 1) begin : GEN_SCORE
            assign score_wire[s] = fc2_score[s];
        end
    endgenerate

    argmax u_argmax (
        .score(score_wire),
        .digit(digit)
    );

endmodule
