module io #(
  parameter
    IO_COUNT = 128
)(
  //CRAM signals
  input logic clk, en, nrst, config_en,
    config_data_in,
  output logic config_data_out,

  //configurable logic signals (to drive input registered and synchronized modes)
  input logic le_clk, le_en, le_nrst,

  //external clock (to drive output registered and synchronized modes)
  input logic ext_clk,

  //external IO
  inout wire [IO_COUNT - 1:0] io_top,

  //to internal FPGA cells
  output logic [IO_COUNT - 1:0] in, //from pad to logic
  input logic [IO_COUNT - 1:0] out //from logic to pad
);
  //    [ IO index ]  [mode] (000 = NC, 001 = in, 010 = out, 011 = in registered, 
  //    100 out registered, 101 in synchronized, 110 out synchronized, 
  //    111 inout with weak output series resistors)
  localparam CFG_WIDTH = IO_COUNT * 3;
  logic [CFG_WIDTH-1:0] config_data;

  always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
      config_data <= '0;
    else if (config_en)
      config_data <= {config_data[CFG_WIDTH-2:0], config_data_in};
  end

  assign config_data_out = config_data[CFG_WIDTH-1];

  //internal registers for registered/synchronized modes
  logic [IO_COUNT-1:0] in_reg, in_sync_1, in_sync_2;
  logic [IO_COUNT-1:0] out_reg, out_sync_1, out_sync_2;

  // Capture inputs for register and sync modes
  always_ff @(posedge le_clk or negedge le_nrst) begin
    if (!le_nrst) begin
      in_reg <= '0;
      in_sync_1 <= '0;
      in_sync_2 <= '0;
    end else if (le_en) begin
      in_reg <= io_top;
      in_sync_1 <= io_top;
      in_sync_2 <= in_sync_1;
    end
  end

  //register/sync outputs on external clock
  always_ff @(posedge ext_clk or negedge nrst) begin
    if (!nrst) begin
      out_reg <= '0;
      out_sync_1 <= '0;
      out_sync_2 <= '0;
    end else begin
      out_reg <= out;
      out_sync_1 <= out;
      out_sync_2 <= out_sync_1;
    end
  end

  //logic to drive in[] and io_top[] based on mode
  genvar i;
  generate
    for (i = 0; i < IO_COUNT; i++) begin : io_cfg
      wire [2:0] mode = config_data[i * 3 +: 3];

      // Input logic
      always_comb begin
        unique case (mode)
          3'b001: in[i] = io_top[i];        // direct input
          3'b011: in[i] = in_reg[i];        // input registered
          3'b101: in[i] = in_sync_2[i];     // input synchronized
          default: in[i] = 1'b0;            // NC, outputs
        endcase
      end

      //output logic (tri-state)
      always_comb begin
        unique case (mode)
          3'b010: io_top[i] = out[i];        // direct output
          3'b100: io_top[i] = out_reg[i];    // output registered
          3'b110: io_top[i] = out_sync_2[i]; // output synchronized
          default: io_top[i] = 1'bz;         // NC or input
        endcase
      end
    end
  endgenerate

endmodule
