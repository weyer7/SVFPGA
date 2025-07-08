`default_nettype none
`timescale 1ms/10ns

module CB_tb;
  parameter int WIDTH      = 8;
  parameter int LE_INPUTS  = 4;
  parameter int LE_OUTPUTS = 1;

  localparam int SEL_BITS  = $clog2(WIDTH + 2);
  localparam int CFG_BITS  = (LE_INPUTS + LE_OUTPUTS) * SEL_BITS;

  // DUT-facing inouts
  wire [WIDTH-1:0] sb_bus;
  logic config_data_inA, config_data_inB;
  logic config_en;
  logic config_data_outA, config_data_outB;
  logic clk, en, nrst;

  logic [LE_OUTPUTS-1:0] le_outA, le_outB;
  wire  [LE_INPUTS-1:0]  le_inA, le_inB;

  // Internal tri-state bus drivers
  logic [WIDTH-1:0] sb_bus_drv;
  logic [WIDTH-1:0] sb_bus_ena;



  int test_case;
  int sub_test;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin
      assign sb_bus[i] = sb_bus_ena[i] ? sb_bus_drv[i] : 1'bz;
    end
  endgenerate

  // Instantiate DUT
  CB #(
    .WIDTH(WIDTH),
    .LE_INPUTS(LE_INPUTS),
    .LE_OUTPUTS(LE_OUTPUTS)
  ) dut (
    .clk(clk), .en(en), .nrst(nrst),
    .sb_bus(sb_bus),
    .config_data_inA(config_data_inA), .config_data_inB(config_data_inB),
    .config_en(config_en),
    .config_data_outA(config_data_outA), .config_data_outB(config_data_outB),
    .le_outA(le_outA), .le_outB(le_outB),
    .le_inA(le_inA), .le_inB(le_inB)
  );

  // Helper tasks for configuring each LE
  logic [CFG_BITS - 1:0] config_dataA, config_dataB;
  task automatic set_config_muxA(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_dataA[shift +: SEL_BITS] = sel;
  endtask

  task automatic set_config_muxB(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_dataB[shift +: SEL_BITS] = sel;
  endtask

  task reset();
    begin
      clk = 0;
      nrst = 0;
      #0.05;
      nrst = 1;
      #0.05;
    end
  endtask

  task cram (logic [CFG_BITS - 1:0] dataA, dataB);
    begin
      reset();
      config_en = 1;
      for (int i = CFG_BITS; i > 0; i--) begin
        clk = 0;
        config_data_inA = dataA[i - 1];
        config_data_inB = dataB[i - 1];
        #0.05;
        clk = 1;
        #0.05;
      end
      config_en = 0;
      clear_signals();
      #0.05;
    end
  endtask

  task automatic clear_signals();
    sb_bus_ena  = '0;
    sb_bus_drv  = '0;
    le_outA     = '0;
    le_outB     = '0;
    config_dataA = {CFG_BITS{1'b1}}; // Disabled
    config_dataB = {CFG_BITS{1'b1}}; // Disabled
  endtask

  // Constants
  localparam int CONST_0 = WIDTH;
  localparam int CONST_1 = WIDTH + 1;

  // === TEST SEQUENCE ===
  initial begin
    $dumpfile("waves/CB.vcd");
    $dumpvars(0, CB_tb);
    $display("[TEST] Starting conbox test...");

    clear_signals();
    en = 1;
    nrst = 0;
    #1;
    nrst = 1;
    #1;

    // === Test 1a: LEA input 0 connected to bus A wire 2 === //
    test_case = 1;
    sub_test = 1;
    set_config_muxA(0, 2);  // maps to sb_bus[3]
    cram(config_dataA, config_dataB);

    sb_bus_ena[2] = 1;
    sb_bus_drv[2] = 1'b1;
    #1;
    sb_bus_drv[2] = 1'b0;
    #1
    sb_bus_drv[2] = 1'b1;
    #1
    $display("LEA input 0 = %b (expected 1)", le_inA[0]);
    clear_signals();
    #1

    // === Test 1b: LEA input 0 connected to bus B wire 6 === //
    sub_test = 2;
    set_config_muxA(0, 6);  // maps to sb_bus[6]
    cram(config_dataA, config_dataB);
    sb_bus_ena[6] = 1;
    sb_bus_drv[6] = 1'b1;
    #1;
    sb_bus_drv[6] = 1'b0;
    #1
    sb_bus_drv[6] = 1'b1;
    #1
    $display("LEA input 0 = %b (expected 1)", le_inA[0]);
    clear_signals();
    #1

    // === Test 2a: LEB input 1 connected to bus B wire 1 === //
    test_case = 2;
    sub_test = 1;
    set_config_muxB(1, 1);  // maps to sb_busB[1]
    cram(config_dataA, config_dataB);
    sb_bus_ena[1] = 1;
    sb_bus_drv[1] = 1'b1;
    #1;
    sb_bus_drv[1] = 1'b0;
    #1;
    sb_bus_drv[1] = 1'b1;
    #1
    $display("LEB input 1 = %b (expected 1)", le_inB[1]);
    clear_signals();
    #1

    // === Test 2b: LEB input 1 connected to bus A wire 5 === //
    test_case = 2;
    sub_test = 2;
    set_config_muxB(1, 5);  // maps to sb_busB[4]
    cram(config_dataA, config_dataB);
    sb_bus_ena[5] = 1;
    sb_bus_drv[5] = 1'b1;
    #1;
    sb_bus_drv[5] = 1'b0;
    #1;
    sb_bus_drv[5] = 1'b1;
    #1
    $display("LEB input 1 = %b (expected 1)", le_inB[1]);
    clear_signals();
    #1

    // === Test 3a: LEA input 2 tied to const 1 === //
    test_case = 3;
    sub_test = 1;
    set_config_muxA(2, CONST_1);
    cram(config_dataA, config_dataB);
    #1;
    sb_bus_ena = {WIDTH{1'd1}};
    #1
    sb_bus_drv = {WIDTH{1'd1}};
    #1
    $display("LEA input 2 = %b (expected 1)", le_inA[2]);
    clear_signals();
    #1

    // === Test 3b: LEB input 3 tied to const 1 === //
    test_case = 3;
    sub_test = 2;
    set_config_muxB(3, CONST_1);
    cram(config_dataA, config_dataB);
    #1;
    #1;
    sb_bus_ena = {WIDTH{1'd1}};
    #1
    sb_bus_drv = {WIDTH{1'd1}};
    #1;
    $display("LEB input 3 = %b (expected 0)", le_inB[3]);
    clear_signals();
    #1

    // === Test 4a: LEA output drives sb_busA[4] === //
    test_case = 4;
    sub_test = 1;
    set_config_muxA(LE_INPUTS, 4); // LEA drives sb_busA[4]
    cram(config_dataA, config_dataB);
    le_outA[0] = 1'b1;
    #1;
    le_outA[0] = 1'b0;
    #1;
    le_outA[0] = 1'b1;
    #1;
    $display("sb_busA[4] = %b (expected 1)", sb_bus[4]);
    clear_signals();
    #1

    // === Test 4b: LEB output drives sb_busB[2] === //
    test_case = 4;
    sub_test = 2;
    set_config_muxB(LE_INPUTS, 2); // LEB drives sb_busB[2]
    cram(config_dataA, config_dataB);
    le_outB[0] = 1'b1;
    #1;
    le_outB[0] = 1'b0;
    #1
    le_outB[0] = 1'b1;
    #1
    $display("sb_busB[3] = %b (expected 1)", sb_bus[3]);
    clear_signals();
    #1

    // === Test 5: LEA output drives sb_busB[2] === //
    test_case = 5;
    sub_test = 1;
    set_config_muxA(LE_INPUTS, 2); // LEB drives sb_busB[2]
    cram(config_dataA, config_dataB);
    le_outA[0] = 1'b1;
    #1;
    le_outA[0] = 1'b0;
    #1
    le_outA[0] = 1'b1;
    #1
    $display("sb_busB[2] = %b (expected 1)", sb_bus[2]);
    clear_signals();
    #1

    // === Test 6: Multiple Drivers (expected bus contention) === //
    test_case = 6;
    sub_test = 1;
    set_config_muxA(0, 0); // sb_busA[0] drives le_inA[0]
    set_config_muxA(0,2); // sb_busA[2] drives le_inA[0]
    cram(config_dataA, config_dataB);
    sb_bus_ena[0] = 1'b1;
    #1;
    sb_bus_ena[2] = 1'b1;
    #1
    sb_bus_drv[0] = 1'b1;
    #1
    sb_bus_drv[2] = 1'b1;
    #1
    sb_bus_drv[0] = 1'b0;
    #1
    sb_bus_drv[2] = 1'b0;
    #1
    $display("sb_busB[2] = %b (expected 1)", sb_bus[2]);
    clear_signals();
    #1

    // bus conetention is not possible with LE outputs; LEA and LEB can only drive even and odd indexes respectively.

    // === Test 6: Multiple Drivers (no expected bus contention) === //
    
    $display("[TEST] Completed.");
    $finish;
  end
endmodule
