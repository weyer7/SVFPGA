`default_nettype none
`timescale 1ms / 10ns

module LEI_tb;

  localparam int LE_INPUTS = 4;

  // Inputs
  // logic clk, en, nrst;
  // logic config_data_in, config_en, config_data_out;
  logic clk, en, nrst;
  //    [from]            [  input index  ] [LE#]       
  logic [2:0] config_data [LE_INPUTS - 1:0] [3:0];
  logic leout0A, leout0B, leout1A, leout1B;
  logic [LE_INPUTS - 1:0]drvLE0A, drvLE0B, drvLE1A, drvLE1B;

  int test_case;

  // Output
  logic [LE_INPUTS - 1:0] lein0A, lein0B, lein1A, lein1B;

  // DUT
  LEI dut (
    .*
  );

  // task reset();
  //   begin
  //     nrst = 0; en = 1; config_en = 0; config_data_in = 0; clk = 0;
  //     #1;
  //     nrst = 1;
  //     config_en = 1;
  //     #1;
  //   end
  // endtask

  // task cram(logic [(LUT_SIZE + 1) - 1:0] data);
  //   begin
  //     config_en = 1; //allow configuration
  //     for (int i = LUT_SIZE + 1; i > 0; i --) begin
  //       clk = 0;
  //       config_data_in = data[i - 1]; //MSB first
  //       #1;
  //       clk = 1;
  //       #1;
  //     end
  //     config_en = 0;
  //   end
  // endtask

  task clear_signals();
    begin
      for (int i = 0; i < 4; i ++) begin
        for (int j = 0; j < LE_INPUTS; j ++) begin
          config_data[j][i] = '1;
        end
      end
      {leout0A, leout0B, leout1A, leout1B} = '0;
      // {drvLE1B, drvLE1A, drvLE0B, drvLE0A} = '0;
      #1;
    end
  endtask

  task cycle_inputs();
    begin
      for (int i = 0; i < 4 * LE_INPUTS; i ++) begin
        {leout1B, leout1A, leout0B, leout0A} = i[3:0];
        #1;
      end
    end
  endtask

  initial begin

    $dumpfile("waves/LEI.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, LEI_tb);

    $display("Starting testbench...");
    clear_signals();

    // ==========================
    // TEST CASE 1: single driver
    // ==========================
    test_case = 1;
    //[idx][LEin#] = [LEout#]
    config_data[0][0] = 1; //leout0A[0] = [leout0B]
    //[idx][LEdvn] = [LEdrv]
    cycle_inputs();

    // =================================
    // TEST CASE 2: 4 drivers to same LE
    // =================================
    clear_signals();
    test_case = 2; //2 drivers to same LE

    config_data[0][0] = 1;
    config_data[0][1] = 2;
    config_data[0][2] = 3;
    config_data[0][3] = 0;

    cycle_inputs();

    // ==============================
    // TEST CASE 3: all inputs driven
    // ==============================
    clear_signals();
    test_case = 3;

    $display("All tests completed.");
    $finish;
  end

endmodule
