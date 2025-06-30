`default_nettype none
module fpga #(
  parameter int CELL_COUNT  = 64,
  parameter int IO_COUNT    = 128,

  parameter int LE_LUT_SIZE = 16,
  parameter int LE_INPUTS   = 4,
  parameter int LE_OUTPUTS  = 1,

  parameter int BUS_WIDTH   = 8
)(
  // CRAM signals
  input  logic clk, en, nrst,
  input  logic config_data, config_en,

  // Top-level bidirectional IOs
  inout  tri [IO_COUNT-1:0] io,

  // Other FPGA signals
  input logic le_clk, le_en, le_nrst
);

  localparam int GRID_DIM  = $clog2(CELL_COUNT);
  localparam int CELL_ROWS = 1 << (GRID_DIM/2);
  localparam int CELL_COLS = CELL_COUNT / CELL_ROWS;
  localparam int IO_QUART  = IO_COUNT / 4;

  // Combined shift register for IO config (direction + output values)
  logic [2*IO_COUNT-1:0] io_config_chain;
  wire  [IO_COUNT-1:0] io_direction_bits = io_config_chain[2*IO_COUNT-1 -: IO_COUNT];
  wire  [IO_COUNT-1:0] io_data_out_bits  = io_config_chain[IO_COUNT-1:0];

  logic [CELL_COUNT:0] config_chain;
  assign config_chain[0] = io_config_chain[2 * IO_COUNT - 2]; // Config chain connected to end of IO config

  // Shift register for IO configuration
  always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
      io_config_chain <= '0;
    else if (en && config_en) // Ensures configuration can't happen unless config_en is high
      io_config_chain <= {io_config_chain[2*IO_COUNT-2:0], config_data};
  end

  // Flattened packed buses across all cells
  logic [BUS_WIDTH*CELL_COUNT-1:0] north_bus_flat;
  logic [BUS_WIDTH*CELL_COUNT-1:0] south_bus_flat;
  logic [BUS_WIDTH*CELL_COUNT-1:0] east_bus_flat;
  logic [BUS_WIDTH*CELL_COUNT-1:0] west_bus_flat;

  logic [LE_OUTPUTS*CELL_COUNT-1:0] leout_north_flat;
  logic [LE_OUTPUTS*CELL_COUNT-1:0] leout_east_flat;

  // Provide zero constants for unused LE inputs/CB outputs
  logic [LE_INPUTS-1:0] zero_lein = '0;
  logic [LE_OUTPUTS-1:0] zero_leout = '0;

  // Tiling cells in a 2D grid with directional interconnects
  genvar row, col;
  generate
    for (row = 0; row < CELL_ROWS; row++) begin: row_gen
      for (col = 0; col < CELL_COLS; col++) begin: col_gen
        localparam int idx       = row * CELL_COLS + col;
        localparam int NB_OFF    = idx * BUS_WIDTH;
        localparam int SB_OFF    = idx * BUS_WIDTH;
        localparam int EB_OFF    = idx * BUS_WIDTH;
        localparam int WB_OFF    = idx * BUS_WIDTH;
        localparam int LN_OFF    = idx * LE_OUTPUTS;
        localparam int LE_OFF    = idx * LE_OUTPUTS;

        wire [LE_OUTPUTS-1:0] cbinsouth;
        if ((row + 1) < CELL_ROWS) begin : safe_cbinsouth
          assign cbinsouth = leout_north_flat[(idx + CELL_COLS)*LE_OUTPUTS +: LE_OUTPUTS];
        end else begin : zero_cbinsouth
          assign cbinsouth = '0;
        end

        wire [LE_OUTPUTS-1:0] cbinwest =
          (col > 0)
            ? leout_east_flat[(idx - 1)*LE_OUTPUTS +: LE_OUTPUTS]
            : '0;

        fpgacell #(
          .LE_LUT_SIZE(LE_LUT_SIZE),
          .LE_INPUTS(LE_INPUTS),
          .LE_OUTPUTS(LE_OUTPUTS),
          .BUS_WIDTH(BUS_WIDTH)
        ) cell_inst (
          // CRAM chain
          .clk(clk), .en(en), .nrst(nrst),
          .config_data_in(config_chain[idx]), .config_en(config_en),
          .config_data_out(config_chain[idx+1]),

          // Configurable logic signals
          .le_clk(le_clk), .le_en(le_en), .le_nrst(le_nrst),

          // NORTH connections
          .CBnorth(north_bus_flat[NB_OFF +: BUS_WIDTH]),
          .LEoutnorth(leout_north_flat[LN_OFF +: LE_OUTPUTS]),
          .LEinnorth({LE_INPUTS{1'b0}}),

          // SOUTH connections
          .SBsouth(south_bus_flat[SB_OFF +: BUS_WIDTH]),
          .CBoutsouth(),
          .CBinsouth(cbinsouth),

          // EAST connections
          .CBeast(east_bus_flat[EB_OFF +: BUS_WIDTH]),
          .LEouteast(leout_east_flat[LE_OFF +: LE_OUTPUTS]),
          .LEineast({LE_INPUTS{1'b0}}),

          // WEST connections
          .SBwest(west_bus_flat[WB_OFF +: BUS_WIDTH]),
          .CBoutwest(),
          .CBinwest(cbinwest)
        );
      end
    end
  endgenerate

  // ----------------------------
  // IO <-> Edge switchbox wiring with CRAM-configured direction
  // ----------------------------
  for (genvar i = 0; i < CELL_COLS; i++) begin : north_io_map
    if (i*BUS_WIDTH + BUS_WIDTH <= IO_QUART) begin
      for (genvar b = 0; b < BUS_WIDTH; b++) begin
        wire direction = io_direction_bits[i*BUS_WIDTH + b];
        wire dout = io_data_out_bits[i*BUS_WIDTH + b];
        assign io[i*BUS_WIDTH + b] = direction ? dout : 1'bz;
        assign north_bus_flat[i*BUS_WIDTH + b] = io[i*BUS_WIDTH + b];
      end
    end
  end

  for (genvar i = 0; i < CELL_COLS; i++) begin : south_io_map
    if ((IO_QUART + i*BUS_WIDTH + BUS_WIDTH) <= IO_COUNT/2) begin
      for (genvar b = 0; b < BUS_WIDTH; b++) begin
        wire direction = io_direction_bits[IO_QUART + i*BUS_WIDTH + b];
        wire dout = io_data_out_bits[IO_QUART + i*BUS_WIDTH + b];
        assign io[IO_QUART + i*BUS_WIDTH + b] = direction ? dout : 1'bz;
        assign south_bus_flat[i*BUS_WIDTH + b] = io[IO_QUART + i*BUS_WIDTH + b];
      end
    end
  end

  for (genvar i = 0; i < CELL_ROWS; i++) begin : west_io_map
    if ((2*IO_QUART + i*BUS_WIDTH + BUS_WIDTH) <= 3*IO_QUART) begin
      for (genvar b = 0; b < BUS_WIDTH; b++) begin
        wire direction = io_direction_bits[2*IO_QUART + i*BUS_WIDTH + b];
        wire dout = io_data_out_bits[2*IO_QUART + i*BUS_WIDTH + b];
        assign io[2*IO_QUART + i*BUS_WIDTH + b] = direction ? dout : 1'bz;
        assign west_bus_flat[i*BUS_WIDTH + b] = io[2*IO_QUART + i*BUS_WIDTH + b];
      end
    end
  end

  for (genvar i = 0; i < CELL_ROWS; i++) begin : east_io_map
    if ((3*IO_QUART + i*BUS_WIDTH + BUS_WIDTH) <= IO_COUNT) begin
      for (genvar b = 0; b < BUS_WIDTH; b++) begin
        wire direction = io_direction_bits[3*IO_QUART + i*BUS_WIDTH + b];
        wire dout = io_data_out_bits[3*IO_QUART + i*BUS_WIDTH + b];
        assign io[3*IO_QUART + i*BUS_WIDTH + b] = direction ? dout : 1'bz;
        assign east_bus_flat[i*BUS_WIDTH + b] = io[3*IO_QUART + i*BUS_WIDTH + b];
      end
    end
  end

endmodule
