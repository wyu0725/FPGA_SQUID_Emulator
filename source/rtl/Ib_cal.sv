`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/06 17:51:27
// Design Name: 
// Module Name: Ib_cal
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


module Ib_cal(
    input clk,
    input reset_n,
    input [15:0] Ib_i,
    input [31:0] cx_pre_i,
    input [31:0] cy_pre_i,

    output [39:0] cx_o,
    output [39:0] cy_o

    );

    Ib_mult X_Ib_inst (
        .CLK(clk),  // input wire CLK
        .A(cx_pre_i[23:0]),      // input wire [23 : 0] A
        .B(Ib_i),      // input wire [15 : 0] B
        .P(cx_o)      // output wire [39 : 0] P
    );

    Ib_mult Y_Ib_inst (
        .CLK(clk),  // input wire CLK
        .A(cy_pre_i[23:0]),      // input wire [23 : 0] A
        .B(Ib_i),      // input wire [15 : 0] B
        .P(cy_o)      // output wire [39 : 0] P
    );

endmodule
