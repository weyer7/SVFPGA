`default_nettype none
module cell16_flat #(
  parameter BUS_WIDTH = 14
)(
  // CRAM signals
  input  logic clk, nrst, config_en,
  input  logic config_data_in,
  output logic config_data_out,

  // configurable logic signals
  input  logic le_en, le_nrst,

  // NORTH (4 columns)
  input  logic [BUS_WIDTH*4-1:0] io_north_in,
  output logic [BUS_WIDTH*4-1:0] io_north_out,

  // SOUTH (4 columns)
  input  logic [BUS_WIDTH*4-1:0] io_south_in,
  output logic [BUS_WIDTH*4-1:0] io_south_out,

  // EAST (4 rows)
  input  logic [BUS_WIDTH*4-1:0] io_east_in,
  output logic [BUS_WIDTH*4-1:0] io_east_out,

  // WEST (4 rows)
  input  logic [BUS_WIDTH*4-1:0] io_west_in,
  output logic [BUS_WIDTH*4-1:0] io_west_out
);

  // Internal vertical buses (between rows)
  logic [BUS_WIDTH-1:0] bus_v_dn_to_up[0:2][0:3];
  logic [BUS_WIDTH-1:0] bus_v_up_to_dn[0:2][0:3];

  // Internal horizontal buses (between columns)
  logic [BUS_WIDTH-1:0] bus_h_lt_to_rt[0:3][0:2];
  logic [BUS_WIDTH-1:0] bus_h_rt_to_lt[0:3][0:2];

  // Config chain outputs
  logic cell_cram_out[0:15];

  //----------------------------------------
  // Row 0 (bottom row: cells 0–3)
  //----------------------------------------
  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell0 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(config_data_in), .config_data_out(cell_cram_out[0]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[0][0]), .CBnorth_out(bus_v_dn_to_up[0][0]),
    .SBsouth_in(io_south_in[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .SBsouth_out(io_south_out[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .CBeast_in(bus_h_rt_to_lt[0][0]), .CBeast_out(bus_h_lt_to_rt[0][0]),
    .SBwest_in(io_west_in[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .SBwest_out(io_west_out[BUS_WIDTH*1-1 -: BUS_WIDTH])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell1 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[0]), .config_data_out(cell_cram_out[1]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[0][1]), .CBnorth_out(bus_v_dn_to_up[0][1]),
    .SBsouth_in(io_south_in[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .SBsouth_out(io_south_out[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .CBeast_in(bus_h_rt_to_lt[0][1]), .CBeast_out(bus_h_lt_to_rt[0][1]),
    .SBwest_in(bus_h_lt_to_rt[0][0]), .SBwest_out(bus_h_rt_to_lt[0][0])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell2 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[1]), .config_data_out(cell_cram_out[2]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[0][2]), .CBnorth_out(bus_v_dn_to_up[0][2]),
    .SBsouth_in(io_south_in[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .SBsouth_out(io_south_out[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .CBeast_in(bus_h_rt_to_lt[0][2]), .CBeast_out(bus_h_lt_to_rt[0][2]),
    .SBwest_in(bus_h_lt_to_rt[0][1]), .SBwest_out(bus_h_rt_to_lt[0][1])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell3 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[2]), .config_data_out(cell_cram_out[3]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[0][3]), .CBnorth_out(bus_v_dn_to_up[0][3]),
    .SBsouth_in(io_south_in[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .SBsouth_out(io_south_out[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .CBeast_in(io_east_in[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .CBeast_out(io_east_out[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .SBwest_in(bus_h_lt_to_rt[0][2]), .SBwest_out(bus_h_rt_to_lt[0][2])
  );

  //----------------------------------------
  // Row 1 (cells 4–7)
  //----------------------------------------
  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell4 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[3]), .config_data_out(cell_cram_out[4]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[1][0]), .CBnorth_out(bus_v_dn_to_up[1][0]),
    .SBsouth_in(bus_v_dn_to_up[0][0]), .SBsouth_out(bus_v_up_to_dn[0][0]),
    .CBeast_in(bus_h_rt_to_lt[1][0]), .CBeast_out(bus_h_lt_to_rt[1][0]),
    .SBwest_in(io_west_in[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .SBwest_out(io_west_out[BUS_WIDTH*2-1 -: BUS_WIDTH])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell5 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[4]), .config_data_out(cell_cram_out[5]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[1][1]), .CBnorth_out(bus_v_dn_to_up[1][1]),
    .SBsouth_in(bus_v_dn_to_up[0][1]), .SBsouth_out(bus_v_up_to_dn[0][1]),
    .CBeast_in(bus_h_rt_to_lt[1][1]), .CBeast_out(bus_h_lt_to_rt[1][1]),
    .SBwest_in(bus_h_lt_to_rt[1][0]), .SBwest_out(bus_h_rt_to_lt[1][0])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell6 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[5]), .config_data_out(cell_cram_out[6]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[1][2]), .CBnorth_out(bus_v_dn_to_up[1][2]),
    .SBsouth_in(bus_v_dn_to_up[0][2]), .SBsouth_out(bus_v_up_to_dn[0][2]),
    .CBeast_in(bus_h_rt_to_lt[1][2]), .CBeast_out(bus_h_lt_to_rt[1][2]),
    .SBwest_in(bus_h_lt_to_rt[1][1]), .SBwest_out(bus_h_rt_to_lt[1][1])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell7 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[6]), .config_data_out(cell_cram_out[7]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[1][3]), .CBnorth_out(bus_v_dn_to_up[1][3]),
    .SBsouth_in(bus_v_dn_to_up[0][3]), .SBsouth_out(bus_v_up_to_dn[0][3]),
    .CBeast_in(io_east_in[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .CBeast_out(io_east_out[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .SBwest_in(bus_h_lt_to_rt[1][2]), .SBwest_out(bus_h_rt_to_lt[1][2])
  );

  //----------------------------------------
  // Row 2 (cells 8–11)
  //----------------------------------------
  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell8 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[7]), .config_data_out(cell_cram_out[8]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[2][0]), .CBnorth_out(bus_v_dn_to_up[2][0]),
    .SBsouth_in(bus_v_dn_to_up[1][0]), .SBsouth_out(bus_v_up_to_dn[1][0]),
    .CBeast_in(bus_h_rt_to_lt[2][0]), .CBeast_out(bus_h_lt_to_rt[2][0]),
    .SBwest_in(io_west_in[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .SBwest_out(io_west_out[BUS_WIDTH*3-1 -: BUS_WIDTH])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell9 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[8]), .config_data_out(cell_cram_out[9]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[2][1]), .CBnorth_out(bus_v_dn_to_up[2][1]),
    .SBsouth_in(bus_v_dn_to_up[1][1]), .SBsouth_out(bus_v_up_to_dn[1][1]),
    .CBeast_in(bus_h_rt_to_lt[2][1]), .CBeast_out(bus_h_lt_to_rt[2][1]),
    .SBwest_in(bus_h_lt_to_rt[2][0]), .SBwest_out(bus_h_rt_to_lt[2][0])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell10 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[9]), .config_data_out(cell_cram_out[10]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[2][2]), .CBnorth_out(bus_v_dn_to_up[2][2]),
    .SBsouth_in(bus_v_dn_to_up[1][2]), .SBsouth_out(bus_v_up_to_dn[1][2]),
    .CBeast_in(bus_h_rt_to_lt[2][2]), .CBeast_out(bus_h_lt_to_rt[2][2]),
    .SBwest_in(bus_h_lt_to_rt[2][1]), .SBwest_out(bus_h_rt_to_lt[2][1])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell11 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[10]), .config_data_out(cell_cram_out[11]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(bus_v_up_to_dn[2][3]), .CBnorth_out(bus_v_dn_to_up[2][3]),
    .SBsouth_in(bus_v_dn_to_up[1][3]), .SBsouth_out(bus_v_up_to_dn[1][3]),
    .CBeast_in(io_east_in[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .CBeast_out(io_east_out[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .SBwest_in(bus_h_lt_to_rt[2][2]), .SBwest_out(bus_h_rt_to_lt[2][2])
  );

  //----------------------------------------
  // Row 3 (top row: cells 12–15)
  //----------------------------------------
  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell12 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[11]), .config_data_out(cell_cram_out[12]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(io_north_in[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .CBnorth_out(io_north_out[BUS_WIDTH*1-1 -: BUS_WIDTH]),
    .SBsouth_in(bus_v_dn_to_up[2][0]), .SBsouth_out(bus_v_up_to_dn[2][0]),
    .CBeast_in(bus_h_rt_to_lt[3][0]), .CBeast_out(bus_h_lt_to_rt[3][0]),
    .SBwest_in(io_west_in[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .SBwest_out(io_west_out[BUS_WIDTH*4-1 -: BUS_WIDTH])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell13 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[12]), .config_data_out(cell_cram_out[13]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(io_north_in[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .CBnorth_out(io_north_out[BUS_WIDTH*2-1 -: BUS_WIDTH]),
    .SBsouth_in(bus_v_dn_to_up[2][1]), .SBsouth_out(bus_v_up_to_dn[2][1]),
    .CBeast_in(bus_h_rt_to_lt[3][1]), .CBeast_out(bus_h_lt_to_rt[3][1]),
    .SBwest_in(bus_h_lt_to_rt[3][0]), .SBwest_out(bus_h_rt_to_lt[3][0])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell14 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[13]), .config_data_out(cell_cram_out[14]),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(io_north_in[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .CBnorth_out(io_north_out[BUS_WIDTH*3-1 -: BUS_WIDTH]),
    .SBsouth_in(bus_v_dn_to_up[2][2]), .SBsouth_out(bus_v_up_to_dn[2][2]),
    .CBeast_in(bus_h_rt_to_lt[3][2]), .CBeast_out(bus_h_lt_to_rt[3][2]),
    .SBwest_in(bus_h_lt_to_rt[3][1]), .SBwest_out(bus_h_rt_to_lt[3][1])
  );

  fpgacell #(.BUS_WIDTH(BUS_WIDTH)) cell15 (
    .clk(clk), .nrst(nrst), .config_en(config_en),
    .config_data_in(cell_cram_out[14]), .config_data_out(config_data_out),
    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),
    .CBnorth_in(io_north_in[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .CBnorth_out(io_north_out[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .SBsouth_in(bus_v_dn_to_up[2][3]), .SBsouth_out(bus_v_up_to_dn[2][3]),
    .CBeast_in(io_east_in[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .CBeast_out(io_east_out[BUS_WIDTH*4-1 -: BUS_WIDTH]),
    .SBwest_in(bus_h_lt_to_rt[3][2]), .SBwest_out(bus_h_rt_to_lt[3][2])
  );

endmodule
