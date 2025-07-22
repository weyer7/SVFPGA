module io (
  input logic clk, config_en, nrst,
    config_data_in,
  output logic config_data_out,
  input logic [31:0] fpga_outputs,
  output logic [31:0] fpga_inputs,
  input logic [31:0] io_inputs,
  output logic [31:0] oeb, io_outputs
);
  logic [63:0] config_data;
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      config_data <= '0;
    end else if (config_en) begin
      config_data <= {config_data[62:0], config_data_in};
    end
  end
  assign config_data_out = config_data[63];

  always_comb begin
    oeb = '1;
    io_outputs = '0;
    fpga_inputs = '0;
    for (int i = 0; i < 32; i ++) begin
      case (config_data[i * 2 + 1 +:2]) //check indexing
        2'b00: ;
        2'b01: fpga_inputs[i] = io_inputs[i]; //io pad drives fpga input
        2'b10: begin
          io_outputs[i] = fpga_outputs[i]; //fpga output drives io pad
          oeb[i] = 0;
        end
        2'b11: ;
      endcase
    end
  end

endmodule