`default_nettype none
module fpga #(
  parameter
    BUS_WIDTH = 16
)(
  //CRAM signals
  input logic clk, en, nrst, config_en,
  input logic config_data_in,
  output logic config_data_out,

  //configurable logic signals
  input logic le_clk, le_en, le_nrst,
  //NORTH
  input logic [BUS_WIDTH * 2 - 1:0] io_north_in,
  output logic [BUS_WIDTH * 2 - 1:0] io_north_out,
  
  //SOUTH
  input logic [BUS_WIDTH * 2 - 1:0] io_south_in,
  output logic [BUS_WIDTH * 2 - 1:0] io_south_out,
  
  //EAST
  input logic [BUS_WIDTH * 2 - 1:0] io_east_in,
  output logic [BUS_WIDTH * 2 - 1:0] io_east_out,
  
  //WEST
  input logic [BUS_WIDTH * 2 - 1:0] io_west_in,
  output logic [BUS_WIDTH * 2 - 1:0] io_west_out
);

  //intercell internal busses
  logic [BUS_WIDTH - 1:0] bus0_1, bus0_2, bus1_0, bus1_3, bus2_0, bus2_3, bus3_1, bus3_2;
  logic cell0_cram_out, cell1_cram_out, cell2_cram_out;

  //output assignments
  logic [BUS_WIDTH-1:0] north0_out, north1_out,
  south0_out, south1_out, east0_out, east1_out,
  west0_out, west1_out;
  assign io_north_out = {north1_out, north0_out};
  assign io_south_out = {south1_out, south0_out};
  assign io_east_out = {east1_out, east0_out};
  assign io_west_out = {west1_out, west0_out};

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell0 
  (
    //CRAM signals
    .clk(clk), .en(en), .nrst(nrst), .config_en(config_en),
    .config_data_in(config_data_in), .config_data_out(cell0_cram_out),
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .CBnorth_in(bus2_0), .CBnorth_out(bus0_2),
    .SBsouth_in(io_south_in[BUS_WIDTH - 1:0]), .SBsouth_out(south0_out), //top level IO
    .CBeast_in(bus1_0), .CBeast_out(bus0_1),
    .SBwest_in(io_west_in[BUS_WIDTH - 1:0]), .SBwest_out(west0_out) //top level IO
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell1
  (
    //CRAM signals
    .clk(clk), .en(en), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell0_cram_out), .config_data_out(cell1_cram_out),
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .CBnorth_in(bus3_1), .CBnorth_out(bus1_3),
    .SBsouth_in(io_south_in[BUS_WIDTH * 2 - 1:BUS_WIDTH]), .SBsouth_out(south1_out), //top level IO
    .CBeast_in(io_east_in[BUS_WIDTH - 1:0]), .CBeast_out(east0_out), //top level IO
    .SBwest_in(bus0_1), .SBwest_out(bus1_0)
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell2
  (
    //CRAM signals
    .clk(clk), .en(en), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell1_cram_out), .config_data_out(cell2_cram_out),
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .CBnorth_in(io_north_in[BUS_WIDTH - 1:0]), .CBnorth_out(north0_out), //top level IO
    .SBsouth_in(bus0_2), .SBsouth_out(bus2_0),
    .CBeast_in(bus3_2), .CBeast_out(bus2_3),
    .SBwest_in(io_west_in[BUS_WIDTH * 2 - 1:BUS_WIDTH]), .SBwest_out(west1_out) //top level IO
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell3
  (
    //CRAM signals
    .clk(clk), .en(en), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell2_cram_out), .config_data_out(config_data_out),
    //configurable logic signals
    .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),

    //NORTH
    .CBnorth_in(io_north_in[BUS_WIDTH * 2 - 1:BUS_WIDTH]), .CBnorth_out(north1_out), //top level IO
    .SBsouth_in(bus1_3), .SBsouth_out(bus3_1), 
    .CBeast_in(io_east_in[BUS_WIDTH * 2 - 1:BUS_WIDTH]), .CBeast_out(east1_out), //top level IO
    .SBwest_in(bus2_3), .SBwest_out(bus3_2)
  );
endmodule