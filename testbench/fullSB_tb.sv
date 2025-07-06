// Improved testbench for fullCB
`timescale 1ns/1ps

module fullSB_tb;

  logic [8:0] cfg;
  wire north, south, east, west;
  logic n_drv, s_drv, e_drv, w_drv;

  // Bidirectional drivers
  assign north = n_drv ? 1'b1 : 1'bz;
  assign south = s_drv ? 1'b1 : 1'bz;
  assign east  = e_drv ? 1'b1 : 1'bz;
  assign west  = w_drv ? 1'b1 : 1'bz;

  // Instantiate the switchbox
  fullSB uut (
    .config_data(cfg),
    .north(north),
    .south(south),
    .east(east),
    .west(west)
  );

  // Driver cleanup
  task clear_drivers();
    n_drv = 0;
    s_drv = 0;
    e_drv = 0;
    w_drv = 0;
  endtask

  task step(); #10; endtask

  // Monitor logic states
  initial begin
    $monitor("Time %0t | N:%b S:%b E:%b W:%b | cfg: %b", $time, north, south, east, west, cfg);
  end

  initial begin
    $dumpfile("waves/fullSB.vcd");
    $dumpvars(0, fullSB_tb);

    clear_drivers();
    cfg = 9'b0;
    step();

    // === Test 1: Single Driver North to South and East ===
    cfg = 9'b0_10_01_01_00; // N: drive, S+E: receive
    n_drv = 1;
    step(); clear_drivers(); step();

    // === Test 2: Single Driver West to North and South ===
    cfg = 9'b0_01_01_10_00; // W: drive, N+S: receive
    w_drv = 1;
    step(); clear_drivers(); step();

    // === Test 3: Dual Adjacent Drivers (North + East), mode 0 (straight)
    cfg = 9'b0_10_10_00_00; // N, E drive
    n_drv = 1; e_drv = 1;
    step(); clear_drivers(); step();

    // === Test 4: Dual Adjacent Drivers (North + East), mode 1 (turn)
    cfg = 9'b1_10_10_00_00; // N, E drive
    n_drv = 1; e_drv = 1;
    step(); clear_drivers(); step();

    // === Test 5: Dual Opposite Drivers (East + West), mode 0 (right)
    cfg = 9'b0_00_10_00_10; // E, W drive
    e_drv = 1; w_drv = 1;
    step();
    cfg = 9'b1_00_10_00_10; // mode 1 (left)
    step(); clear_drivers(); step();

    // === Test 6: Dual Opposite Drivers (North + South), mode 0/1
    cfg = 9'b0_10_00_10_00; // N, S drive
    n_drv = 1; s_drv = 1;
    step();
    cfg = 9'b1_10_00_10_00;
    step(); clear_drivers(); step();

    $finish;
  end
endmodule
