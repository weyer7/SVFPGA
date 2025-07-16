`default_nettype none
module CB #(
  parameter WIDTH = 32,
  parameter LE_OUTPUTS = 1,
  parameter LE_INPUTS = 4
)(
  //CRAM signals
  input logic clk, nrst,
  input logic config_en,
  input logic config_data_inA, config_data_inB,
  output logic config_data_outA, config_data_outB,

  //configurable logic signals
  // inout wire [WIDTH-1:0] sb_bus, //switchbox bus
  input logic [WIDTH - 1:0] sb_bus_in, 
  output logic [WIDTH - 1:0] sb_bus_out, //switch to discreet inputs and outputs

  input logic [WIDTH - 1:0] cb_bus_in,
  output logic [WIDTH - 1:0] cb_bus_out,

  input logic [LE_OUTPUTS - 1:0] le_outA, le_outB,
  output logic [LE_INPUTS - 1:0] le_inA, le_inB
);
  // The connection box (CB) of an FPGA connects each Logic Element (LE)
  // to a switch box (SB) bus. It can also tie LE inputs to a constant 
  // 1 or 0 depending on its configuration data. There are 2 LEs and
  // 2 SBs connected to each CB.

  // dual bank configuration data shift register
  logic [($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 1:0] config_dataA; //# of mux = # of LE I/O. log2(width * 2 + 2) for each mux's select
  logic [($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 1:0] config_dataB;
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      config_dataA <= '1; //check if this is correct
      config_dataB <= '1; //check if this is correct
    end else if (config_en) begin
      config_dataA <= {config_dataA[($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 2:0], config_data_inA};
      config_dataB <= {config_dataB[($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 2:0], config_data_inB};
    end
  end
  assign config_data_outA = config_dataA[($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 1];
  assign config_data_outB = config_dataB[($clog2(WIDTH + 2)) * (LE_INPUTS + LE_OUTPUTS) - 1];

  localparam int SEL_BITS = $clog2(WIDTH + 2);
  localparam int TOTAL_MUX = LE_INPUTS + LE_OUTPUTS;
  localparam int CONST_0 = WIDTH;
  localparam int CONST_1 = WIDTH + 1;

  logic [SEL_BITS-1:0] config_mux_selA [0:TOTAL_MUX-1], config_mux_selB [0:TOTAL_MUX-1];
  logic [LE_OUTPUTS * 2 - 1:0] le_out;
  // logic [LE_INPUTS * 2 - 1:0] le_sel;

  genvar i;
  generate
    for (i = 0; i < TOTAL_MUX; i++) begin : unpack_cfg
      assign config_mux_selA[i] = config_dataA[(i+1)*SEL_BITS-1 -: SEL_BITS];
      assign config_mux_selB[i] = config_dataB[(i+1)*SEL_BITS-1 -: SEL_BITS];
    end
  endgenerate

  generate
    for (genvar i = 0; i < LE_OUTPUTS; i++) begin
      assign le_out[2*i]     = le_outA[i];
      assign le_out[2*i + 1] = le_outB[i];
    end
  endgenerate
  // logic [WIDTH * 2 - 1:0] sb_bus1;
  // logic [WIDTH * 2 - 1:0] sb_bus2;
  // assign sb_bus1 = {sb_busB, sb_busA};
  // assign {sb_busB, sb_busA} = sb_bus2;
  // logic [LE_INPUTS-1:0] le_inA, le_inB;
  generate
    for (i = 0; i < LE_INPUTS; i++) begin : input_mux
      always_comb begin
        if (config_mux_selA[i] == SEL_BITS'(CONST_0)) begin
          le_inA[i] = 1'b0;
        end else if (config_mux_selA[i] == SEL_BITS'(CONST_1)) begin
          le_inA[i] = 1'b1;
        end else if ((config_mux_selA[i]) < WIDTH) begin
          le_inA[i] = sb_bus_in[config_mux_selA[i]] | cb_bus_in[config_mux_selA[i]]; //may need to rework bus muxing logic
        end else begin
          le_inA[i] = 0;
        end
      end
      always_comb begin
        if (config_mux_selB[i] == SEL_BITS'(CONST_0)) begin
          le_inB[i] = 1'b0;
        end else if (config_mux_selB[i] == SEL_BITS'(CONST_1)) begin
          le_inB[i] = 1'b1;
        end else if ((config_mux_selB[i]) < WIDTH) begin
          le_inB[i] = sb_bus_in[config_mux_selB[i]] | cb_bus_in[config_mux_selB[i]]; //may need to rework bus muxing logic
        end else begin
          le_inB[i] = 0;
        end
      end

      // assign le_sel[i] = le_inA[i];
      // assign le_sel[i] = le_inB[i];
    end
  endgenerate

  generate
    for (i = 0; i < LE_OUTPUTS; i++) begin : output_mux
      wire [SEL_BITS-1:0] selA = config_mux_selA[LE_INPUTS + i];
      wire [SEL_BITS-1:0] selB = config_mux_selB[LE_INPUTS + i];

      // genvar j;
      // for (j = 0; j < WIDTH * 2; j++) begin : bus_drive
      //   assign sb_bus2[j] = ((selA == SEL_BITS'(j)) && !config_en && nrst) ? le_out[i*2 + 0] : 1'bz;
      //   assign sb_bus2[j] = ((selB == SEL_BITS'(j)) && !config_en && nrst) ? le_out[i*2 + 1] : 1'bz;
      // end

      genvar j;
      for (j = 0; j < WIDTH; j++) begin : bus_drive
        assign sb_bus_out[j] = (
          (selA == SEL_BITS'(j)) ? le_out[i*2 + 0] :
          (selB == SEL_BITS'(j)) ? le_out[i*2 + 1] :
          cb_bus_in[j] ? cb_bus_in[j] : //incoming bus has last priority
          1'b0 //removed tristate
          );
        assign cb_bus_out[j] = (
          (selA == SEL_BITS'(j)) ? le_out[i*2 + 0] :
          (selB == SEL_BITS'(j)) ? le_out[i*2 + 1] :
          sb_bus_in[j] ? sb_bus_in[j] : //incoming bus has last priority
          1'b0 //removed tristate
          );
      end
    end
  endgenerate
endmodule
