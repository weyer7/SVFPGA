`default_nettype none

module fullSB (
  input  logic [8:0] config_data, // [8]=mode, then [7:6]=n_{dve,dvn}, [5:4]=e_{dve,dvn}, [3:2]=s_{dve,dvn}, [1:0]=w_{dve,dvn}
  inout  wire north, east, south, west
);

  // Unpack configuration
  logic mode;
  logic n_dve, n_dvn;
  logic e_dve, e_dvn;
  logic s_dve, s_dvn;
  logic w_dve, w_dvn;

  assign mode  = config_data[8];
  assign n_dve = config_data[7]; assign n_dvn = config_data[6];
  assign e_dve = config_data[5]; assign e_dvn = config_data[4];
  assign s_dve = config_data[3]; assign s_dvn = config_data[2];
  assign w_dve = config_data[1]; assign w_dvn = config_data[0];

  // Number of active drivers
  logic [2:0] drv_count = n_dve + e_dve + s_dve + w_dve;

  // Store driver values
  logic [3:0] dir_dve;
  logic [3:0] dir_val;
  assign dir_dve = {w_dve, s_dve, e_dve, n_dve};
  assign dir_val = {west, south, east, north};


  // Output enables and values for each direction
  logic [3:0] out_en;
  logic [3:0] out_val;

  // Helper function: rotate direction (0=N, 1=E, 2=S, 3=W)
  function automatic int rot(input int src, input logic turn_left);
    case (src)
      0: rot = turn_left ? 3 : 1; // N -> W or E
      1: rot = turn_left ? 0 : 2; // E -> N or S
      2: rot = turn_left ? 1 : 3; // S -> E or W
      3: rot = turn_left ? 2 : 0; // W -> S or N
      default: rot = -1;
    endcase
  endfunction

  // Convert direction index to wire
  function automatic void drive(output logic en, output logic val, input logic src_val);
    en = 1;
    val = src_val;
  endfunction

  int driverA, driverB, dstA, dstB, rel;

  always_comb begin
    out_en  = 4'b0000;
    out_val = 4'bxxxx;

    driverA = -1;
    driverB = -1;
    dstA    = -1;
    dstB    = -1;
    rel     = -1;

    if (drv_count == 1) begin
      // === SINGLE DRIVER ===
      // Forward value to all directions with _dvn = 1
      if (n_dve) begin
        if (e_dvn) drive(out_en[1], out_val[1], north);
        if (s_dvn) drive(out_en[2], out_val[2], north);
        if (w_dvn) drive(out_en[3], out_val[3], north);
      end else if (e_dve) begin
        if (n_dvn) drive(out_en[0], out_val[0], east);
        if (s_dvn) drive(out_en[2], out_val[2], east);
        if (w_dvn) drive(out_en[3], out_val[3], east);
      end else if (s_dve) begin
        if (n_dvn) drive(out_en[0], out_val[0], south);
        if (e_dvn) drive(out_en[1], out_val[1], south);
        if (w_dvn) drive(out_en[3], out_val[3], south);
      end else if (w_dve) begin
        if (n_dvn) drive(out_en[0], out_val[0], west);
        if (e_dvn) drive(out_en[1], out_val[1], west);
        if (s_dvn) drive(out_en[2], out_val[2], west);
      end
    end else if (drv_count == 2) begin
      // === TWO DRIVERS ===
      for (int i = 0; i < 4; i++) begin
        if (dir_dve[i]) begin
          if (driverA == -1) driverA = i;
          else driverB = i;
        end
      end

      // Determine destination directions
      if ((driverA + 2) % 4 == driverB) begin
        // === Opposite drivers ===
        dstA = rot(driverA, mode);
        dstB = rot(driverB, mode);
      end else begin
        // === Adjacent drivers ===
        if (mode == 0) begin
          dstA = (driverA + 2) % 4;
          dstB = (driverB + 2) % 4;
        end else begin
          rel = (driverA - driverB + 4) % 4;
          if (rel == 1) begin
            dstA = rot(driverA, 1); // A turns left
            dstB = rot(driverB, 0); // B turns right
          end else begin
            dstA = rot(driverA, 0); // A turns right
            dstB = rot(driverB, 1); // B turns left
          end
        end
      end

      drive(out_en[dstA], out_val[dstA], dir_val[driverA]);
      drive(out_en[dstB], out_val[dstB], dir_val[driverB]);
    end
  end


  // Tie outputs to inouts
  assign north = out_en[0] ? out_val[0] : 1'bz;
  assign east  = out_en[1] ? out_val[1] : 1'bz;
  assign south = out_en[2] ? out_val[2] : 1'bz;
  assign west  = out_en[3] ? out_val[3] : 1'bz;

endmodule
