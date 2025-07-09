module LEI (
	clk,
	en,
	nrst,
	config_data,
	leout0A,
	leout0B,
	leout1A,
	leout1B,
	lein0A,
	lein0B,
	lein1A,
	lein1B,
	drvLE0A,
	drvLE0B,
	drvLE1A,
	drvLE1B
);
	reg _sv2v_0;
	parameter LE_INPUTS = 4;
	input wire clk;
	input wire en;
	input wire nrst;
	input wire [((LE_INPUTS * 4) * 3) - 1:0] config_data;
	input wire leout0A;
	input wire leout0B;
	input wire leout1A;
	input wire leout1B;
	output wire [LE_INPUTS - 1:0] lein0A;
	output wire [LE_INPUTS - 1:0] lein0B;
	output wire [LE_INPUTS - 1:0] lein1A;
	output wire [LE_INPUTS - 1:0] lein1B;
	output wire [LE_INPUTS - 1:0] drvLE0A;
	output wire [LE_INPUTS - 1:0] drvLE0B;
	output wire [LE_INPUTS - 1:0] drvLE1A;
	output wire [LE_INPUTS - 1:0] drvLE1B;
	reg [LE_INPUTS - 1:0] input_drv [3:0];
	assign drvLE0A = input_drv[0];
	assign drvLE0B = input_drv[1];
	assign drvLE1A = input_drv[2];
	assign drvLE1B = input_drv[3];
	reg [LE_INPUTS - 1:0] concat_inputs [3:0];
	assign lein0A = concat_inputs[0];
	assign lein0B = concat_inputs[1];
	assign lein1A = concat_inputs[2];
	assign lein1B = concat_inputs[3];
	wire concat_outputs [3:0];
	assign concat_outputs[0] = leout0A;
	assign concat_outputs[1] = leout0B;
	assign concat_outputs[2] = leout1A;
	assign concat_outputs[3] = leout1B;
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin : sv2v_autoblock_2
					reg signed [31:0] j;
					for (j = 0; j < LE_INPUTS; j = j + 1)
						if (config_data[((j * 4) + i) * 3+:3] < 4) begin
							concat_inputs[j][i] = concat_outputs[config_data[(((j * 4) + i) * 3) + 1-:2]];
							input_drv[j][i] = 1'b1;
						end
						else begin
							concat_inputs[j][i] = 1'b0;
							input_drv[j][i] = 1'b0;
						end
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule