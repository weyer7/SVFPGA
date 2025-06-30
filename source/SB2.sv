`default_nettype none

/**
 * @brief A high-throughput switchbox (SB) module.
 * * This switchbox allows for up to two simultaneous, disjoint connections per channel,
 * effectively doubling the routing capacity compared to a single-bus architecture.
 * For example, it can route north-to-south and east-to-west on the same wire
 * channel at the same time.
 * * It uses a multiplexer-based (Wilton) architecture where each output port for each
 * channel has a dedicated mux to select its driver from the other three inputs.
 *
 * Configuration is done serially via config_data_in, controlled by clk and config_en.
 */
module SB #(
  parameter int WIDTH = 32
)(
  // Bidirectional ports for the four directions
  inout wire [WIDTH-1:0] north,
  inout wire [WIDTH-1:0] east,
  inout wire [WIDTH-1:0] south,
  inout wire [WIDTH-1:0] west,

  // Control and configuration signals
  input logic clk, 
  input logic nrst,
  input logic config_data_in, 
  input logic config_en, // Enables the shifting of configuration data
  output logic config_data_out
);

  // Each channel requires 4 sets of 2-bit selectors, one for each output port (N, E, S, W).
  // Each selector determines which of the other 3 inputs drives the corresponding output.
  // Total bits = WIDTH * 4 outputs * 2 bits/selector
  localparam int CFG_BITS = WIDTH * 4 * 2;
  logic [CFG_BITS - 1:0] config_reg;

  // Configuration chain for serial programming.
  // When config_en is asserted, the configuration data is shifted in.
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      config_reg <= '0;
    end else if (config_en) begin
      config_reg <= {config_reg[CFG_BITS - 2:0], config_data_in};
    end
  end

  // The last bit of the configuration register is shifted out.
  assign config_data_out = config_reg[CFG_BITS - 1];

  // For clarity, we define a struct for the configuration of a single wire channel.
  // This makes the code more readable than indexing into a flat array.
  // The configuration for each output port selects one of three possible inputs or 'disabled'.
  typedef struct packed {
    logic [1:0] west_src_sel;  // Selects source for the 'west' output port
    logic [1:0] south_src_sel; // Selects source for the 'south' output port
    logic [1:0] east_src_sel;  // Selects source for the 'east' output port
    logic [1:0] north_src_sel; // Selects source for the 'north' output port
  } chan_cfg_t;

  // Create a view of the flat config_reg as an array of structs for easy access.
  chan_cfg_t [WIDTH-1:0] chan_cfg;
  assign chan_cfg = config_reg;


  // Generate the multiplexer-based switchbox logic for each wire.
  // This architecture allows for two disjoint paths per wire (e.g., N-S and E-W simultaneously).
  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : wire_loop

      // Mux for the 'north' output port of wire i.
      // It can be driven by east[i], south[i], or west[i].
      always_comb begin
        // During configuration, all outputs are high-Z to prevent contention.
        if (config_en) begin
            north[i] = 1'bz;
        end else begin
            case (chan_cfg[i].north_src_sel)
              2'b00:   north[i] = east[i];   // Driven by east
              2'b01:   north[i] = south[i];  // Driven by south
              2'b10:   north[i] = west[i];   // Driven by west
              default: north[i] = 1'bz;      // Disabled (High-Z)
            endcase
        end
      end

      // Mux for the 'east' output port of wire i.
      // It can be driven by north[i], south[i], or west[i].
      always_comb begin
        if (config_en) begin
            east[i] = 1'bz;
        end else begin
            case (chan_cfg[i].east_src_sel)
              2'b00:   east[i] = north[i];   // Driven by north
              2'b01:   east[i] = south[i];   // Driven by south
              2'b10:   east[i] = west[i];    // Driven by west
              default: east[i] = 1'bz;       // Disabled (High-Z)
            endcase
        end
      end

      // Mux for the 'south' output port of wire i.
      // It can be driven by north[i], east[i], or west[i].
      always_comb begin
        if (config_en) begin
            south[i] = 1'bz;
        end else begin
            case (chan_cfg[i].south_src_sel)
              2'b00:   south[i] = north[i];  // Driven by north
              2'b01:   south[i] = east[i];   // Driven by east
              2'b10:   south[i] = west[i];   // Driven by west
              default: south[i] = 1'bz;      // Disabled (High-Z)
            endcase
        end
      end

      // Mux for the 'west' output port of wire i.
      // It can be driven by north[i], east[i], or south[i].
      always_comb begin
        if (config_en) begin
            west[i] = 1'bz;
        end else begin
            case (chan_cfg[i].west_src_sel)
              2'b00:   west[i] = north[i];   // Driven by north
              2'b01:   west[i] = east[i];    // Driven by east
              2'b10:   west[i] = south[i];   // Driven by south
              default: west[i] = 1'bz;       // Disabled (High-Z)
            endcase
        end
      end
    end
  endgenerate

endmodule
