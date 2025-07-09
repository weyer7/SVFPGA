`default_nettype none
`timescale 1ms / 10ns

module tbuf_tb;
  logic a, b, f;
  // DUT
  tbuf dut (
    .a(a),
    .b(b),
    .f(f)
  );

  initial begin

    $dumpfile("waves/tbuf.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, tbuf_tb);
    
    for (int i = 0; i < 4; i ++) begin
      {b, a} = i[1:0];
      #1;
    end

    $display("Starting testbench...");


    $display("All tests completed.");
    $finish;
  end

endmodule
