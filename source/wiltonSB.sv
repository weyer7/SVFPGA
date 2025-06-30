`default_nettype none

module wiltonSB #(
  parameter int WIDTH = 8
)(
  inout wire [WIDTH-1:0] north,
  inout wire [WIDTH-1:0] east,
  inout wire [WIDTH-1:0] south,
  inout wire [WIDTH-1:0] west,

  input logic [WIDTH-1:0][3:0][1:0] route_sel  // [wire][input_dir][2-bit turn]
);

  // Local direction encoding
  localparam int DIR_N = 0;
  localparam int DIR_E = 1;
  localparam int DIR_S = 2;
  localparam int DIR_W = 3;

  // Each wire gets a shared bus node for bidirectional comm
  wire [WIDTH-1:0] wire_bus; //need WIDTH*2 wire busses to get full utilization of switchbox.
  // For example, if, on the same permutation (set of four wires one for each direction), I
  // want to route South to East as well as Nort to West, I would need two internal bus wires.
  // Because of this, for a full Wilton box, there should be WIDTH * 2 internal wire busses.
  // The remaining code should also reflect this fuctionality, which currently it does not
  // support.

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
      assign wire_bus[i] = 
          (route_sel[i][DIR_N] != 2'b11) ? north[i] :
          (route_sel[i][DIR_E] != 2'b11) ? east[i]  :
          (route_sel[i][DIR_S] != 2'b11) ? south[i] :
          (route_sel[i][DIR_W] != 2'b11) ? west[i]  : 1'bz;

      // Output logic
      assign north[i] = (
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_N && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_N && route_sel[i][DIR_S] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_N && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'bz;

      assign east[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_E && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_E && route_sel[i][DIR_S] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_E && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'bz;

      assign south[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_S && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_S && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_W, route_sel[i][DIR_W]) == DIR_S && route_sel[i][DIR_W] != 2'b11)
        ) ? wire_bus[i] : 1'bz;

      assign west[i] = (
          (rot_dir(DIR_N, route_sel[i][DIR_N]) == DIR_W && route_sel[i][DIR_N] != 2'b11) ||
          (rot_dir(DIR_E, route_sel[i][DIR_E]) == DIR_W && route_sel[i][DIR_E] != 2'b11) ||
          (rot_dir(DIR_S, route_sel[i][DIR_S]) == DIR_W && route_sel[i][DIR_S] != 2'b11)
        ) ? wire_bus[i] : 1'bz;
    end
  endgenerate

endmodule
