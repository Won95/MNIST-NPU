/*
A = [ 1 2 3
      4 5 6
      7 8 9]

B = [ 1 2 3
      4 5 6
      7 8 9]

AxB = [(1+8+21) (2+10+24) (3+12+27)
       (4+20+42) (8+25+48) (12+30+54)
       (7+32+63) (14+40+72) (21+48+81)]
*/ 


module pe_array (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire clear,

    input wire signed [7:0] activation,

    input wire signed [7:0] weight1,
    input wire signed [7:0] weight2,
    input wire signed [7:0] weight3,
    input wire signed [7:0] weight4,
    input wire signed [7:0] weight5,
    input wire signed [7:0] weight6,
    input wire signed [7:0] weight7,
    input wire signed [7:0] weight8,

    output wire signed [31:0] acc1,
    output wire signed [31:0] acc2,
    output wire signed [31:0] acc3,
    output wire signed [31:0] acc4,
    output wire signed [31:0] acc5,
    output wire signed [31:0] acc6,
    output wire signed [31:0] acc7,
    output wire signed [31:0] acc8
);

    pe pe1(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight1),
           .acc(acc1));

    pe pe2(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight2),
           .acc(acc2));

    pe pe3(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight3),
           .acc(acc3));

    pe pe4(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight4),
           .acc(acc4));

    pe pe5(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight5),
           .acc(acc5));

    pe pe6(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight6),
           .acc(acc6));

    pe pe7(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight7),
           .acc(acc7));

    pe pe8(.clk(clk),
           .rst_n(rst_n),
           .valid_in(valid_in),
           .clear(clear),
           .A_in(activation),
           .B_in(weight8),
           .acc(acc8));
endmodule

/*
module pe_test(
    parameter Datawidth = 8;
    parameter Row = 2;
    parameter Col = 2;
)
(
    input wire clk,
    input wire rst_n,
);
    reg ready;
    reg [Datawidth-1:0] DATA_A[Row-1:0][Col-1:0];
    reg [Datawidth-1:0] DATA_B[Row-1:0][Col-1:0];

    initial begin
        DATA_A=[(1,2),(3,4)];
        DATA_B=[(5,6),(7,8)];
    end
    integer cnt=0;
    always @(posedge clk) begin
        if(cnt>Row*Col) begin
            for (i = 0; i < Row ;i++) begin
                for (j = 0; j < Col ;j++ ) begin
                    A_in1 <= DATA_A[i][j];
                    B_in1 <= DATA_B[j][i];
                end
            end
            cnt++    
        end
        else ready;        
    end
    pe pe1(.clk(clk),.rst_n(rst_n),ready(ready),.A_in(A_in1),.B_in(B_in1),
    .A_out(A_out1),.B_out(B_out2),.acc(acc1));
    pe pe2(.clk(clk),.rst_n(rst_n),ready(ready),.A_in(A_out1),.B_in(B_out1),
    .A_out(A_out1),.B_out(B_out2),.acc(acc1));
    pe pe3(.clk(clk),.rst_n(rst_n),ready(ready),.A_in(A_in1),.B_in(B_in1),
    .A_out(A_out1),.B_out(B_out2),.acc(acc1));
    pe pe4(.clk(clk),.rst_n(rst_n),ready(ready),.A_in(A_in1),.B_in(B_in1),
    .A_out(A_out1),.B_out(B_out2),.acc(acc1));
    always @(posedge clk ) begin

        
    end
    
endmodule

a*b+acc

 P = [-y_M-1 2^M-1+sigma j=0~M-2 y_j 2^j]
*/
