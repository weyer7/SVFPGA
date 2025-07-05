`default_nettype none
module fpgacell #(
  parameter
    LE_LUT_SIZE = 16,
    LE_INPUTS = 4,
    LE_OUTPUTS = 1,
    BUS_WIDTH = 8
)(
  //CRAM signals
  input logic clk, en, nrst,
  input logic config_data_in, config_en,
  output logic config_data_out,

  //Configurable logic signals
  input logic le_clk, le_en, le_nrst,

  //NORTH
  inout wire [BUS_WIDTH - 1:0] CBnorth,
  // output logic [LE_OUTPUTS - 1:0] LEoutnorth,
  // input logic [LE_INPUTS - 1:0] LEinnorth,

  //SOUTH
  inout wire [BUS_WIDTH - 1:0] SBsouth,
  // output logic [LE_INPUTS - 1:0] CBoutsouth,
  // input logic [LE_OUTPUTS - 1:0] CBinsouth,

  //EAST
  inout wire [BUS_WIDTH - 1:0] CBeast,
  // output logic [LE_OUTPUTS - 1:0] LEouteast,
  // input logic [LE_INPUTS - 1:0] LEineast,

  //WEST
  inout wire [BUS_WIDTH - 1:0] SBwest
  // output logic [LE_INPUTS - 1:0] CBoutwest,
  // input logic [LE_OUTPUTS - 1:0] CBinwest
);
  //internal busses
  wire [BUS_WIDTH - 1:0] bus_south, bus_west;
  logic [LE_OUTPUTS - 1:0] leout_west, leout_south, leout_north, leout_east;
  logic [LE_INPUTS - 1:0] lein_west, lein_south, lein_north, lein_east;
  //internal CRAM wires
  logic le_west_cram_out, le_south_cram_out, le_north_cram_out, le_east_cram_out,
  cb0A_cram_out, cb0B_cram_out, 
  cb1A_cram_out, cb1B_cram_out, sb_cram_out;

  // assign LEouteast = leout_east;
  // assign LEoutnorth = leout_north;

  LE #(LE_LUT_SIZE)                      LE_northeast_south
    //CRAM signals
    (.config_data_in(config_data_in), .config_en(config_en), .config_data_out(le_south_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein_south), .le_out(leout_south));

  LE #(LE_LUT_SIZE)                      LE_northeast_east
  //CRAM signals
  (.config_data_in(le_south_cram_out), .config_en(config_en), .config_data_out(le_east_cram_out), 
  .clk(clk), .en(en), .nrst(nrst), 
  //configurable logic signals
  .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
  .select(lein_east), .le_out(leout_east));

  LE #(LE_LUT_SIZE)                      LE_northeast_north
    //CRAM signals
    (.config_data_in(le_east_cram_out), .config_en(config_en), .config_data_out(le_north_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein_north), .le_out(leout_north));

  LE #(LE_LUT_SIZE)                      LE_northeast_west
    //CRAM signals
    (.config_data_in(le_north_cram_out), .config_en(config_en), .config_data_out(le_west_cram_out), 
    .clk(clk), .en(en), .nrst(nrst), 
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),
    .select(lein_west), .le_out(leout_west));

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_northwest 
    //CRAM signals
    (.config_data_inA(le_west_cram_out), .config_en(config_en), .config_data_outA(cb0A_cram_out), //change cram chain
    .config_data_inB(cb0A_cram_out), .config_data_outB(cb0B_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .sb_busA(bus_west), .le_outA(leout_south), .le_inA(lein_south),
    .sb_busB(CBnorth), .le_outB(leout_north), .le_inB(lein_north));

  CB #(BUS_WIDTH, LE_OUTPUTS, LE_INPUTS) CB_southeast 
    //CRAM signals
    (.config_data_inA(cb0B_cram_out), .config_en(config_en), .config_data_outA(cb1A_cram_out), 
    .config_data_inB(cb1A_cram_out), .config_data_outB(cb1B_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .sb_busA(bus_south), .le_outA(leout_west), .le_inA(lein_west),
    .sb_busB(CBeast), .le_outB(leout_east), .le_inB(lein_east));

  SB #(BUS_WIDTH)                        SB_southwest 
    //CRAM signals
    (.config_data_in(cb1B_cram_out), .config_en(config_en), .config_data_out(sb_cram_out), 
    .clk(clk), .en(en), .nrst(nrst),
    //configurable logic signals
    .north(bus_west), .south(SBsouth), .east(bus_south), .west(SBwest));

    assign config_data_out = sb_cram_out;

endmodule
