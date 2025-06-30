`timescale 1ms/10ps
module tri_state_tb;
  wire bus;
  logic drive_a, value_a, drive_b, value_b;
  logic read_val, red, green, blue;
  logic expected;
  tri_state tritest (.*);
  initial begin
    // make sure to dump the signals so we can see them in the waveform
    $dumpfile("waves/tri_state.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, tri_state_tb);
    
    //initial values
    drive_a = 0;
    drive_b = 0;
    value_a = 0;
    value_b = 0;
    #5
    for (int i = 0; i < 16; i ++) begin
      {value_b, drive_b, value_a, drive_a} = i[3:0];
      $display("bus = %d", read_val);
      if (!drive_a && !drive_b) begin
        expected = 1'bz;
      end else if (drive_a && !drive_b)begin
        expected = value_a;
      end else if (!drive_a && drive_b) begin
        expected = value_b;
      end else if (value_a == value_b) begin
        expected = value_a;
      end else begin
        expected = 1'bx;
      end
      #1;
    end 
    // finish the simulation
    #1 $finish;
  end
endmodule