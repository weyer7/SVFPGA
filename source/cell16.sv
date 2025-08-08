`default_nettype none
module cell16 #(
  parameter
    BUS_WIDTH = 14
)(
  //CRAM signals
  input logic clk, nrst, config_en,
  input logic config_data_in,
  output logic config_data_out,

  //configurable logic signals
  input logic /*le_clk,*/ 
  le_en, le_nrst,
  //NORTH
  input logic [BUS_WIDTH * 4 - 1:0] io_north_in,
  output logic [BUS_WIDTH * 4 - 1:0] io_north_out,
  
  //SOUTH
  input logic [BUS_WIDTH * 4 - 1:0] io_south_in,
  output logic [BUS_WIDTH * 4 - 1:0] io_south_out,
  
  //EAST
  input logic [BUS_WIDTH * 4 - 1:0] io_east_in,
  output logic [BUS_WIDTH * 4 - 1:0] io_east_out,
  
  //WEST
  input logic [BUS_WIDTH * 4 - 1:0] io_west_in,
  output logic [BUS_WIDTH * 4 - 1:0] io_west_out
);

  //intercell internal busses
  logic [BUS_WIDTH * 2 - 1:0] bus0_1, bus0_2, bus1_0, bus1_3, bus2_0, bus2_3, bus3_1, bus3_2;
  logic block0_cram_out, block1_cram_out, block2_cram_out;

  //output assignments
  logic [BUS_WIDTH * 2 - 1:0] north0_out, north1_out,
  south0_out, south1_out, east0_out, east1_out,
  west0_out, west1_out;
  assign io_north_out = {north1_out, north0_out};
  assign io_south_out = {south1_out, south0_out};
  assign io_east_out = {east1_out, east0_out};
  assign io_west_out = {west1_out, west0_out};

  cell4 #(.BUS_WIDTH(BUS_WIDTH)) block0 
  (
    //CRAM signals
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(config_data_in), .config_data_out(block0_cram_out),
    //configurable logic signals
    .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .io_north_in(bus2_0), .io_north_out(bus0_2),
    .io_south_in(io_south_in[BUS_WIDTH * 2 - 1:0]), .io_south_out(south0_out), //top level IO
    .io_east_in(bus1_0), .io_east_out(bus0_1),
    .io_west_in(io_west_in[BUS_WIDTH * 2 - 1:0]), .io_west_out(west0_out) //top level IO
  );

  cell4 #(.BUS_WIDTH(BUS_WIDTH)) block1
  (
    //CRAM signals
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(block0_cram_out), .config_data_out(block1_cram_out),
    //configurable logic signals
    .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .io_north_in(bus3_1), .io_north_out(bus1_3),
    .io_south_in(io_south_in[BUS_WIDTH * 4 - 1:BUS_WIDTH * 2]), .io_south_out(south1_out), //top level IO
    .io_east_in(io_east_in[BUS_WIDTH * 2 - 1:0]), .io_east_out(east0_out), //top level IO
    .io_west_in(bus0_1), .io_west_out(bus1_0)
  );

  cell4 #(.BUS_WIDTH(BUS_WIDTH)) block2
  (
    //CRAM signals
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(block1_cram_out), .config_data_out(block2_cram_out),
    //configurable logic signals
    .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .io_north_in(io_north_in[BUS_WIDTH * 2 - 1:0]), .io_north_out(north0_out), //top level IO
    .io_south_in(bus0_2), .io_south_out(bus2_0),
    .io_east_in(bus3_2), .io_east_out(bus2_3),
    .io_west_in(io_west_in[BUS_WIDTH * 4 - 1:BUS_WIDTH * 2]), .io_west_out(west1_out) //top level IO
  );

  cell4 #(.BUS_WIDTH(BUS_WIDTH)) block3
  (
    //CRAM signals
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(block2_cram_out), .config_data_out(config_data_out),
    //configurable logic signals
    .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .io_north_in(io_north_in[BUS_WIDTH * 4 - 1:BUS_WIDTH * 2]), .io_north_out(north1_out), //top level IO
    .io_south_in(bus1_3), .io_south_out(bus3_1), 
    .io_east_in(io_east_in[BUS_WIDTH * 4 - 1:BUS_WIDTH * 2]), .io_east_out(east1_out), //top level IO
    .io_west_in(bus2_3), .io_west_out(bus3_2)
  );
endmodule