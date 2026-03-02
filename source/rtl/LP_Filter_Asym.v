`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/28 10:39:33
// Design Name: 
// Module Name: LP_Filter_Asym
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


module LP_Filter_Asym(
    input clk,
    input reset_n,
    input lp_en,
    input [31:0] sig_i,
    output [31:0] sig_o
    );

    reg [38:0] y1 = 39'b0;
    reg [45:0] y2 = 46'b0;
    reg [52:0] y3 = 53'b0;
    reg [59:0] y4 = 60'b0;
    reg [66:0] y5 = 67'b0;
    wire [31:0] squid_filtered_w2;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            y1 <= 39'b0;
            y2 <= 46'b0;
            y3 <= 53'b0;
            y4 <= 60'b0;
            y5 <= 67'b0;
        end
        else begin
            if (lp_en) begin
                y1 <= y1 - {{7{y1[38]}},y1[38-:32]} + {{7{sig_i[31]}},sig_i};
                y2 <= y2 - {{7{y2[45]}},y2[45-:39]} + {{7{y1[38]}},y1};
                y3 <= y3 - {{7{y3[52]}},y3[52-:46]} + {{7{y2[45]}},y2};
                y4 <= y4 - {{7{y4[59]}},y4[59-:53]} + {{7{y3[52]}},y3};
                y5 <= y5 - {{7{y5[66]}},y5[66-:60]} + {{7{y4[59]}},y4}; 
            end
        end
    end
    assign sig_o = y5[66-:32];


endmodule
