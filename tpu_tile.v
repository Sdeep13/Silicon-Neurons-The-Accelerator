module tpu_tile (
    input  wire        clk,
    input  wire        rst,
    input  wire [511:0] M_flat,
    input  wire [63:0]  V_flat,
    input  wire         valid_in,
    output reg          valid_out,
    output reg  [191:0] Y_flat
);
    wire [7:0] M [0:7][0:7];
    wire [7:0] V [0:7];

    genvar r, c;
    generate
        for (r = 0; r < 8; r = r + 1)
            for (c = 0; c < 8; c = c + 1)
                assign M[r][c] = M_flat[(r*8+c)*8 +: 8];
        for (c = 0; c < 8; c = c + 1)
            assign V[c] = V_flat[c*8 +: 8];
    endgenerate

    reg [15:0] s1_prod [0:7][0:7];
    reg        s1_valid;

    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            s1_valid <= 0;
            for (i=0;i<8;i=i+1)
                for (j=0;j<8;j=j+1)
                    s1_prod[i][j] <= 0;
        end else begin
            s1_valid <= valid_in;
            for (i=0;i<8;i=i+1)
                for (j=0;j<8;j=j+1)
                    s1_prod[i][j] <= M[i][j] * V[j];
        end
    end

    wire [16:0] l1 [0:7][0:3];
    wire [17:0] l2 [0:7][0:1];

    generate
        for (r = 0; r < 8; r = r + 1) begin : atree
            assign l1[r][0] = s1_prod[r][0] + s1_prod[r][1];
            assign l1[r][1] = s1_prod[r][2] + s1_prod[r][3];
            assign l1[r][2] = s1_prod[r][4] + s1_prod[r][5];
            assign l1[r][3] = s1_prod[r][6] + s1_prod[r][7];
            assign l2[r][0] = l1[r][0] + l1[r][1];
            assign l2[r][1] = l1[r][2] + l1[r][3];
        end
    endgenerate

    reg [17:0] s2_sum [0:7][0:1];
    reg        s2_valid;

    always @(posedge clk) begin
        if (rst) begin
            s2_valid <= 0;
            for (i=0;i<8;i=i+1) begin
                s2_sum[i][0] <= 0;
                s2_sum[i][1] <= 0;
            end
        end else begin
            s2_valid <= s1_valid;
            for (i=0;i<8;i=i+1) begin
                s2_sum[i][0] <= l2[i][0];
                s2_sum[i][1] <= l2[i][1];
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 0;
            Y_flat    <= 0;
        end else begin
            valid_out <= s2_valid;
            for (i=0;i<8;i=i+1)
                Y_flat[i*24 +: 24] <= s2_sum[i][0] + s2_sum[i][1];
        end
    end

endmodule
