module mac_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [15:0] product
);
    always @(posedge clk) begin
        if (rst) product <= 16'd0;
        else     product <= a * b;
    end
endmodule
