`default_nettype none
`timescale 1ms / 10ns

module LEI_tb;

  localparam int LE_INPUTS = 4;
  localparam CFG_BITS = LE_INPUTS * 4 * 3;

  //CRAM signals
  logic clk, en, nrst;
  logic config_data_in, config_data_out;
  logic config_en;

  //    [from]            [  input index  ] [LE#]       
  logic [LE_INPUTS * 4 * 3 - 1:0] config_data;
  logic leout0A, leout0B, leout1A, leout1B;
  logic [LE_INPUTS - 1:0]drvLE0A, drvLE0B, drvLE1A, drvLE1B;

  int test_case;

  //outputs
  logic [LE_INPUTS - 1:0] lein0A, lein0B, lein1A, lein1B;

  // DUT
  LEI dut (
    .*
  );

  task reset();
    begin
      nrst = 0; en = 1; config_en = 0; config_data_in = 0; clk = 0;
      #1;
      nrst = 1;
      config_en = 1;
      #1;
    end
  endtask

  task cram(logic [CFG_BITS - 1:0] data);
    begin
      config_en = 1; //allow configuration
      for (int i = CFG_BITS; i > 0; i --) begin
        clk = 0;
        config_data_in = data[i - 1]; //MSB first
        #0.01;
        clk = 1;
        #0.01;
      end
      clk = 0;
      config_data_in = 0;
      config_en = 0;
    end
  endtask

  task clear_signals();
    begin
      for (int i = 0; i < 4; i ++) begin
        for (int j = 0; j < LE_INPUTS; j ++) begin
          config_dataup[j][i] = '1;
        end
      end
      {leout0A, leout0B, leout1A, leout1B} = '0;
      flatten_config_data();
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

  logic [2:0] config_dataup [LE_INPUTS - 1:0] [3:0];

  task automatic flatten_config_data();
  //   input  logic [2:0] config_data [LE_INPUTS - 1:0][3:0],
  //   output logic [LE_INPUTS * 4 * 3 - 1:0] config_packed
  // );
    config_data = '0;
    for (int j = 0; j < LE_INPUTS; j++) begin
      for (int i = 0; i < 4; i++) begin
        config_data[(j * 4 + i) * 3 +: 3] = config_dataup[j][i];
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
    reset();
    //[idx][LEin#] = [LEout#]
    config_dataup[0][0] = 1; //leout0A[0] = [leout0B]
    //[idx][LEdvn] = [LEdrv]
    flatten_config_data();
    cram(config_data);
    cycle_inputs();

    // =================================
    // TEST CASE 2: 4 drivers to same LE
    // =================================
    clear_signals();
    test_case = 2; //2 drivers to same LE

    config_dataup[0][0] = 1;
    config_dataup[1][0] = 2;
    config_dataup[2][0] = 3;
    config_dataup[3][0] = 0;

    flatten_config_data();
    cram(config_data);
    cycle_inputs();

    // ==============================
    // TEST CASE 3: all inputs driven
    // ==============================
    clear_signals();
    test_case = 3;

    for (int i = 0; i < 4; i ++) begin
      config_dataup[0][i] = (i + 0) % 4;
      config_dataup[1][i] = (i + 1) % 4;
      config_dataup[2][i] = (i + 2) % 4;
      config_dataup[3][i] = (i + 3) % 4;
    end

    flatten_config_data();
    cram(config_data);
    cycle_inputs();

    $display("All tests completed.");
    $finish;
  end

endmodule
