`default_nettype none
module fpga_param #(
    parameter DIM = 2,           // N x N grid
    parameter BUS_WIDTH = 16,
    parameter BITS_PER_CELL = 356
)(
    `ifdef USE_POWER_PINS
        inout vccd1, vssd1,
    `endif
    input logic clk, nrst, config_en,
    input logic config_data_in,
    output logic config_data_out, cfg_done,
    output logic [1:0] cfg_error,

    input logic le_en, le_nrst,

    // IO Busses scaled by DIM
    input  logic [(BUS_WIDTH * DIM) - 1:0] io_north_in,  output logic [(BUS_WIDTH * DIM) - 1:0] io_north_out, output logic [(BUS_WIDTH * DIM) - 1:0] io_north_oeb,
    input  logic [(BUS_WIDTH * DIM) - 1:0] io_south_in,  output logic [(BUS_WIDTH * DIM) - 1:0] io_south_out, output logic [(BUS_WIDTH * DIM) - 1:0] io_south_oeb,
    input  logic [(BUS_WIDTH * DIM) - 1:0] io_east_in,   output logic [(BUS_WIDTH * DIM) - 1:0] io_east_out,  output logic [(BUS_WIDTH * DIM) - 1:0] io_east_oeb,
    input  logic [(BUS_WIDTH * DIM) - 1:0] io_west_in,   output logic [(BUS_WIDTH * DIM) - 1:0] io_west_out,  output logic [(BUS_WIDTH * DIM) - 1:0] io_west_oeb
);

    localparam OEB_BITS = BUS_WIDTH * DIM * 4;
    localparam TOTAL_CFG_BITS = BITS_PER_CELL * (DIM * DIM) + OEB_BITS;

    // --- Configuration Controller ---
    // logic [$clog2(TOTAL_CFG_BITS + 1) :0] config_bits, config_bits_d;
    // logic cfg_done_d, config_en_q;
    // logic [1:0] cfg_error_d;
    // always_ff @(posedge clk, negedge nrst) begin
    //     if (!nrst) begin
    //     config_bits <= '1;
    //     cfg_done <= 0;
    //     config_en_q <= 0;
    //     cfg_error <= 3;
    //     end else begin
    //     config_bits <= config_bits_d;
    //     cfg_done <= cfg_done_d;
    //     config_en_q <= config_en;
    //     cfg_error <= cfg_error_d;
    //     end
    // end

    // always_comb begin
    //     config_bits_d = config_bits;
    //     cfg_error_d = cfg_error;
    //     cfg_done_d = 0;
    //     cfg_error_d = 0;
    //     if (config_en && !config_en_q) begin
    //         config_bits_d = 1;
    //     end else if (!config_en && config_en_q && (config_bits < CFG_BITS)) begin
    //         cfg_error_d = 1;
    //     end else if (!config_en && config_en_q && (config_bits > CFG_BITS)) begin
    //         cfg_error_d = 2;
    //     end else if (config_en) begin
    //         config_bits_d ++;
    //     end else if (config_bits == CFG_BITS) begin
    //         cfg_done_d = 1;
    //         cfg_error_d = 0;
    //     end 
    // end
    // // assign cfg_done_d = (cfg_done || (config_bits == CFG_BITS)) && !(config_en && !config_en_q);
    logic cfg_en;
    // assign cfg_en = config_en && !cfg_done;
    assign cfg_en = config_en;

    // --- Internal Wiring Grids ---
    // We create wires for every possible boundary between cells
    logic [BUS_WIDTH-1:0] east_bus  [0:DIM-1][0:DIM];
    logic [BUS_WIDTH-1:0] west_bus  [0:DIM-1][0:DIM];

    logic [BUS_WIDTH-1:0] north_bus [0:DIM][0:DIM-1];
    logic [BUS_WIDTH-1:0] south_bus [0:DIM][0:DIM-1];
    // Config chain
    logic config_chain [DIM*DIM:0];
    assign config_chain[0] = config_data_in;

    // --- Grid Generation ---
    
    genvar r, c;
    generate
        for (r = 0; r < DIM; r = r + 1) begin : row
            for (c = 0; c < DIM; c = c + 1) begin : col
                
                // Map the 1D config chain to the 2D grid
                localparam int cell_idx = r * DIM + c;

                fpgacell cell_inst (
                    `ifdef USE_POWER_PINS
                        .vccd1(vccd1), .vssd1(vssd1),
                    `endif
                    .clk(clk), .nrst(nrst), .config_en(cfg_en),
                    .config_data_in(config_chain[cell_idx]),
                    .config_data_out(config_chain[cell_idx+1]),
                    .le_clk(clk), .le_en(le_en), .le_nrst(le_nrst),

                    // EAST-WEST

                    // eastbound (c -> c+1)
                    .CBeast_out(east_bus[r][c+1]),
                    .SBwest_in (east_bus[r][c]),

                    // westbound (c+1 -> c)
                    .SBwest_out(west_bus[r][c]),
                    .CBeast_in (west_bus[r][c+1]),


                    // NORTH-SOUTH

                    // northbound (r -> r+1)
                    .CBnorth_out(north_bus[r+1][c]), // Output to the bus above me
                    .SBsouth_in (north_bus[r][c]),   // Input from the bus below me

                    // southbound (r+1 -> r)
                    .SBsouth_out(south_bus[r][c]),   // Output to the bus below me
                    .CBnorth_in (south_bus[r+1][c])  // Input from the bus above me
                );
            end
        end

        // --- Boundary IO Assignments ---
        for (genvar i = 0; i < DIM; i = i + 1) begin : boundaries

            // WEST edge
            assign east_bus[i][0] = io_west_in[i*BUS_WIDTH +: BUS_WIDTH];
            assign io_west_out[i*BUS_WIDTH +: BUS_WIDTH] = west_bus[i][0];

            // EAST edge
            assign west_bus[i][DIM] = io_east_in[i*BUS_WIDTH +: BUS_WIDTH];
            assign io_east_out[i*BUS_WIDTH +: BUS_WIDTH] = east_bus[i][DIM];

            // SOUTH edge
            // SOUTH edge (Row 0)
            assign north_bus[0][i] = io_south_in[i*BUS_WIDTH +: BUS_WIDTH]; // Into the mesh
            assign io_south_out[i*BUS_WIDTH +: BUS_WIDTH] = south_bus[0][i]; // Out of the mesh

            // NORTH edge (Row DIM)
            assign south_bus[DIM][i] = io_north_in[i*BUS_WIDTH +: BUS_WIDTH]; // Into the mesh
            assign io_north_out[i*BUS_WIDTH +: BUS_WIDTH] = north_bus[DIM][i]; // Out of the mesh

        end
    endgenerate

    // --- OEB Shift Register (Remaining logic) ---
    logic [OEB_BITS-1:0] oeb_reg;
    always_ff @(posedge clk, negedge nrst) begin
        if (!nrst) oeb_reg <= '0;
        else if (cfg_en) oeb_reg <= {oeb_reg[OEB_BITS-2:0], config_chain[DIM*DIM]};
    end

    assign {io_north_oeb, io_east_oeb, io_south_oeb, io_west_oeb} = oeb_reg;
    assign config_data_out = oeb_reg[OEB_BITS-1];

endmodule