module LEI #(
  parameter
    LE_INPUTS = 4
)(
  input logic clk, en, nrst,
  //          [from]            [  input index  ] [LE#]       
  input logic [2:0] config_data [LE_INPUTS - 1:0] [3:0],
  input logic leout0A, leout0B, leout1A, leout1B,
  output logic [LE_INPUTS - 1:0] lein0A, lein0B, lein1A, lein1B,
  output logic [LE_INPUTS - 1:0] drvLE0A, drvLE0B, drvLE1A, drvLE1B
);

//each LE's input should be able to be driven by any of the other three LE outputs

logic [LE_INPUTS - 1:0] input_drv [3:0]; //weather LEI is driving the LE input
assign drvLE0A = input_drv[0];
assign drvLE0B = input_drv[1];
assign drvLE1A = input_drv[2];
assign drvLE1B = input_drv[3];

logic [LE_INPUTS - 1:0] concat_inputs [3:0];
assign lein0A = concat_inputs[0];
assign lein0B = concat_inputs[1];
assign lein1A = concat_inputs[2];
assign lein1B = concat_inputs[3];

logic concat_outputs [3:0];
assign concat_outputs[0] = leout0A;
assign concat_outputs[1] = leout0B;
assign concat_outputs[2] = leout1A;
assign concat_outputs[3] = leout1B;

//drive inputs with outputs
always @(*) begin
  for (int i = 0; i < 4; i ++) begin //LE#
    for (int j = 0; j < LE_INPUTS; j ++) begin //LE idx
      if (config_data[j][i] < 4) begin
        concat_inputs[j][i] = concat_outputs[config_data[j][i][1:0]];
        input_drv[j][i] = 1'b1;
      end else begin
        concat_inputs[j][i] = 1'b0;
        input_drv[j][i] = 1'b0; //works so long as LE prioritizes CB
      end
    end
  end
end

endmodule