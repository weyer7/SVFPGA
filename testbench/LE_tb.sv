`default_nettype none
`timescale 1ms / 10ns

module LE_tb;

  localparam int LUT_SIZE = 16;
  localparam int SEL_WIDTH = $clog2(LUT_SIZE);

  // Inputs
  logic clk, en, nrst;
  logic le_clk, le_en, le_nrst;
  logic [SEL_WIDTH-1:0] selCB, selLEI, LEIdvn;
  logic config_data_in, config_en, config_data_out; // +1 for mode
  int test_case;

  // Output
  logic le_out;

  // DUT
  LE #(.LUT_SIZE(LUT_SIZE)) dut (
    .*
  );

  // Clock generation
  initial le_clk = 0;
  always #2 le_clk = ~le_clk; // 10ns clock period

  task le_reset();
    begin
      le_nrst = 0; le_en = 1; selCB = '0; selLEI = '0;
      #1;
      le_nrst = 1;
      #1;
    end
  endtask

  task reset();
    begin
      nrst = 0; en = 1; config_en = 0; config_data_in = 0; clk = 0; LEIdvn = '0;
      #1;
      nrst = 1;
      config_en = 1;
      #1;
    end
  endtask

  task cram(logic [(LUT_SIZE + 1) - 1:0] data);
    begin
      config_en = 1; //allow configuration
      for (int i = LUT_SIZE + 1; i > 0; i --) begin
        clk = 0;
        config_data_in = data[i - 1]; //MSB first
        #0.01;
        clk = 1;
        #0.01;
      end
      config_en = 0;
      clk = 0;
      config_data_in = 0;
      le_reset();
    end
  endtask

  // LUT: Implement function: f(select) = select[0] ^ select[1] (for example)
  function automatic [LUT_SIZE-1:0] make_xor_lut();
    int i;
    logic [LUT_SIZE-1:0] lut;
    begin
      for (i = 0; i < LUT_SIZE; i++) begin
        lut[i] = ^i; // XOR of lower 2 bits of select
      end
      return lut;
    end
  endfunction

  logic [LUT_SIZE-1:0] xor_lut = make_xor_lut();

  initial begin

    $dumpfile("waves/LE.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, LE_tb);

    $display("Starting testbench...");
    le_reset();
    reset();
    test_case = 0;

    // ==========================
    // TEST 1: Combinational Mode
    // ==========================
    $display("Test 1: Combinational mode");
    test_case = 1;
    cram ({1'b0, xor_lut});
    for (int i = 0; i < LUT_SIZE; i++) begin
      selCB = i;
      #1; // allow propagation
      assert (le_out == xor_lut[i]) else
        $error("FAIL: select=%0d, expected=%0b, got=%0b", i, xor_lut[i], le_out);
    end

    le_reset();
    reset();

    // =======================
    // TEST 2: Registered Mode
    // =======================
    $display("Test 2: Registered (DFF) mode");
    test_case = 2;
    cram({1'b1, xor_lut});

    for (int i = 0; i < LUT_SIZE; i++) begin
      selCB = i;
      #2;
    end

    le_reset();
    reset();

    // =========================
    // TEST 3: DFF Hold Behavior
    // =========================
    $display("Test 3: Registered mode, en=0 (hold)");
    test_case = 3;
    cram({1'b1, 16'd1});
    #2
    selCB = 0;
    #1
    le_en = 0;
    #1
    selCB = selCB + 1; // change select, but en=0
    #10
    assert (le_out == 1) else
      $error("FAIL: DFF should hold value when en=0");

    // ====================================
    // TEST 4: previous tests driven by LEI
    // ====================================

    LEIdvn = '1;
    cram ({1'b0, xor_lut});
    for (int i = 0; i < LUT_SIZE; i++) begin
      selLEI = i;
      #1; // allow propagation
      assert (le_out == xor_lut[i]) else
        $error("FAIL: select=%0d, expected=%0b, got=%0b", i, xor_lut[i], le_out);
    end

    le_reset();
    reset();

    LEIdvn = '1;
    cram({1'b1, xor_lut});

    for (int i = 0; i < LUT_SIZE; i++) begin
      selLEI = i;
      #2;
    end

    le_reset();
    reset();

    LEIdvn = '1;
    cram({1'b1, 16'd1});
    #2
    selLEI = 0;
    #1
    le_en = 0;
    #1
    selLEI = selLEI + 1; // change select, but en=0
    #10
    assert (le_out == 1) else
      $error("FAIL: DFF should hold value when en=0");

    $display("All tests completed.");
    $finish;
  end

endmodule
