`default_nettype none
`timescale 1ms/10ns
module wiltonSB_tb;
  parameter WIDTH = 4;

  // DUT-facing inouts
  wire [WIDTH-1:0] north, south, east, west;

  // Tri-state driver signals for testbench
  logic [WIDTH-1:0] north_drv, south_drv, east_drv, west_drv;
  logic [WIDTH-1:0] north_ena, south_ena, east_ena, west_ena;

  // Tri-state assignments (The connection box would fulfill this role in an FPGA)
  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin
      assign north[i] = north_ena[i] ? north_drv[i] : 1'bz;
      assign south[i] = south_ena[i] ? south_drv[i] : 1'bz;
      assign east[i]  = east_ena[i]  ? east_drv[i]  : 1'bz;
      assign west[i]  = west_ena[i]  ? west_drv[i]  : 1'bz;
    end
  endgenerate


  // Unpacked, debug-friendly route select
  logic [1:0] route_sel_unpacked [0:WIDTH-1][0:3];  // [wire][input_dir]

  // Flattened packed route_sel for DUT
  logic [WIDTH*4*2-1:0] route_sel_flat;

  // Task to flatten route_sel_unpacked into packed route_sel_flat
  task automatic flatten_route_sel();
    for (int widx = 0; widx < WIDTH; widx++) begin
      for (int dir = 0; dir < 4; dir++) begin
        int flat_index = (widx * 4 + dir) * 2;
        route_sel_flat[flat_index +: 2] = route_sel_unpacked[widx][dir];
      end
    end
  endtask

  // Instantiate DUT
  wiltonSB #(.WIDTH(WIDTH)) dut (
    .north(north),
    .east(east),
    .south(south),
    .west(west),
    .route_sel(route_sel_flat)
  );

  // Clear signals and route select
  task automatic clear_signals();
    north_ena = '0; south_ena = '0; east_ena = '0; west_ena = '0;
    north_drv = '0; south_drv = '0; east_drv = '0; west_drv = '0;

    for (int widx = 0; widx < WIDTH; widx++) begin
      for (int dir = 0; dir < 4; dir++) begin
        route_sel_unpacked[widx][dir] = 2'b11;  // Disabled
      end
    end
    flatten_route_sel();
  endtask

  // Stimulus and tests
  initial begin
    $dumpfile("waves/wiltonSB.vcd");
    $dumpvars(0, wiltonSB_tb);
    $display("[TEST] Starting Wilton Switchbox Test with WIDTH = %0d", WIDTH);

    clear_signals();

    // Test 1: Single Wire Tests
    // Test 1a: North[0] turns left -> goes to East[0]
    route_sel_unpacked[0][0] = 2'b10;
    flatten_route_sel();

    north_ena[0] = 1;
    north_drv[0] = 1;
    #1;
    north_drv[0] = 0;
    north_ena[0] = 0;
    #1;
    clear_signals();

    // Test 2b: East[1] turns left -> goes to South[1]
    route_sel_unpacked[1][1] = 2'b10;
    flatten_route_sel();

    east_ena[1] = 1;
    east_drv[1] = 1;
    #1;
    east_drv[1] = 0;
    east_ena[1] = 0;
    #1;
    clear_signals();

    // Test 1c: West[2] goes straight -> goes to East[2]
    route_sel_unpacked[2][3] = 2'b01;
    flatten_route_sel();

    west_ena[2] = 1;
    west_drv[2] = 1;
    #1;
    west_drv[2] = 0;
    west_ena[2] = 0;
    #1;
    clear_signals();

    // Test 1d: South[3] goes right -> goes to East[1]
    route_sel_unpacked[3][2] = 2'b00;
    flatten_route_sel();

    south_ena[3] = 1;
    south_drv[3] = 1;
    #1;
    south_drv[3] = 0;
    south_ena[3] = 0;
    #1;

    clear_signals();
    // Test 2: Multiple driver wires on different permutations
    // Test 2a: Two drive wires
    route_sel_unpacked[0][0] = 2'b01; // [wire 0][north] = [straight]
    route_sel_unpacked[1][1] = 2'b01; // [wire 1][east]  = [straight]
    flatten_route_sel();

    north_ena[0] = 1;
    north_drv[0] = 1;
    #1
    east_ena[1] = 1;
    east_drv[1] = 1;
    north_drv[0] = 0;
    #1
    clear_signals();
    #1

    // Test 2b: Three drive wires
    route_sel_unpacked[0][0] = 2'b00; // [wire 0][north] = [right]
    route_sel_unpacked[1][3] = 2'b10; // [wire 1][west]  = [left]
    route_sel_unpacked[2][2] = 2'b01; // [wire 2][south] = [straight]
    flatten_route_sel();

    north_ena[0] = 1;
    north_drv[0] = 1; // to west
    #1
    west_ena[1] = 1;
    west_drv[1] = 1; // to north
    north_drv = 0; // to west
    #1
    south_ena[2] = 1;
    south_drv[2] = 1; //  to north
    west_drv[1] = 0; // to north
    #1
    north_drv[0] = 1; // to west
    #1
    clear_signals();
    #1

    //Test 2c: Four drive wires
    route_sel_unpacked[0][0] = 2'b01; // [wire 0][north] = [straight]
    route_sel_unpacked[1][3] = 2'b01; // [wire 1][west]  = [straight]
    route_sel_unpacked[2][2] = 2'b10; // [wire 2][south] = [left]
    route_sel_unpacked[3][1] = 2'b00; // [wire 3][east]  = [right]
    flatten_route_sel();

    north_ena[0] = 1;
    north_drv[0] = 1; // to south
    #1
    west_ena[1] = 1;
    west_drv[1] = 1; // to east
    north_drv = 0; // to south
    #1
    south_ena[2] = 1;
    south_drv[2] = 1; //  to west
    west_drv[1] = 0; // to east
    #1
    north_drv[0] = 1; // to south
    #1
    east_ena[3] = 1;
    east_drv[3] = 1; // to north
    south_drv[2] = 0; //to west
    #1
    west_drv[1] = 1; //to east
    #1
    north_drv[0] = 0; //to south
    clear_signals();
    #1

    // Test 3: multiple drivers on one permutation without expected bus contention
    //FAIL

    // Test 4: multiple drivers on one permutation with expected bus contention
    route_sel_unpacked[3][2] = 2'b01; // [wire 3][south] = [straight]
    route_sel_unpacked[3][0] = 2'b01; // [wire 3][north]  = [straight]
    flatten_route_sel();

    south_ena = 1;
    north_ena = 1;
    #1
    north_drv = 1;
    #1
    south_drv = 1;
    #1
    north_drv = 0;
    #1
    south_drv = 0;
    #1
    $display("[TEST] Completed");
    $finish;
  end
endmodule



