`default_nettype none
module LEI #(
  parameter int LE_INPUTS = 4
)(
  input logic clk, nrst, config_en,
  input logic config_data_in,
  output logic config_data_out,

  input logic leout0A, leout0B, leout1A, leout1B,

  //connections to nearby LE outputs
  input logic [3:0] ccw_in, cw_in,
  output logic [3:0] ccw_out, cw_out,

  output logic [LE_INPUTS-1:0] lein0A, lein0B, lein1A, lein1B
  // output logic [LE_INPUTS-1:0] drvLE0A, drvLE0B, drvLE1A, drvLE1B
);
  //packed config_data: [LE_INPUTS * 4 * 12 - 1:0]
  localparam CFG_BITS = LE_INPUTS * 4 * 12;
  logic [CFG_BITS - 1:0] config_data;

  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      config_data <= '0;
    end else if (config_en) begin
      config_data <= {config_data[CFG_BITS - 2:0], config_data_in};
    end
  end

  assign config_data_out = config_data[CFG_BITS - 1];

  //output bits grouped as: {1B, 1A, 0B, 0A} => indexes 3,2,1,0
  logic [3:0] le_outputs;
  assign le_outputs = {leout1B, leout1A, leout0B, leout0A};

  logic [LE_INPUTS-1:0] concat_inputs [3:0];
  // logic [LE_INPUTS-1:0] input_drv     [3:0];

  assign lein0A   = concat_inputs[0];
  assign lein0B   = concat_inputs[1];
  assign lein1A   = concat_inputs[2];
  assign lein1B   = concat_inputs[3];

  logic [11:0] concat_inputs2;

  assign concat_inputs2 = {ccw_in, cw_in, le_outputs};

  // assign drvLE0A  = input_drv[0];
  // assign drvLE0B  = input_drv[1];
  // assign drvLE1A  = input_drv[2];
  // assign drvLE1B  = input_drv[3];

  assign ccw_out = le_outputs;
  assign cw_out = le_outputs;

  always_comb begin
    for (int i = 0; i < 4; i++) begin //LE input group (0A, 0B, 1A, 1B)
      for (int j = 0; j < LE_INPUTS; j++) begin // LE input index
        //compute flat index manually (must be pure arithmetic)
        //flat_index = ((j * 4) + i) * 3
        logic [3:0] sel;
        sel = config_data[(((j << 2) + i) * 4) +: 4];
        if (sel < 4'd12) begin
          concat_inputs[i][j] = concat_inputs2[sel];
          // input_drv[i][j]     = 1'b1;
        end else begin
          concat_inputs[i][j] = 1'b0;
          // input_drv[i][j]     = 1'b0;
        end
      end
    end
  end

endmodule
