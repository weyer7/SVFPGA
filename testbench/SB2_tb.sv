`default_nettype none
`timescale 1ns/1ps

/**
 * @brief Testbench for the high-throughput switchbox (SB) module.
 *
 * This testbench verifies the functionality of the Wilton-style switchbox,
 * focusing on its ability to handle multiple simultaneous connections, including
 * two disjoint paths on the same channel.
 * This version is updated to be compatible with simulators like Icarus Verilog
 * by removing features like 'ref' arguments in tasks.
 */
module SB2_tb;
  // Use a small width for simulation speed and readability
  parameter int WIDTH = 4;

  // DUT Signals
  wire [WIDTH-1:0] north, south, east, west;
  logic clk = 0;
  logic nrst = 0; // Active-low reset
  logic config_en = 0;
  logic config_data_in = 0;
  logic config_data_out;
  
  // Testbench driver logic for the inout ports
  logic [WIDTH-1:0] north_drv, south_drv, east_drv, west_drv;
  logic [WIDTH-1:0] north_ena, south_ena, east_ena, west_ena;

  // Tri-state buffer assignments to drive the DUT's inout ports
  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin
      assign north[i] = north_ena[i] ? north_drv[i] : 1'bz;
      assign south[i] = south_ena[i] ? south_drv[i] : 1'bz;
      assign east[i]  = east_ena[i]  ? east_drv[i]  : 1'bz;
      assign west[i]  = west_ena[i]  ? west_drv[i]  : 1'bz;
    end
  endgenerate

  // Replicate the DUT's configuration struct for easy and readable test writing.
  typedef struct packed {
    logic [1:0] west_src_sel;  // Selects source for the 'west' output port
    logic [1:0] south_src_sel; // Selects source for the 'south' output port
    logic [1:0] east_src_sel;  // Selects source for the 'east' output port
    logic [1:0] north_src_sel; // Selects source for the 'north' output port
  } chan_cfg_t;

  // Testbench representation of the configuration to be loaded.
  localparam int CFG_BITS = WIDTH * 4 * 2;
  chan_cfg_t [WIDTH-1:0] test_cfg;
  logic [CFG_BITS-1:0] config_bits;

  // DUT instantiation
  SB #(.WIDTH(WIDTH)) dut (
    .north(north), 
    .south(south), 
    .east(east), 
    .west(west),
    .clk(clk), 
    .nrst(nrst),
    .config_data_in(config_data_in),
    .config_en(config_en),
    .config_data_out(config_data_out)
  );
  
  // Free-running clock generator (100 MHz)
  always #5 clk = ~clk;

  /**
   * @brief Resets all drivers and sets the test configuration to 'all disabled'.
   */
  task automatic clear_and_disable();
    // Disable all testbench drivers
    north_ena = '0; south_ena = '0; east_ena = '0; west_ena = '0;
    north_drv = 'x; south_drv = 'x; east_drv = 'x; west_drv = 'x;

    // Use an aggregate assignment to disable all selectors. This is more robust
    // than a for-loop for some compilers. Each of the 4 selectors gets 2'b11.
    test_cfg = '1;
    
    // Flatten the configuration struct into a bit vector for loading.
    config_bits = test_cfg;
  endtask

  /**
   * @brief Loads a configuration bitstream into the DUT's shift register.
   */
  task automatic load_config(input logic [CFG_BITS-1:0] data);
    config_en = 1;
    // Shift in the configuration data, LSB first, one bit per clock cycle.
    for (int i = 0; i < CFG_BITS; i++) begin
      config_data_in = data[i];
      #10; // Wait for one clock cycle (posedge + negedge)
    end
    config_en = 0;
    config_data_in = 0; // Return input to idle state
    #10;
  endtask
  
  // Main test sequence
  initial begin
    $dumpfile("waves/SB2.vcd");
    $dumpvars(0, SB2_tb);
    $display("[TB] Starting Switchbox Test with WIDTH = %0d", WIDTH);

    // 1. Reset the DUT and testbench drivers
    clear_and_disable();
    nrst = 0;
    #20;
    nrst = 1;
    #10;
    $display("[TB] Reset complete.");

    // 2. Load initial 'all disabled' configuration into the DUT
    load_config(config_bits);
    
    // =========================================================================
    // Test 1: Simple single connections on different channels
    // =========================================================================
    $display("[TB] Starting Test 1: Simple connections");
    
    // Test 1a: North[0] drives East[0]
    clear_and_disable();
    test_cfg[0].east_src_sel = 2'b00; // Mux for east[i]: 2'b00=north
    config_bits = test_cfg;
    load_config(config_bits);
    north_ena[0] = 1; north_drv[0] = 1; #10; north_ena[0] = 0; north_drv[0] = 'x;
    #20;
    
    // Test 1b: East[1] drives South[1]
    clear_and_disable();
    test_cfg[1].south_src_sel = 2'b01; // Mux for south[i]: 2'b01=east
    config_bits = test_cfg;
    load_config(config_bits);
    east_ena[1] = 1; east_drv[1] = 1; #10; east_ena[1] = 0; east_drv[1] = 'x;
    #20;

    // Test 1c: West[2] drives North[2]
    clear_and_disable();
    test_cfg[2].north_src_sel = 2'b10; // Mux for north[i]: 2'b10=west
    config_bits = test_cfg;
    load_config(config_bits);
    west_ena[2] = 1; west_drv[2] = 1; #10; west_ena[2] = 0; west_drv[2] = 'x;
    #20;

    // =========================================================================
    // Test 2: Multiple connections on DIFFERENT channels simultaneously
    // =========================================================================
    $display("[TB] Starting Test 2: Multiple connections on different channels");
    clear_and_disable();
    test_cfg[0].south_src_sel = 2'b00; // North[0] -> South[0]
    test_cfg[1].west_src_sel  = 2'b01; // East[1]  -> West[1]
    test_cfg[2].north_src_sel = 2'b01; // South[2] -> North[2]
    test_cfg[3].east_src_sel  = 2'b10; // West[3]  -> East[3]
    config_bits = test_cfg;
    load_config(config_bits);
    
    // Drive all inputs at once with different data
    fork
      begin north_ena[0] = 1; north_drv[0] = 1; #10; north_ena[0] = 0; north_drv[0] = 'x; end
      begin east_ena[1]  = 1; east_drv[1]  = 0; #10; east_ena[1]  = 0; east_drv[1]  = 'x; end
      begin south_ena[2] = 1; south_drv[2] = 1; #10; south_ena[2] = 0; south_drv[2] = 'x; end
      begin west_ena[3]  = 1; west_drv[3]  = 0; #10; west_ena[3]  = 0; west_drv[3]  = 'x; end
    join
    #20;

    // =========================================================================
    // Test 3: Dual connections on the SAME channel (Key Test)
    // =========================================================================
    $display("[TB] Starting Test 3: Dual connections on the SAME channel");
    clear_and_disable();
    // Channel 1: North[1] -> South[1]  AND  East[1] -> West[1]
    test_cfg[1].south_src_sel = 2'b00; // South output is driven by North
    test_cfg[1].west_src_sel  = 2'b01; // West output is driven by East
    config_bits = test_cfg;
    load_config(config_bits);
    
    // Drive the two paths simultaneously and check outputs
    $display("[TB]   Driving N[1] and E[1] simultaneously.");
    north_ena[1] = 1; north_drv[1] = 1;
    east_ena[1] = 1;  east_drv[1] = 0;
    #20;
    // In the waveform viewer, check that south[1]==1 and west[1]==0.
    north_ena[1] = 0; north_drv[1] = 'x;
    east_ena[1] = 0;  east_drv[1] = 'x;
    #20;
    
    // =========================================================================
    // Test 4: Combinational loop (latch creation) test
    // =========================================================================
    $display("[TB] Starting Test 4: Combinational loop test");
    clear_and_disable();
    // Channel 2: North[2] -> South[2] AND South[2] -> North[2]
    // This creates a direct feedback loop, which should behave like a latch.
    test_cfg[2].south_src_sel = 2'b00; // South output is driven by North
    test_cfg[2].north_src_sel = 2'b01; // North output is driven by South
    config_bits = test_cfg;
    load_config(config_bits);

    // Drive one side of the loop to 'set' the latch
    $display("[TB]   Setting the latch on channel 2 to 1.");
    north_ena[2] = 1; north_drv[2] = 1; #10; north_ena[2] = 0; north_drv[2] = 'x;
    #10; // Allow time for value to propagate and latch
    // Now drive the other side to 'reset' the latch
    $display("[TB]   Resetting the latch on channel 2 to 0.");
    south_ena[2] = 1; south_drv[2] = 0; #10; south_ena[2] = 0; south_drv[2] = 'x;
    #10;

    $display("[TB] All tests completed.");
    $finish;
  end

endmodule