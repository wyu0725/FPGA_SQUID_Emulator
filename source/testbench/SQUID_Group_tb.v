`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/29 15:20:19
// Design Name: 
// Module Name: SQUID_Group_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SQUID_Group_tb(

    );

    reg clk_100m = 1'b0;
    reg reset_n = 1'b0;
    wire solver2mem_wr_en_w;
    wire [15:0] solver2mem_addr_w;
    wire [15:0] solver2mem_data_w;
    reg [15:0] squid_bram_addr_i;
    wire [15:0] squid_bram_data_o;
    reg [39:0] cx_test = 40'h190900;
    reg [39:0] cy_test = 40'h190900;
    
    always #5 clk_100m = ~clk_100m;
    initial begin
        reset_n = 1'b0;
        #100;
        reset_n = 1'b1;
        #100;
        reset_n = 1'b1;
    end

    always @(posedge clk_100m or negedge reset_n) begin
        if (~reset_n) begin
            squid_bram_addr_i <= 16'b0;
        end
        else begin
            squid_bram_addr_i <= squid_bram_addr_i + 1'b1;
        end
    end

    SQUID_Group SQUID_Group_inst(
        .clk(clk_100m),
        .reset_n(reset_n),
        .squid_en_i(1'b1),

        // .ax_i(32'h0004A161),
        // .bx_i(32'h00029246),
        // .cx_i(32'h000073BB),
        // .dx_i(32'hFFFF8159),
        // .ex_i(32'h00003F53),
        // .fx_i(32'hFFFFA6DC),
        // .gx_i(32'hFFFFE68E),

        // .ay_i(32'h00029246),
        // .by_i(32'h0003A162),
        // .cy_i(32'h000069BC),
        // .dy_i(32'h00006AF9),
        // .ey_i(32'hFFFFCA83),
        // .fy_i(32'hFFFFE68E),
        // .gy_i(32'hFFFFB0C2),
        .ax_i(32'h0006A861),
        .bx_i(32'h00000001),
        .cx_i(cx_test[38-:32]),
        .dx_i(32'hFFFF2682),
        .ex_i(32'h00006CBF),
        .fx_i(32'hFFFF929F),
        .gx_i(32'h00000000),
  

        .ay_i(32'h00000001),
        .by_i(32'h0006A861),
        .cy_i(cy_test[38-:32]),
        .dy_i(32'h0000D97E),
        .ey_i(32'hFFFF9341),
        .fy_i(32'h00000000),
        .gy_i(32'hFFFF929F),


        .Vo_ratio_x_i(32'h2000),
        .Vo_ratio_y_i(32'h2000),

        .clk_sig_in(clk_100m),
        .phi_i(squid_bram_addr_i),
        .vo_o(squid_bram_data_o)

    );


endmodule
