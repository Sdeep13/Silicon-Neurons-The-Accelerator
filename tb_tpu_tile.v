`timescale 1ns/1ps
module tb_tpu_tile;
reg clk, rst, valid_in;
reg [511:0] M_flat;
reg [63:0] V_flat;
wire valid_out;
wire [191:0] Y_flat;

tpu_tile dut(
  .clk(clk), .rst(rst),
  .M_flat(M_flat), .V_flat(V_flat),
  .valid_in(valid_in),
  .valid_out(valid_out),
  .Y_flat(Y_flat)
);

initial clk = 0;
always #5 clk = ~clk;

integer k;

task fill_all;
  input [7:0] mv;
  input [7:0] vv;
  begin
    for(k=0;k<64;k=k+1) M_flat[k*8+:8] = mv;
    for(k=0;k<8;k=k+1)  V_flat[k*8+:8] = vv;
  end
endtask

task check_all;
  input [23:0] exp;
  input [8*20:1] lbl;
  integer e; reg ok;
  begin
    ok = 1;
    for(e=0;e<8;e=e+1)
      if(Y_flat[e*24+:24] !== exp) begin
        $display("FAIL [%0s] eng%0d got %0d exp %0d", lbl, e, Y_flat[e*24+:24], exp);
        ok = 0;
      end
    if(ok) $display("PASS [%0s] = %0d", lbl, exp);
    if(!valid_out) $display("FAIL [%0s] valid_out not high", lbl);
  end
endtask

initial begin
  $dumpfile("tpu_tile.vcd");
  $dumpvars(0, tb_tpu_tile);
  rst=1; valid_in=0; M_flat=0; V_flat=0;
  repeat(5) @(posedge clk); #1;
  rst = 0;
  repeat(2) @(posedge clk); #1;

  fill_all(0, 0);
  @(posedge clk); #1; valid_in=1;
  @(posedge clk); #1; valid_in=0;
  @(posedge clk);
  @(posedge clk); #1;
  check_all(24'd0, "ALL_ZEROS");

  repeat(2) @(posedge clk); #1;

  fill_all(1, 1);
  @(posedge clk); #1; valid_in=1;
  @(posedge clk); #1; valid_in=0;
  @(posedge clk);
  @(posedge clk); #1;
  check_all(24'd8, "ALL_ONES");

  repeat(2) @(posedge clk); #1;

  fill_all(255, 255);
  @(posedge clk); #1; valid_in=1;
  @(posedge clk); #1; valid_in=0;
  @(posedge clk);
  @(posedge clk); #1;
  check_all(24'd520200, "MAX_VALUE");

  $display("Simulation complete.");
  $finish;
end

initial begin #500000; $display("TIMEOUT"); $finish; end
endmodule
