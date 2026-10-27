
/*module argmax (
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
*/
/* 현재
score0 ─┐
        CMP ─┐
score1 ─┘    │
             CMP ─┐
score2 ──────┘    │
                  CMP ── ... ── digit
score3 ───────────┘

10개 점수를 차례대로 비교하면 최악의 경우 9단계 비교를 거쳐야 해.
\[
D_{\text{serial}}\approx 9T_{\text{cmp}}
\]*/

/* 바꿀 구조
score0 ─┐
        CMP ─┐
score1 ─┘    │
             CMP ─┐
score2 ─┐    │    │
        CMP ─┘    │
score3 ─┘         │
                  CMP ── ...
score4 ─┐         │
        CMP ─┐    │
score5 ─┘    │    │
             CMP ─┘
score6 ─┐    │
        CMP ─┘
score7 ─┘

score8, score9도 트리에 포함

10개 점수의 비교를 균형 있게 배치하면 최대 4단계로 줄일 수 있어.
\[
D_{\text{tree}}=\lceil\log_2 10\rceil T_{\text{cmp}}
=4T_{\text{cmp}}
\]*/

module argmax (
    input  wire signed [31:0] score [0:9],
    output wire        [3:0]  digit
);

    // Stage 1: 10 -> 5
    wire signed [31:0] max1 [0:4];
    wire        [3:0]  idx1 [0:4];

    genvar i;

    generate
        for (i = 0; i < 5; i = i + 1) begin : STAGE1

            assign max1[i] =
                (score[2*i] >= score[2*i+1])
                ? score[2*i]
                : score[2*i+1];

            assign idx1[i] =
                (score[2*i] >= score[2*i+1])
                ? 4'(2*i)
                : 4'(2*i+1);

        end
    endgenerate


    // Stage 2: 5 -> 3
    wire signed [31:0] max2 [0:2];
    wire        [3:0]  idx2 [0:2];

    generate
        for (i = 0; i < 2; i = i + 1) begin : STAGE2

            assign max2[i] =
                (max1[2*i] >= max1[2*i+1])
                ? max1[2*i]
                : max1[2*i+1];

            assign idx2[i] =
                (max1[2*i] >= max1[2*i+1])
                ? idx1[2*i]
                : idx1[2*i+1];

        end
    endgenerate

    // Odd element bypass
    assign max2[2] = max1[4];
    assign idx2[2] = idx1[4];


    // Stage 3: 3 -> 2
    wire signed [31:0] max3 [0:1];
    wire        [3:0]  idx3 [0:1];

    assign max3[0] =
        (max2[0] >= max2[1])
        ? max2[0]
        : max2[1];

    assign idx3[0] =
        (max2[0] >= max2[1])
        ? idx2[0]
        : idx2[1];

    assign max3[1] = max2[2];
    assign idx3[1] = idx2[2];


    // Stage 4: 2 -> 1
    assign digit =
        (max3[0] >= max3[1])
        ? idx3[0]
        : idx3[1];

endmodule