`default_nettype none
module tri_state (
  //put your ports here
  inout wire bus,
  input logic drive_a, value_a,
  input logic drive_b, value_b,
  output logic read_val, red, green, blue
);
//your code starts here ...

  // Driver A
  assign bus = (drive_a) ? value_a : 1'bz;

  // Driver B
  assign bus = (drive_b) ? value_b : 1'bz;

  // Reader (shared wire)
  assign read_val = bus;

  // Visual feedback
  assign red   = drive_a & drive_b & (value_a != value_b);  // conflict!
  assign green = read_val;                                  // current bus value
  assign blue  = ~(drive_a | drive_b);                      // idle
endmodule