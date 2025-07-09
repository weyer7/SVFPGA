`default_nettype none
module fpgacell #(
  parameter
    LE_LUT_SIZE = 16,
    LE_INPUTS = 4,
    LE_OUTPUTS = 1,
    BUS_WIDTH = 16
)(
  //CRAM signals
  input logic clk, en, nrst,
  input logic config_data_in, config_en,
  output logic config_data_out,

  //Configurable logic signals
  input logic le_clk, le_en, le_nrst,

  //NORTH
  // inout wire [BUS_WIDTH - 1:0] SBnorth,
  // input logic [BUS_WIDTH - 1:0] SBnorth_in,
  output logic [BUS_WIDTH - 1:0] SBnorth_out,

  //SOUTH
  // inout wire [BUS_WIDTH - 1:0] SBsouth,
  input logic [BUS_WIDTH - 1:0] SBsouth_in,
  output logic [BUS_WIDTH - 1:0] SBsouth_out,

  //EAST
  // inout wire [BUS_WIDTH - 1:0] SBeast,
  // input logic [BUS_WIDTH - 1:0] SBeast_in,
  output logic [BUS_WIDTH - 1:0] SBeast_out,

  //WEST
  // inout wire [BUS_WIDTH - 1:0] SBwest
  input logic [BUS_WIDTH - 1:0] SBwest_in,
  output logic [BUS_WIDTH - 1:0] SBwest_out
);
  //internal busses
  wire [BUS_WIDTH - 1:0] bus_south, bus_west;
  logic [LE_OUTPUTS - 1:0] leout0A, leout0B, leout1A, leout1B;
  logic [LE_INPUTS - 1:0]  lein0A,  lein0B,  lein1A,  lein1B;
  //internal CRAM wires
  logic le_west_cram_out, le_south_cram_out, le_north_cram_out, le_east_cram_out,
  cb0A_cram_out, cb0B_cram_out, 
  cb1A_cram_out, cb1B_cram_out, sb_cram_out;

  // assign LEouteast = leout_east;
  // assign LEoutnorth = leout_north;

  // logic [BUS_WIDTH - 1:0] SBnorth_in, SBsouth_in, SBeast_in, SBwest_in;
  logic [BUS_WIDTH - 1:0] SBnorth_in, SBeast_in;

  LE #(LE_LUT_SIZE)                      LE_0A
    //CRAM signals
    (.config_data_in(config_data_in), .config_en(config_en), .config_data_out(le_south_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein0A), .le_out(leout0A));

  LE #(LE_LUT_SIZE)                      LE_0B
    //CRAM signals
    (.config_data_in(le_east_cram_out), .config_en(config_en), .config_data_out(le_north_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein0B), .le_out(leout0B));

  LE #(LE_LUT_SIZE)                      LE_1A
    //CRAM signals
    (.config_data_in(le_north_cram_out), .config_en(config_en), .config_data_out(le_west_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein1A), .le_out(leout1A));

  LE #(LE_LUT_SIZE)                      LE_1B
  //CRAM signals
  (.config_data_in(le_south_cram_out), .config_en(config_en), .config_data_out(le_east_cram_out), 
  .clk(clk), .en(en), .nrst(nrst), 
  //configurable logic signals
  .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
  .select(lein1B), .le_out(leout1B));

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_0
    //CRAM signals
    (.config_data_inA(le_west_cram_out), .config_en(config_en), .config_data_outA(cb0A_cram_out), //change cram chain
    .config_data_inB(cb0A_cram_out), .config_data_outB(cb0B_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .sb_bus_in(SBnorth_out), .sb_bus_out(SBnorth_in), .le_outA(leout0A), .le_inA(lein0A),
    .le_outB(leout0B), .le_inB(lein0B));

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_1
    //CRAM signals
    (.config_data_inA(cb0B_cram_out), .config_en(config_en), .config_data_outA(cb1A_cram_out), 
    .config_data_inB(cb1A_cram_out), .config_data_outB(cb1B_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .sb_bus_in(SBeast_out), .sb_bus_out(SBeast_in), .le_outA(leout1A), .le_inA(lein1A),
    .le_outB(leout1B), .le_inB(lein1B));

  SB #(BUS_WIDTH)                        SB0
    //CRAM signals
    (.config_data_in(cb1B_cram_out), .config_en(config_en), .config_data_out(sb_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .north_in(SBnorth_in), .north_out(SBnorth_out), .south_in(SBsouth_in), .south_out(SBsouth_out), .east_in(SBeast_in), .east_out(SBeast_out), .west_in(SBwest_in), .west_out(SBwest_out));

    assign config_data_out = sb_cram_out;

endmodule
