`default_nettype none

module top (
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Internal inout wire to emulate a shared tri-state bus
  // wire bus;

  // // Two drivers and one reader
  // logic drive_a, value_a;
  // logic drive_b, value_b;
  // logic read_val;

  // // Button controls
  // assign drive_a = pb[0];    // enable A
  // assign value_a = pb[1];    // value from A

  // assign drive_b = pb[2];    // enable B
  // assign value_b = pb[3];    // value from B

  // // Driver A
  // assign bus = (drive_a) ? value_a : 1'bz;

  // // Driver B
  // assign bus = (drive_b) ? value_b : 1'bz;

  // // Reader (shared wire)
  // assign read_val = bus;

  // // Visual feedback
  // assign red   = drive_a & drive_b & (value_a != value_b);  // conflict!
  // assign green = read_val;                                  // current bus value
  // assign blue  = ~(drive_a | drive_b);                      // idle
  tri_state tristate(.bus(), .read_val(green), .drive_a(pb[0]), .drive_b(pb[2]), .value_a(pb[1]), .value_b(pb[3]), .red(), .green(), .blue());

endmodule
