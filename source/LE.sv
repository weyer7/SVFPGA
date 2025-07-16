`default_nettype none
module LE #(
  parameter
    LUT_SIZE = 16 //number of look up table values
)(
  //CRAM signals
  input logic clk, nrst,
  input logic config_data_in, config_en,
  output logic config_data_out,

  input logic le_clk, le_en, le_nrst,
  input logic [$clog2(LUT_SIZE) - 1:0] selCB, selLEI, //select lines of the LE's LUT
  output logic le_out
);
// The logic element, or LE of an FPGA is what defines the FPGA's behavior.
// It contains both combinational logic in the form of a look-up table, or
// LUT, as well as a single D type flip-flop. These two elements, combined
// with configurable connectons with the switch boxes and connecton boxes,
// can form any combinational or sequential circuit so long as the FPGA
// is large enough.

//Configuration data:
//MSB [ reset_edge | reset_val | edge_mode | reg_mode | LUT data ] LSB
logic [(LUT_SIZE + 4) - 1:0] config_data; //LUT data + operation mode
always @(posedge clk, negedge nrst) begin
  if (~nrst) begin
    config_data <= {4'b0010, 16'b0};
  end else if (config_en) begin
    config_data <= {config_data[(LUT_SIZE + 4) - 2:0], config_data_in};
  end
end

assign config_data_out = config_data[(LUT_SIZE + 4) - 1];

//D type flip-flop
(*keep*)logic dff_out; //sel Q
(*keep*)logic dff0_out; //Q reset0
(*keep*)logic dff1_out; //Q reset1
(*keep*)logic sel_clk; //selected clock
(*keep*)logic edge_mode; //clock edge sensitivity mode
(*keep*)logic reset_val; //async reset value
(*keep*)logic reset_mode; //reset edge sensitivity mode
(*keep*)logic sel_reset; //selected reset signal
always_comb begin
  edge_mode = config_data[LUT_SIZE + 1];
  reset_val = config_data[LUT_SIZE + 2];
  reset_mode = config_data[LUT_SIZE + 3];
  sel_clk = edge_mode ? le_clk : ~le_clk;
  sel_reset = reset_mode ? ~nrst : nrst;
end
// always_ff @(posedge sel_clk, negedge sel_reset) begin
always_ff @(posedge sel_clk, negedge le_nrst) begin
  if (!le_nrst) begin
    // dff_out <= reset_val;
    dff0_out <= 0;
  end else if (le_en) begin
    dff0_out <= mux_out;
  end else begin
    dff0_out <= dff0_out;
  end
end
always_ff @(posedge sel_clk, negedge le_nrst) begin
  if (!le_nrst) begin
    // dff_out <= reset_val;
    dff1_out <= 1;
  end else if (le_en) begin
    dff1_out <= mux_out;
  end else begin
    dff1_out <= dff1_out;
  end
end
assign dff_out = reset_val ? dff1_out : dff0_out;

//multiplexer
logic mux_out;
logic [LUT_SIZE - 1:0]mux_data;
logic [$clog2(LUT_SIZE) - 1:0] select;
assign mux_data = config_data[(LUT_SIZE + 1) - 2:0];
always_comb begin
  for (int i = 0; i < $clog2(LUT_SIZE); i ++) begin
    select[i] = selLEI[i] | selCB[i];
  end
end
assign mux_out = mux_data[select];

//mode multiplexer
logic mode;
assign mode = config_data[LUT_SIZE];
assign le_out = config_en || !nrst ? 1'b0 : mode ? dff_out : mux_out; //0 if configuring

endmodule
