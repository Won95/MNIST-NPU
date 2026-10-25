
`timescale 1ns/1ps

module tb_npu_mnist_extended;

  reg clk = 0, rst_n = 0, start = 0;
  wire [3:0] digit;
  wire done;

  // SRAM Weight Loading
  reg         weight_load_en   = 0;
  reg [11:0]  weight_load_addr = 0;
  reg [63:0]  weight_load_data = 0;
  reg [63:0]  weights [0:3199];

  reg [7:0] expected_fc1 [0:31];
  reg [31:0] expected_fc2 [0:9];
  reg [7:0] labels [0:999];

  integer sample, i, j, errors = 0, tests = 0, expected_digit;
  integer correct = 0, model_correct = 0, n = 100;
  integer sram_errors = 0;

  reg signed [31:0] best_score;
  reg [1023:0] filename;

  always #5 clk = ~clk;

  npu_top dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .digit(digit),
      .done(done),
      .weight_load_en(weight_load_en),
      .weight_load_addr(weight_load_addr),
      .weight_load_data(weight_load_data)
  );

  initial begin

    if (!$value$plusargs("N=%d", n))
      n = 100;

    if (n != 100 && n != 1000) begin
      $display("[FAIL] Use +N=100 or +N=1000");
      $fatal(1);
    end

    // ----------------------------------------
    // 1. Load Weight File
    // ----------------------------------------
    $readmemh("weights.hex", weights, 0, 3199);
    $readmemh("labels.hex", labels);

    // ----------------------------------------
    // 2. Write Weights into SRAM Banks
    // ----------------------------------------
    $display("[INFO] SRAM Weight Loading Start");

    weight_load_en = 0;
    rst_n = 0;

    repeat (3) @(negedge clk);

    for (i = 0; i < 3200; i = i + 1) begin
      weight_load_en   = 1'b1;
      weight_load_addr = i;
      weight_load_data = weights[i];
      @(negedge clk);
    end

    weight_load_en = 1'b0;
    weight_load_addr = 0;
    weight_load_data = 0;

    $display("[INFO] SRAM Weight Loading Complete: 3200 words");

    // ----------------------------------------
    // 2-1. SRAM Write Verification
    // ----------------------------------------
    $display("================================");
    $display("[DEBUG] SRAM Write Verification");

    $display("Bank 0 Addr 0: expected=%h actual=%h",
      weights[0],
      dut.u_weight_memory.GEN_SRAM[0].u_sram.mem[0]);

    $display("Bank 0 Addr 1: expected=%h actual=%h",
      weights[1],
      dut.u_weight_memory.GEN_SRAM[0].u_sram.mem[1]);

    $display("Bank 1 Addr 0: expected=%h actual=%h",
      weights[512],
      dut.u_weight_memory.GEN_SRAM[1].u_sram.mem[0]);

    $display("Bank 2 Addr 0: expected=%h actual=%h",
      weights[1024],
      dut.u_weight_memory.GEN_SRAM[2].u_sram.mem[0]);

    $display("Bank 3 Addr 0: expected=%h actual=%h",
      weights[1536],
      dut.u_weight_memory.GEN_SRAM[3].u_sram.mem[0]);

    $display("Bank 4 Addr 0: expected=%h actual=%h",
      weights[2048],
      dut.u_weight_memory.GEN_SRAM[4].u_sram.mem[0]);

    $display("Bank 5 Addr 0: expected=%h actual=%h",
      weights[2560],
      dut.u_weight_memory.GEN_SRAM[5].u_sram.mem[0]);

    $display("Bank 6 Addr 0: expected=%h actual=%h",
      weights[3072],
      dut.u_weight_memory.GEN_SRAM[6].u_sram.mem[0]);

    // Check representative addresses
    if (dut.u_weight_memory.GEN_SRAM[0].u_sram.mem[0] !== weights[0])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[0].u_sram.mem[1] !== weights[1])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[1].u_sram.mem[0] !== weights[512])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[2].u_sram.mem[0] !== weights[1024])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[3].u_sram.mem[0] !== weights[1536])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[4].u_sram.mem[0] !== weights[2048])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[5].u_sram.mem[0] !== weights[2560])
      sram_errors = sram_errors + 1;

    if (dut.u_weight_memory.GEN_SRAM[6].u_sram.mem[0] !== weights[3072])
      sram_errors = sram_errors + 1;

    if (sram_errors != 0) begin
      $display("[FAIL] SRAM Write Verification: %0d mismatches",
        sram_errors);
      $fatal(1);
    end

    $display("[PASS] SRAM Write Verification");
    $display("================================");

    // ----------------------------------------
    // 3. MNIST Inference Test
    // ----------------------------------------
    for (sample = 0; sample < n; sample = sample + 1) begin

      rst_n = 0;
      repeat (3) @(negedge clk);

      $sformat(filename, "image_%0d.hex", sample);
      $readmemh(filename, dut.u_input_buffer.memory, 0, 783);

      $sformat(filename, "fc1_expected_%0d.hex", sample);
      $readmemh(filename, expected_fc1, 0, 31);

      $sformat(filename, "fc2_expected_%0d.hex", sample);
      $readmemh(filename, expected_fc2, 0, 9);

      rst_n = 1;

      @(negedge clk);
      start = 1;

      @(negedge clk);
      start = 0;

      wait (done === 1'b1);
      @(negedge clk);

      // FC1 Verification
      for (i = 0; i < 32; i = i + 1) begin
        if (dut.fc1_output[i] !== $signed(expected_fc1[i])) begin
          $display(
            "[FAIL] sample=%0d FC1[%0d] expected=%0d actual=%0d",
            sample, i,
            $signed(expected_fc1[i]),
            dut.fc1_output[i]
          );
          errors = errors + 1;
        end
      end

      // FC2 Verification
      for (i = 0; i < 10; i = i + 1) begin
        if (dut.fc2_score[i] !== $signed(expected_fc2[i])) begin
          $display(
            "[FAIL] sample=%0d FC2[%0d] expected=%0d actual=%0d",
            sample, i,
            $signed(expected_fc2[i]),
            dut.fc2_score[i]
          );
          errors = errors + 1;
        end
      end

      // Expected Digit
      expected_digit = 0;
      best_score = $signed(expected_fc2[0]);

      for (j = 1; j < 10; j = j + 1) begin
        if ($signed(expected_fc2[j]) > best_score) begin
          best_score = $signed(expected_fc2[j]);
          expected_digit = j;
        end
      end

      if (digit !== expected_digit[3:0]) begin
        $display(
          "[FAIL] sample=%0d digit expected=%0d actual=%0d",
          sample, expected_digit, digit
        );
        errors = errors + 1;
      end

      if (digit === labels[sample][3:0])
        correct = correct + 1;

      if (expected_digit == labels[sample])
        model_correct = model_correct + 1;

      tests = tests + 1;

      if ((tests % 100) == 0 || tests == n)
        $display(
          "Progress %0d/%0d RTL_correct=%0d Python_correct=%0d mismatches=%0d",
          tests, n, correct, model_correct, errors
        );

    end

    // ----------------------------------------
    // 4. Final Results
    // ----------------------------------------
    $display("================================");
    $display("MNIST RTL TEST: samples=%0d mismatches=%0d", tests, errors);

    $display(
      "RTL classification accuracy: %0d/%0d (%0.2f%%)",
      correct, tests, 100.0 * correct / tests
    );

    $display(
      "Python classification accuracy: %0d/%0d (%0.2f%%)",
      model_correct, tests, 100.0 * model_correct / tests
    );

    if (errors == 0)
      $display("[PASS] RTL equals Python golden model");
    else begin
      $display("[FAIL] RTL/Python mismatch");
      $fatal(1);
    end

    $finish;
  end

  initial begin
    #50000000;
    $display("[FAIL] Simulation timeout");
    $fatal(1);
  end

endmodule
