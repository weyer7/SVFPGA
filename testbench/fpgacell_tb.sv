`default_nettype none
`timescale 1ms/10ns
module fpgacell_tb;
  parameter BUS_WIDTH = 4;
  parameter LE_INPUTS = 4;
  parameter LE_OUTPUTS = 1;
  parameter LE_LUT_SIZE = 16;

  localparam SEL_BITS  = $clog2(BUS_WIDTH + 2);
  localparam CFG_BITS = ((BUS_WIDTH*4*2) + (4 * ((LE_INPUTS + LE_OUTPUTS) * SEL_BITS)) + (LE_LUT_SIZE + 1));

  //CRAM signals
  logic clk, en, nrst;
  logic config_data_in, config_en;
  logic config_data_out;

  //Configurable logic signals
  logic le_clk, le_en, le_nrst;

  //NORTH
  wire [BUS_WIDTH - 1:0] CBnorth;
  logic [LE_OUTPUTS - 1:0] LEoutnorth;
  logic [LE_INPUTS - 1:0] LEinnorth;

  //SOUTH
  wire [BUS_WIDTH - 1:0] SBsouth;
  logic [LE_INPUTS - 1:0] CBoutsouth;
  logic [LE_OUTPUTS - 1:0] CBinsouth;

  //EAST
  wire [BUS_WIDTH - 1:0] CBeast;
  logic [LE_OUTPUTS - 1:0] LEouteast;
  logic [LE_INPUTS - 1:0] LEineast;

  //WEST
  wire [BUS_WIDTH - 1:0] SBwest;
  logic [LE_INPUTS - 1:0] CBoutwest;
  logic [LE_OUTPUTS - 1:0] CBinwest;

  // Unpacked route selection for testbench readability
  logic [1:0] route_sel_unpacked [0:BUS_WIDTH-1][0:3];
  logic [BUS_WIDTH*4*2 - 1:0] route_sel_flat;

  // Task: Flatten route_sel
  task automatic flatten_route_sel();
    for (int widx = 0; widx < BUS_WIDTH; widx++) begin
      for (int dir = 0; dir < 4; dir++) begin
        int flat_index = (widx * 4 + dir) * 2;
        route_sel_flat[flat_index +: 2] = route_sel_unpacked[widx][dir];
      end
    end
  endtask
  //route_sel_unpacked[bus][index] = [direction]
  //bus: north = 0, east = 1, west = 2, south = 3
  //index: from WIDTH-1 to 0 for each direction
  //direction: 0 for right, 1 for straight, 2 for left, 3 for hi-z

  logic [((LE_INPUTS + LE_OUTPUTS) * SEL_BITS) - 1:0] config_data0A, config_data0B, config_data1A, config_data1B;
  logic mode;
  logic [LE_LUT_SIZE - 1:0] lut_data;

  //=========================================================================================
  // Helper tasks for configuring each LE
  task automatic set_config_mux0A(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_data0A[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusA, BusB}[2*sel] ]
  //[0][3]  LEA input 0 to busA[6]

  task automatic set_config_mux0B(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_data0B[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusB, BusA}[2*sel+1] ]
  //[0][3]  LEB input 0 to busB[7]
  //[LE_INPUTS][2]  LEB output to busB[5]

  task automatic set_config_mux1A(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_data1A[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusA, BusB}[2*sel] ]
  //[0][3]  LEA input 0 to busA[6]

  task automatic set_config_mux1B(input int mux_index, input int sel);
    int shift = mux_index * SEL_BITS;
    config_data1B[shift +: SEL_BITS] = sel;
  endtask
  //[ ([LE_INPUTS-1:0] for LE inputs], [LE_INPUTS] for LE output) ] [ {BusB, BusA}[2*sel+1] ]
  //[0][3]  LEB input 0 to busB[7]
  //[LE_INPUTS][2]  LEB output to busB[5]
  //=========================================================================================

  // Task: CRAM configuration loading (MSB first)
  task cram(logic [CFG_BITS - 1:0] data);
    //(SB) + 2*(CB) + (LE)
    begin
      config_en = 1;
      for (int i = CFG_BITS; i > 0; i--) begin
        clk = 0;
        config_data_in = data[i-1];
        #0.05;
        clk = 1;
        #0.05;
      end
      config_en = 0;
      clk = 0;
    end
  endtask
  // <==MSB SB CB1B CB1A CB0B CB0A LE LSB==>

  // CB0 LE
  // SB CB1

  task automatic clear_signals();
    begin
      clk = 0;
      config_en = 0;
      config_data_in = 0;
      en = 1;
      le_en = 1;
      le_clk = 0;
      le_nrst = 0;
      nrst = 0;
      CBinsouth = 0;
      CBinwest = 0;
      LEineast = 0;
      LEinnorth = 0;
      config_data0A = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data0B = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data1A = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data1B = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      route_sel_flat = {BUS_WIDTH*4*2{'1}}; //disabled
      for (int i = 0; i < BUS_WIDTH; i ++) begin
        for (int j = 0; j < 4; j ++) begin
          route_sel_unpacked[j][i] = 3;
        end
      end
      mode = 0;
      lut_data = 0;
      #1;
      nrst = 1;
      le_nrst = 1;
    end
  endtask

  // DUT instantiation
  fpgacell #(
    .LE_LUT_SIZE(LE_LUT_SIZE),
    .LE_INPUTS(LE_INPUTS),
    .LE_OUTPUTS(LE_OUTPUTS),
    .BUS_WIDTH(BUS_WIDTH)
    )dut(
      .*
    );

    always begin
      #1;
      le_clk = ~le_clk;
    end

  // Main test sequence
  initial begin
    $dumpfile("waves/fpgacell.vcd");
    $dumpvars(0, fpgacell_tb);
    $display("[TEST] Starting FPGA cell test with width = %0d", BUS_WIDTH);
    clear_signals();
    le_clk = 0;

    // set_config_mux0A(0,0); //connect LEin[0] to busA[0]
    set_config_mux0B(0,2); //connect LEin[0] to busB[0]
    // set_config_mux1A(0,0);
    // set_config_mux1B(0,4);
    route_sel_unpacked[0][0] = 2'd1; //north[0] goes straight
    flatten_route_sel();
    cram({route_sel_flat, config_data1B, config_data1A, config_data0B, config_data0A, {mode, lut_data}});
    #5;

    $display("[TEST] Completed");
    $finish;
  end
endmodule
