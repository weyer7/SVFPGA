`default_nettype none
module fpgacell #(
  parameter
    BUS_WIDTH = 14,
    LE_INPUTS = 4,
    LE_OUTPUTS = 1,
    LE_LUT_SIZE = 16
)(
  //CRAM signals
  input logic clk, nrst,
  input logic config_data_in, config_en,
  output logic config_data_out,

  //Configurable logic signals
  input logic le_clk, le_en, le_nrst,

  //NORTH
  // inout wire [BUS_WIDTH - 1:0] SBnorth,
  input logic [BUS_WIDTH - 1:0] CBnorth_in,
  output logic [BUS_WIDTH - 1:0] CBnorth_out,

  //SOUTH
  // inout wire [BUS_WIDTH - 1:0] SBsouth,
  input logic [BUS_WIDTH - 1:0] SBsouth_in,
  output logic [BUS_WIDTH - 1:0] SBsouth_out,

  //EAST
  // inout wire [BUS_WIDTH - 1:0] SBeast,
  input logic [BUS_WIDTH - 1:0] CBeast_in,
  output logic [BUS_WIDTH - 1:0] CBeast_out,

  //WEST
  // inout wire [BUS_WIDTH - 1:0] SBwest
  input logic [BUS_WIDTH - 1:0] SBwest_in,
  output logic [BUS_WIDTH - 1:0] SBwest_out
);
  //internal busses
  wire [BUS_WIDTH - 1:0] bus_south, bus_west;
  logic [LE_OUTPUTS - 1:0] leout0A, leout0B, leout1A, leout1B;
  logic [LE_INPUTS - 1:0]  lein0A_CB,  lein0B_CB,  lein1A_CB,  lein1B_CB;
  logic [LE_INPUTS - 1:0]  lein0A_LEI,  lein0B_LEI,  lein1A_LEI,  lein1B_LEI;
  // logic [LE_INPUTS - 1:0]  lein0A_LEIdvn,  lein0B_LEIdvn,  lein1A_LEIdvn,  lein1B_LEIdvn;

  //internal CRAM wires
  logic le_west_cram_out, le_south_cram_out, le_north_cram_out, le_east_cram_out,
  lei_cram_out,
  cb0A_cram_out, cb0B_cram_out, 
  cb1A_cram_out, cb1B_cram_out, sb_cram_out;

  // logic [BUS_WIDTH - 1:0] SBnorth_in, SBsouth_in, SBeast_in, SBwest_in;
  logic [BUS_WIDTH - 1:0] SBnorth_in, SBeast_in, SBnorth_out, SBeast_out;

  LE #(LE_LUT_SIZE)                      LE_0A
    //CRAM signals
    (
      .config_data_in(config_data_in), .config_en(config_en), .config_data_out(le_south_cram_out), 
      .clk(clk), .nrst(nrst), 
      //configurable logic signals
      .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
      .selCB(lein0A_CB), .selLEI(lein0A_LEI), .le_out(leout0A)
    );

  LE #(LE_LUT_SIZE)                      LE_0B
    (
      //CRAM signals
      .config_data_in(le_east_cram_out), .config_en(config_en), .config_data_out(le_north_cram_out), 
      .clk(clk), .nrst(nrst), 
      //configurable logic signals
      .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
      .selCB(lein0B_CB), .selLEI(lein0B_LEI), .le_out(leout0B)
    );

  LE #(LE_LUT_SIZE)                      LE_1A
    (
      //CRAM signals
      .config_data_in(le_north_cram_out), .config_en(config_en), .config_data_out(le_west_cram_out), 
      .clk(clk), .nrst(nrst), 
      //configurable logic signals
      .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
      .selCB(lein1A_CB), .selLEI(lein1A_LEI), .le_out(leout1A)
    );

  LE #(LE_LUT_SIZE)                      LE_1B
  (
    //CRAM signals
    .config_data_in(le_south_cram_out), .config_en(config_en), .config_data_out(le_east_cram_out), 
    .clk(clk), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .selCB(lein1B_CB), .selLEI(lein1B_LEI), .le_out(leout1B)
  );

  LEI #(LE_INPUTS)                       LEI0
  (
    //CRAM signals
    .clk(clk), .nrst(nrst),
    .config_data_in(le_west_cram_out), .config_data_out(lei_cram_out), .config_en(config_en),
    //configurable logic signals
    .leout0A(leout0A), .leout0B(leout0B), .leout1A(leout1A), .leout1B(leout1B),
    .lein0A(lein0A_LEI), .lein0B(lein0B_LEI), .lein1A(lein1A_LEI), .lein1B(lein1B_LEI)
  );

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_0
    (
      //CRAM signals
      .config_data_inA(lei_cram_out), .config_en(config_en), .config_data_outA(cb0A_cram_out), //change cram chain
      .config_data_inB(cb0A_cram_out), .config_data_outB(cb0B_cram_out), 
      .clk(clk), .nrst(nrst),
      //configurable logic signals
      .sb_bus_in(SBnorth_out), .sb_bus_out(SBnorth_in),
      .cb_bus_in(CBnorth_in), .cb_bus_out(CBnorth_out),
      .le_outA(leout0A), .le_inA(lein0A_CB),
      .le_outB(leout0B), .le_inB(lein0B_CB)
    );

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_1
    (
      //CRAM signals
      .config_data_inA(cb0B_cram_out), .config_en(config_en), .config_data_outA(cb1A_cram_out), 
      .config_data_inB(cb1A_cram_out), .config_data_outB(cb1B_cram_out), 
      .clk(clk), .nrst(nrst),
      //configurable logic signals
      .sb_bus_in(SBeast_out), .sb_bus_out(SBeast_in),
      .cb_bus_in(CBeast_in), .cb_bus_out(CBeast_out),
      .le_outA(leout1A), .le_inA(lein1A_CB),
      .le_outB(leout1B), .le_inB(lein1B_CB)
    );

  SB #(BUS_WIDTH)                        SB0
    (
      //CRAM signals
      .config_data_in(cb1B_cram_out), .config_en(config_en), .config_data_out(sb_cram_out), 
      .clk(clk), .nrst(nrst),
      //configurable logic signals
      .north_in(SBnorth_in), .north_out(SBnorth_out), 
      .south_in(SBsouth_in), .south_out(SBsouth_out), 
      .east_in(SBeast_in), .east_out(SBeast_out), 
      .west_in(SBwest_in), .west_out(SBwest_out)
    );

    assign config_data_out = sb_cram_out;

endmodule
