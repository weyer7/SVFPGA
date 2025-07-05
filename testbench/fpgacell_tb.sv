`default_nettype none
`timescale 1ms/10ns
module fpgacell_tb;
  parameter BUS_WIDTH = 8;
  parameter LE_INPUTS = 4;
  parameter LE_OUTPUTS = 1;
  parameter LE_LUT_SIZE = 16;

  localparam SEL_BITS  = $clog2(2 * BUS_WIDTH + 2);
  //                     [  Switch Box ]   [             Connection Box              ]   [   Logic Element   ]
  localparam CFG_BITS = ((BUS_WIDTH*4*2) + (4 * ((LE_INPUTS + LE_OUTPUTS) * SEL_BITS)) + 4 * (LE_LUT_SIZE + 1));
 
  //========TOP-LEVEL IO==========//
  //CRAM signals                  //
  logic clk, en, nrst;            //
  logic config_data_in, config_en;//
  logic config_data_out;          //
  //configurable logic signals    //
  logic le_clk, le_en, le_nrst;   //
  //cardinal busses               //
  wire [BUS_WIDTH - 1:0] CBnorth; //
  wire [BUS_WIDTH - 1:0] SBsouth; //
  wire [BUS_WIDTH - 1:0] CBeast;  //
  wire [BUS_WIDTH - 1:0] SBwest;  //
  //==============================//

  // ====================================================================
  // HELPER FUNCTIONS
  // ====================================================================
  //unpacked route selection for testbench readability
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
  //route_sel_unpacked[index][bus] = [direction]
  //bus: north = 0, east = 1, south = 2, west = 3
  //index: from WIDTH-1 to 0 for each direction
  //direction: 0 for right, 1 for straight, 2 for left, 3 for hi-z

  // Tri-state driver signals for testbench
  logic [BUS_WIDTH-1:0] north_drv, south_drv, east_drv, west_drv;
  logic [BUS_WIDTH-1:0] north_ena, south_ena, east_ena, west_ena;

  // Tri-state assignments
  genvar i;
  generate
    for (i = 0; i < BUS_WIDTH; i++) begin
      assign CBnorth[i] = north_ena[i] ? north_drv[i] : 1'bz;
      assign SBsouth[i] = south_ena[i] ? south_drv[i] : 1'bz;
      assign CBeast[i]  = east_ena[i]  ? east_drv[i]  : 1'bz;
      assign SBwest[i]  = west_ena[i]  ? west_drv[i]  : 1'bz;
    end
  endgenerate

  logic [((LE_INPUTS + LE_OUTPUTS) * SEL_BITS) - 1:0] config_data0A, config_data0B, config_data1A, config_data1B;
  logic mode_w, mode_s, mode_e, mode_n;
  logic [LE_LUT_SIZE - 1:0] lut_data_w, lut_data_s, lut_data_e, lut_data_n;

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
      // CBinsouth = 0;
      // CBinwest = 0;
      // LEineast = 0;
      // LEinnorth = 0;
      {north_drv, south_drv, east_drv, west_drv} = '0;
      {north_ena, south_ena, east_ena, west_ena} = '0;
      config_data0A = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data0B = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data1A = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      config_data1B = {(LE_INPUTS + LE_OUTPUTS) * SEL_BITS{'1}}; // Disabled
      route_sel_flat = {BUS_WIDTH*4*2{'1}}; //disabled
      for (int i = 0; i < BUS_WIDTH; i ++) begin
        for (int j = 0; j < 4; j ++) begin
          route_sel_unpacked[i][j] = 3;
        end
      end
      {mode_w, mode_s, mode_e, mode_n} = 0;
      {lut_data_w, lut_data_s, lut_data_e, lut_data_n} = 0;
      #1;
      nrst = 1;
      le_nrst = 1;
    end
  endtask

  // =====================================================================
  // DUT INSTANTIATION
  // =====================================================================
  int test_case;
  int sub_test;

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

  //=========================================================================
  // MAIN TEST SEQUENCE
  //=========================================================================
  initial begin
    $dumpfile("waves/fpgacell.vcd");
    $dumpvars(0, fpgacell_tb);
    $display("[TEST] Starting FPGA cell test with width = %0d", BUS_WIDTH);
    test_case = 0;
    sub_test = 0;
    clear_signals();
    le_clk = 0;

    // ======================================
    // TEST 1: SIMPLE COMBINATIONAL OPERATION
    // ======================================
    test_case = 1;
    sub_test = 1;

    //[idx][from] = [to]
    //INPUTS
    route_sel_unpacked[0][2] = 2'd1; //south[0] goes straight into CB0A
    // route_sel_unpacked[3][1] = 2'd1; //south[1] goes right into CB0A
    route_sel_unpacked[1][3] = 2'd2; //west[1] goes left into CB0A

    set_config_mux0A(0, 0); //connect LEin[0] to bus0A[0]
    set_config_mux0A(1, 1); //connect LEin[1] to bus0A[1]
    //OUTPUTS
    route_sel_unpacked[2][0] = 2'd1; //north[2] from CB1A goes straight to south[2]

    set_config_mux0A(LE_INPUTS, 2); //LEout connects to bus1A[2]

    //LUT data
    lut_data_s = 16'b1000100010001000; //2-input AND with [1:0]
    mode_s = 0; //non-registered

    //CRAM
    flatten_route_sel();
    cram({route_sel_flat, config_data1B, config_data1A, config_data0B, config_data0A, {mode_w, lut_data_w}, {mode_n, lut_data_n}, {mode_e, lut_data_e}, {mode_s, lut_data_s}});
    // #5;

    sub_test = 2; //2-input operation with rest unspecified
    //set inputs to AND gate
    south_ena[0] = 1;
    west_ena[1] = 1;
    for (int i = 0; i < 4; i ++) begin
      {west_drv[1], south_drv[0]} = i[1:0];
      #1;
    end

    sub_test = 3; //consecutive CRAM without clear
    //Add one more input
    route_sel_unpacked[3][2] = 2'd1; //south[3] goes straight
    set_config_mux0A(2, 3); //connect LEin[2] to busA[3]
    //other signals don't need to be updated

    flatten_route_sel();
    cram({route_sel_flat, config_data1B, config_data1A, config_data0B, config_data0A, {mode_w, lut_data_w}, {mode_n, lut_data_n}, {mode_e, lut_data_e}, {mode_s, lut_data_s}});
    
    south_ena[3] = 1;
    sub_test = 4;//3-input operation with rest unspecified
    for (int i = 0; i < 8; i ++) begin
      {south_drv[3], west_drv[1], south_drv[0]} = i[2:0];
      #1;
    end

    // ===================================
    // TEST 2: SIMPLE SEQUENTIAL OPERATION
    // ===================================
    test_case = 2;
    sub_test = 1; //CRAM sequential design
    clear_signals();
    //JK flip-flop
    /*
    |J|K|Q|Qn|
    |0|0|0|0 |
    |0|0|1|1 |
    |0|1|0|0 |
    |0|1|1|0 |
    |1|0|0|1 |
    |1|0|1|1 |
    |1|1|0|1 |
    |1|1|1|0 |
    LEin[2:0]={J,K,Q}
    */
    mode_s = 1; //registered
    lut_data_s = 16'b01110010_01110010; //repeated twice to ignore MSB

    //first connect le_out(Q) to le_in[0] and this to a top-level switchbox output
    set_config_mux0A(LE_INPUTS, 0); //le_out to CB0A bus[0]
    set_config_mux0A(0, 0); //le_in[0] to CB0A bus[0]
    route_sel_unpacked[0][0] = 2'd1; //north[0] straight to SBsout[0]

    //then, connect K to a top-level switchbox input
    //[idx][from] = [to]
    route_sel_unpacked[1][2] = 2'd1; //south[1] straight to CB0A
    set_config_mux0A(1, 1); //le_in[1] to CB0 busA[1]

    //again for J
    route_sel_unpacked[2][2] = 2'd1; //south[2] straight to CB0A
    set_config_mux0A(2,2); //LEin[2] to CB0 busA[2]

    //now, CRAM
    flatten_route_sel();
    cram({route_sel_flat, config_data1B, config_data1A, config_data0B, config_data0A, {mode_w, lut_data_w}, {mode_n, lut_data_n}, {mode_e, lut_data_e}, {mode_s, lut_data_s}});

    sub_test = 2; //logic element nrst
    le_nrst = 0;
    #1
    le_nrst = 1;

    sub_test = 3; //regular operation
    le_en = 1;
    //set
    south_ena[1] = 1; //k
    south_ena[2] = 1; //j
    south_drv[1] = 0;
    south_drv[2] = 0;

    @(negedge le_clk); //synchronize

    south_drv[2] = 1;
    #2;
    south_drv[2] = 0;
    #4; //test hold
    //reset
    south_drv[1] = 1;
    #2;
    south_drv[1] = 0;
    #4; //test hold
    south_drv[2] = 1; //toggle
    south_drv[1] = 1;
    #2;
    south_drv[1] = 0;
    south_drv[2] = 0;
    #4; //test hold
    south_drv[2] = 1; //toggle again
    south_drv[1] = 1;
    #2;
    sub_test = 4; //disabled 
    le_en = 0;
    #4;
    le_en = 1;
    #8; //four toggles
    south_drv[1] = 0;
    south_drv[2] = 0;    
    #4; //test hold
    south_drv[2] = 1; //set
    #2;
    sub_test = 4; //mid_operation reset
    le_nrst = 0;
    #4;
    le_nrst = 1; //deassert reset
    #4;

    // =======================================
    // TEST 3: COMPLEX COMBINATIONAL OPERATION
    // =======================================
    test_case = 3;
    sub_test = 1;
    clear_signals();
    //make a 1-bit full-adder using 2 LEs
    /*
    | A | B |Cin|Sum|Cout|
    | 0 | 0 | 0 | 0 | 0  |
    | 0 | 0 | 1 | 1 | 0  |
    | 0 | 1 | 0 | 1 | 0  |
    | 0 | 1 | 1 | 0 | 1  |
    | 1 | 0 | 0 | 1 | 0  |
    | 1 | 0 | 1 | 0 | 1  |
    | 1 | 1 | 0 | 0 | 1  |
    | 1 | 1 | 1 | 1 | 1  |
    */
    //first, configure the two LUTs:
    lut_data_s = 16'b10010110_10010110; //sum
    lut_data_n = 16'b11101000_11101000; //cout

    //now, configure LE inputs
    set_config_mux0A(0,0); //connect LE_s input 0 to busA[0]
    set_config_mux0B(0,0);   //connect LE_n input 0 to busA[0]

    set_config_mux0A(1,1);
    set_config_mux0B(1,1);

    set_config_mux0A(2,2);
    set_config_mux0B(2,2);

    route_sel_unpacked[0][2] = 2'd1; //south[0] goes straight
    route_sel_unpacked[1][2] = 2'd1;
    route_sel_unpacked[2][2] = 2'd1;

    //finally, configure LE outputs:
    set_config_mux0A(LE_INPUTS, 3); //LE_s (sum) connected to busA[3]
    route_sel_unpacked[3][0] = 2'd1; //north[3] goes straight

    set_config_mux0B(LE_INPUTS, 4);
    route_sel_unpacked[4][0] = 2'd1;

    //CRAM
    flatten_route_sel();
    cram({route_sel_flat, config_data1B, config_data1A, config_data0B, config_data0A, {mode_w, lut_data_w}, {mode_n, lut_data_n}, {mode_e, lut_data_e}, {mode_s, lut_data_s}});

    sub_test = 2;
    south_ena[2:0] = '1;
    for (int i = 0; i < 8; i ++) begin
      south_drv[2:0] = i[2:0];
      #1;
    end

    //add one more test that uses all four LEs

    // ====================================
    // TEST 4: COMPLEX SEQUENTIAL OPERATION
    // ====================================

    //one test case with two LEs and one with all four

    $display("[TEST] Completed");
    $finish;
  end
endmodule
