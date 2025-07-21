`default_nettype none

module SB #(
  parameter int WIDTH = 32
)(
  // inout wire [WIDTH-1:0] north,
  // inout wire [WIDTH-1:0] east,
  // inout wire [WIDTH-1:0] south,
  // inout wire [WIDTH-1:0] west,

  //removed tristate
  input wire [WIDTH - 1:0] north_in,
  output wire [WIDTH - 1:0] north_out,

  input wire [WIDTH - 1:0] east_in,
  output wire [WIDTH - 1:0] east_out,

  input wire [WIDTH - 1:0] south_in,
  output wire [WIDTH - 1:0] south_out,

  input wire [WIDTH - 1:0] west_in,
  output wire [WIDTH - 1:0] west_out,

  // input logic [WIDTH-1:0][3:0][1:0] route_sel  // [wire][input_dir][2-bit turn]
  input logic clk, nrst,
  input logic config_data_in, config_en,
  output logic config_data_out
);

  localparam CFG_BITS = WIDTH * 4 * 2;
  logic [CFG_BITS - 1:0] route_sel_flat;
  logic [WIDTH-1:0][3:0][1:0] route_sel; // [wire][input_dir][2-bit turn]
  
  assign route_sel = route_sel_flat;

  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      route_sel_flat <= {CFG_BITS{'1}}; //make sure this is good
    end else if (config_en) begin
      route_sel_flat <= {route_sel_flat[WIDTH * 4 * 2 - 2:0], config_data_in};
    end
  end

  assign config_data_out = route_sel_flat[WIDTH * 4 * 2 - 1];

  // Local direction encoding. could also use typedef...
  localparam int DIR_N = 0;
  localparam int DIR_E = 1;
  localparam int DIR_S = 2;
  localparam int DIR_W = 3;

  // Each wire gets a shared bus node for bidirectional comm
  wire [WIDTH-1:0] wire_bus; //need WIDTH*2 wires to get full utilization of switchbox
  // For example, what if on the same permutation net, I want north to drive west and east to drive south.
  // This isn't possible with the current code because only one signal can drive each permuation.

  // Helper function to rotate direction
  function automatic int rot_dir(input int from_dir, input logic [1:0] turn);
    case (turn)
      2'b00: rot_dir = (from_dir + 3) % 4; // Left
      2'b01: rot_dir = (from_dir + 2) % 4; // Straight
      2'b10: rot_dir = (from_dir + 1) % 4; // Right
      default: rot_dir = -1;              // Disabled
    endcase
  endfunction

  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : wire_loop

      // Determine who is driving the bus. Priority logic avoids contention
      assign wire_bus[i] = config_en ? 1'b0 :
          (route_sel[i][DIR_N] != 2'b11) ? north_in[i] :
          (route_sel[i][DIR_E] != 2'b11) ? east_in[i]  :
          (route_sel[i][DIR_S] != 2'b11) ? south_in[i] :
          (route_sel[i][DIR_W] != 2'b11) ? west_in[i]  : 1'b0;

      // Output logic with updated 2'b11 handling (connects to wire_bus instead of disconnecting)
      assign north_out[i] = (
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_N && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_N && route_sel[i][DIR_S] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_N && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'b0;
      
      assign east_out[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_E && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_E && route_sel[i][DIR_S] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_E && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'b0;
      
      assign south_out[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_S && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_S && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_S && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'b0;
      
      assign west_out[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_W && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_W && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_W && route_sel[i][DIR_S] != 2'b11)
        ) ? wire_bus[i] : 1'b0;
      
    end
  endgenerate

endmodule
