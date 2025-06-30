`default_nettype none
module LE #(
  parameter
    LUT_SIZE = 16 //number of look up table values
)(
  input logic clk, en, nrst,
  input logic le_clk, le_en, le_nrst,
  input logic [$clog2(LUT_SIZE) - 1:0] select, //select lines of the LE's LUT
  // input logic [(LUT_SIZE + 1) - 1:0] config_data, //LUT data + operation mode
  input logic config_data_in, config_en,
  output logic config_data_out,
  output logic le_out
);
// The logic element, or LE of an FPGA is what defines the FPGA's behavior.
// It contains both combinational logic in the form of a look-up table, or
// LUT, as well as a single D type flip-flop. These two elements, combined
// with configurable connectons with the switch boxes and connecton boxes,
// can form any combinational or sequential circuit so long as the FPGA
// is large enough.

//Configuration data:
//MSB [ MODE | LUT data ] LSB
logic [(LUT_SIZE + 1) - 1:0] config_data; //LUT data + operation mode
always_ff @(posedge clk, negedge nrst) begin
  if (~nrst) begin
    config_data <= 0;
  end else if (en && config_en) begin
    config_data <= {config_data[(LUT_SIZE + 1) - 2:0], config_data_in};
  end
end

assign config_data_out = config_data[(LUT_SIZE + 1) - 1];

//D type flip-flop
logic dff_out;
always_ff @(posedge le_clk, negedge le_nrst) begin
  if (!le_nrst) begin
    dff_out <= 0;
  end else if (le_en) begin
    dff_out <= mux_out;
  end else begin
    dff_out <= dff_out;
  end
end

//multiplexer
logic mux_out;
logic [LUT_SIZE - 1:0]mux_data;
assign mux_data = config_data[(LUT_SIZE + 1) - 2:0];
assign mux_out = mux_data[select];

//mode multiplexer
logic mode;
assign mode = config_data[LUT_SIZE];
assign le_out = config_en || !nrst ? 1'bz : mode ? dff_out : mux_out; //hi-z if configuring

endmodule
