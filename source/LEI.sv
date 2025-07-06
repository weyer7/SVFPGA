// module LEI #(
//   parameter
//     LE_INPUTS = 4
// )(
//   input logic clk, en, nrst,
//   input logic [LE_INPUTS - 1:0][3:0]config_data [3:0],
//   input logic leout0A, leout0B, leout1A, leout1B,
//   output logic [LE_INPUTS - 1:0] lein0A, lein0B, lein1A, lein1B
// );

// //each LE's input should be able to be driven by any of the other three LE outputs
// //SIGNAL: [idx][drivenLE] = [driverLE]
// //RANGE:  [1:0][1:0]      = [1:0]

// logic [LE_INPUTS - 1:0] concat_outputs [3:0];
// assign concat_outputs[0] = lein0A;
// assign concat_outputs[1] = lein0B;
// assign concat_outputs[2] = lein1A;
// assign concat_outputs[3] = lein1B;

// logic concat_inputs [3:0];
// assign concat_inputs[0] = leout0A;
// assign concat_inputs[1] = leout0B;
// assign concat_inputs[2] = leout1A;
// assign concat_inputs[3] = leout1B;

// always_comb begin
//   for (int i = 0; i < LE_INPUTS; i ++) begin

//   end
// end

// endmodule