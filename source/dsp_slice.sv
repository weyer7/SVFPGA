typedef enum logic [3:0] {
  BUF,
  NOT,
  OR,
  NOR,
  AND,
  NAND,
  XOR,
  XNOR,
  ADD_S,
  ADD_US,
  MULT_S,
  MULT_US,
  DIV_S,
  DIV_US,
  SQRT_S,
  SQRT_US
} opcode_t;

module dsp_slice #(
  parameter
    DSP_BIT_DEPTH = 4,
    BUS_WIDTH = 14
)(
  input  logic clk,
  input  logic config_en,
  input  logic nrst,
  input  logic config_data_in,
  output logic config_data_out,
  input  logic config_data,
  input  logic [BUS_WIDTH - 1:0] in,
  output logic [BUS_WIDTH - 1:0] out
);

  // Local parameters and signals
  opcode_t operation;
  assign operation[3:0] = in[DSP_BIT_DEPTH * 2 + 3:DSP_BIT_DEPTH * 2];
  logic signed   [DSP_BIT_DEPTH-1:0] signed_a, signed_b;
  logic         [DSP_BIT_DEPTH-1:0] unsigned_a, unsigned_b;
  logic signed   [2*DSP_BIT_DEPTH-1:0] signed_result;
  logic         [2*DSP_BIT_DEPTH-1:0] unsigned_result;
  logic [DSP_BIT_DEPTH-1:0] root;

  always_comb begin
    out = in;
    signed_a   = in[DSP_BIT_DEPTH - 1:0];
    signed_b   = in[2*DSP_BIT_DEPTH - 1:DSP_BIT_DEPTH];
    unsigned_a = in[DSP_BIT_DEPTH - 1:0];
    unsigned_b = in[2*DSP_BIT_DEPTH - 1:DSP_BIT_DEPTH];
    signed_result = '0;
    unsigned_result = '0;
    root = '0;

    case (operation)
      BUF: begin
        out[DSP_BIT_DEPTH - 1:0] = in[DSP_BIT_DEPTH - 1:0];
      end
      NOT: begin
        out[DSP_BIT_DEPTH - 1:0] = ~in[DSP_BIT_DEPTH - 1:0];
      end
      OR: begin
        out[0] = |in[DSP_BIT_DEPTH - 1:0];
      end
      NOR: begin
        out[0] = ~|in[DSP_BIT_DEPTH - 1:0];
      end
      AND: begin
        out[0] = &in[DSP_BIT_DEPTH - 1:0];
      end
      NAND: begin
        out[0] = ~&in[DSP_BIT_DEPTH - 1:0];
      end
      XOR: begin
        out[DSP_BIT_DEPTH - 1:0] = in[2*DSP_BIT_DEPTH - 1:DSP_BIT_DEPTH] ^ in[DSP_BIT_DEPTH - 1:0];
      end
      XNOR: begin
        out[DSP_BIT_DEPTH - 1:0] = ~(in[2*DSP_BIT_DEPTH - 1:DSP_BIT_DEPTH] ^ in[DSP_BIT_DEPTH - 1:0]);
      end
      ADD_S: begin
        signed_result = signed_a + signed_b;
        out[DSP_BIT_DEPTH-1:0] = signed_result[DSP_BIT_DEPTH-1:0];
      end
      ADD_US: begin
        unsigned_result = unsigned_a + unsigned_b;
        out[DSP_BIT_DEPTH-1:0] = unsigned_result[DSP_BIT_DEPTH-1:0];
      end
      MULT_S: begin
        signed_result = signed_a * signed_b;
        out[DSP_BIT_DEPTH-1:0] = signed_result[DSP_BIT_DEPTH-1:0];
      end
      MULT_US: begin
        unsigned_result = unsigned_a * unsigned_b;
        out[DSP_BIT_DEPTH-1:0] = unsigned_result[DSP_BIT_DEPTH-1:0];
      end
      DIV_S: begin
        if (signed_b != 0) begin
          signed_result = signed_a / signed_b;
          out[DSP_BIT_DEPTH-1:0] = signed_result[DSP_BIT_DEPTH-1:0];
        end
      end
      DIV_US: begin
        if (unsigned_b != 0) begin
          unsigned_result = unsigned_a / unsigned_b;
          out[DSP_BIT_DEPTH-1:0] = unsigned_result[DSP_BIT_DEPTH-1:0];
        end
      end
      SQRT_S: begin
        signed_result = signed_a;
        if (signed_result >= 0) begin
          for (int i = DSP_BIT_DEPTH-1; i >= 0; i--) begin
            if ((root | (1 << i)) * (root | (1 << i)) <= signed_result) begin
              root = root | (1 << i);
            end
          end
          out[DSP_BIT_DEPTH-1:0] = root;
        end
      end
      SQRT_US: begin
        unsigned_result = unsigned_a;
        for (int i = DSP_BIT_DEPTH-1; i >= 0; i--) begin
          if ((root | (1 << i)) * (root | (1 << i)) <= unsigned_result) begin
            root = root | (1 << i);
          end
        end
        out[DSP_BIT_DEPTH-1:0] = root;
      end
    endcase
  end
endmodule
