
module controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    output reg  [9:0]  input_addr,
    output reg  [11:0] weight_addr,

    output reg         valid_in,
    output reg         clear,

    output reg         result_valid,
    output reg         done,

    output wire [1:0]  group_addr,
    output reg         layer
);

    localparam IDLE       = 3'd0,
               CLEAR      = 3'd1,
               READ       = 3'd2,
               MAC        = 3'd3,
               DRAIN      = 3'd4,
               RESULT     = 3'd5,
               NEXT_GROUP = 3'd6,
               DONE       = 3'd7;

    reg [2:0] state;

    reg [9:0] input_count;
    reg [1:0] group_count;

    assign group_addr = group_count;

    wire last_input;
    wire last_group;

    assign last_input = layer ?
                        (input_count == 10'd31) :
                        (input_count == 10'd783);

    assign last_group = layer ?
                        (group_count == 2'd1) :
                        (group_count == 2'd3);

    always @(posedge clk) begin
        if (!rst_n) begin
            state        <= IDLE;
            input_count  <= 0;
            group_count  <= 0;
            input_addr   <= 0;
            weight_addr  <= 0;
            valid_in     <= 0;
            clear        <= 0;
            result_valid <= 0;
            done         <= 0;
            layer        <= 0;
        end
        else begin
            valid_in     <= 0;
            clear        <= 0;
            result_valid <= 0;
            done         <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        layer       <= 0;
                        input_count <= 0;
                        group_count <= 0;
                        state       <= CLEAR;
                    end
                end

                CLEAR: begin
                    clear       <= 1;
                    input_count <= 0;
                    input_addr  <= 0;

                    if (layer == 0)
                        weight_addr <= group_count * 12'd784;
                    else
                        weight_addr <= 12'd3136
                                     + group_count * 12'd32;

                    state <= READ;
                end

                READ: begin
                    state <= MAC;
                end

                MAC: begin
                    valid_in <= 1;

                    if (last_input) begin
                        state <= DRAIN;
                    end
                    else begin
                        input_count <= input_count + 1'b1;
                        input_addr  <= input_addr + 1'b1;
                        weight_addr <= weight_addr + 1'b1;
                    end
                end

                DRAIN: begin
                    valid_in <= 0;
                    state <= RESULT;
                end

                RESULT: begin
                    result_valid <= 1;

                    if (last_group) begin
                        if (layer == 0)
                            state <= NEXT_GROUP;
                        else
                            state <= DONE;
                    end
                    else begin
                        state <= NEXT_GROUP;
                    end
                end

                NEXT_GROUP: begin
                    if (last_group) begin
                        layer       <= 1;
                        group_count <= 0;
                    end
                    else begin
                        group_count <= group_count + 1'b1;
                    end

                    state <= CLEAR;
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
