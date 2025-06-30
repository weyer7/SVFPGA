`default_nettype none
`timescale 1ms/10ns

module conbox_tb;
  parameter int WIDTH      = 8;
  parameter int LE_INPUTS  = 4;
  parameter int LE_OUTPUTS = 1;

  localparam int SEL_BITS  = $clog2(WIDTH + 2);
  localparam int CFG_BITS  = (LE_INPUTS + LE_OUTPUTS) * SEL_BITS;

  // DUT-facing inouts
  wire [WIDTH-1:0] sb_busA;
  wire [WIDTH-1:0] sb_busB;
  logic [CFG_BITS-1:0] config_dataA, config_dataB;

  logic [LE_OUTPUTS-1:0] le_outA, le_outB;
  wire  [LE_INPUTS-1:0]  le_inA, le_inB;

  // Internal tri-state bus drivers
  logic [WIDTH-1:0] sb_bus_drvA, sb_bus_drvB;
  logic [WIDTH-1:0] sb_bus_enaA, sb_bus_enaB;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin
      assign sb_busA[i] = sb_bus_enaA[i] ? sb_bus_drvA[i] : 1'bz;
      assign sb_busB[i] = sb_bus_enaB[i] ? sb_bus_drvB[i] : 1'bz;
    end
  endgenerate

  // Instantiate DUT
  conbox #(
    .WIDTH(WIDTH),
    .LE_INPUTS(LE_INPUTS),
    .LE_OUTPUTS(LE_OUTPUTS)
  ) dut (
    .sb_busA(sb_busA),
    .sb_busB(sb_busB),
    .config_dataA(config_dataA),
    .config_dataB(config_dataB),
    .le_outA(le_outA),
    .le_outB(le_outB),
    .le_inA(le_inA),
    .le_inB(le_inB)
  );

  // Helper tasks for configuring each LE
  task automatic set_config_muxA(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_dataA[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusA, BusB}[2*sel] ]
  //[0][3]  LEA input 0 to busA[6]

  task automatic set_config_muxB(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_dataB[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusB, BusA}[2*sel+1] ]
  //[0][3]  LEB input 0 to busB[7]
  //[LE_INPUTS][2]  LEB output to busB[5]

  task automatic clear_signals();
    sb_bus_enaA  = '0;
    sb_bus_drvA  = '0;
    sb_bus_enaB  = '0;
    sb_bus_drvB  = '0;
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
    $dumpfile("waves/conbox.vcd");
    $dumpvars(0, conbox_tb);
    $display("[TEST] Starting conbox test...");

    clear_signals();
    #1;

    // === Test 1a: LEA input 0 connected to bus A wire 2 === //
    set_config_muxA(0, 1);  // maps to sb_bus[3]
    sb_bus_enaA[2] = 1;
    sb_bus_drvA[2] = 1'b1;
    #1;
    sb_bus_drvA[2] = 1'b0;
    #1
    sb_bus_drvA[2] = 1'b1;
    #1
    $display("LEA input 0 = %b (expected 1)", le_inA[0]);
    clear_signals();
    #1

    // === Test 1b: LEA input 0 connected to bus B wire 6 === //
    set_config_muxA(0, 7);  // maps to sb_bus[6]
    sb_bus_enaB[6] = 1;
    sb_bus_drvB[6] = 1'b1;
    #1;
    sb_bus_drvB[6] = 1'b0;
    #1
    sb_bus_drvB[6] = 1'b1;
    #1
    $display("LEA input 0 = %b (expected 1)", le_inA[0]);
    clear_signals();
    #1

    // === Test 2a: LEB input 1 connected to bus B wire 1 === //
    set_config_muxB(1, 4);  // maps to sb_busB[1]
    sb_bus_enaB[1] = 1;
    sb_bus_drvB[1] = 1'b1;
    #1;
    sb_bus_drvB[1] = 1'b0;
    #1;
    sb_bus_drvB[1] = 1'b1;
    #1
    $display("LEB input 1 = %b (expected 1)", le_inB[1]);
    clear_signals();
    #1

    // === Test 2b: LEB input 1 connected to bus A wire 5 === //
    set_config_muxB(1, 2);  // maps to sb_busB[4]
    sb_bus_enaA[5] = 1;
    sb_bus_drvA[5] = 1'b1;
    #1;
    sb_bus_drvA[5] = 1'b0;
    #1;
    sb_bus_drvA[5] = 1'b1;
    #1
    $display("LEB input 1 = %b (expected 1)", le_inB[1]);
    clear_signals();
    #1

    // === Test 3a: LEA input 2 tied to const 1 === //
    set_config_muxA(2, CONST_1);
    #1;
    sb_bus_enaA = {WIDTH{1'd1}};
    sb_bus_enaB = {WIDTH{1'd1}};
    #1
    sb_bus_drvA = {WIDTH{1'd1}};
    sb_bus_drvB = {WIDTH{1'd1}};
    #1
    $display("LEA input 2 = %b (expected 1)", le_inA[2]);
    clear_signals();
    #1

    // === Test 3b: LEB input 3 tied to const 0 === //
    set_config_muxB(3, CONST_0);
    #1;
    #1;
    sb_bus_enaA = {WIDTH{1'd1}};
    sb_bus_enaB = {WIDTH{1'd1}};
    #1
    sb_bus_drvA = {WIDTH{1'd1}};
    sb_bus_drvB = {WIDTH{1'd1}};
    #1;
    $display("LEB input 3 = %b (expected 0)", le_inB[3]);
    clear_signals();
    #1

    // === Test 4a: LEA output drives sb_busA[4] === //
    set_config_muxA(LE_INPUTS, 2); // LEA drives sb_busA[4]
    le_outA[0] = 1'b1;
    #1;
    le_outA[0] = 1'b0;
    #1;
    le_outA[0] = 1'b1;
    #1;
    $display("sb_busA[4] = %b (expected 1)", sb_busA[4]);
    clear_signals();
    #1

    // === Test 4b: LEB output drives sb_bus[3] === //
    set_config_muxB(LE_INPUTS, 5); // LEB drives sb_busB[3]
    le_outB[0] = 1'b1;
    #1;
    le_outB[0] = 1'b0;
    #1
    le_outB[0] = 1'b1;
    #1
    $display("sb_busB[3] = %b (expected 1)", sb_busB[3]);
    clear_signals();
    #1

    // === Test 5: LEA output drives sb_busB[2] === //
    set_config_muxA(LE_INPUTS, 5); // LEB drives sb_busB[2]
    le_outA[0] = 1'b1;
    #1;
    le_outA[0] = 1'b0;
    #1
    le_outA[0] = 1'b1;
    #1
    $display("sb_busB[2] = %b (expected 1)", sb_busB[2]);
    clear_signals();
    #1

    // === Test 6: Multiple Drivers (expected bus contention) === //
    set_config_muxA(0, 0); // sb_busA[0] drives le_inA[0]
    set_config_muxA(0,1); // sb_busA[2] drives le_inA[0]
    sb_bus_enaA[0] = 1'b1;
    #1;
    sb_bus_enaA[2] = 1'b1;
    #1
    sb_bus_drvA[0] = 1'b1;
    #1
    sb_bus_drvA[2] = 1'b1;
    #1
    sb_bus_drvA[0] = 1'b0;
    #1
    sb_bus_drvA[2] = 1'b0;
    #1
    $display("sb_busB[2] = %b (expected 1)", sb_busB[2]);
    clear_signals();
    #1

    // bus conetention is not possible with LE outputs; LEA and LEB can only drive even and odd indexes respectively.

    // === Test 6: Multiple Drivers (no expected bus contention) === //
    
    $display("[TEST] Completed.");
    $finish;
  end
endmodule
