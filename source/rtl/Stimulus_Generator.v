`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/28 14:01:24
// Design Name: 
// Module Name: Stimulus_Generator
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


module Stimulus_Generator#(
        parameter SEG_NUM = 6
)(
        input clk,
        input reset_n,
        output ram_flag_o,
        output [31:0] sig_seg1_o,
        output [31:0] sig_seg2_o,
        output [31:0] sig_seg3_o,
        output [31:0] sig_seg4_o,
        output [31:0] sig_seg5_o,
        output [31:0] sig_seg6_o
    );

    parameter TOTOAL = 17'd65536;
    parameter SEG_LENGTH = TOTOAL / SEG_NUM;
    parameter EXTEND = 2048;

    parameter SEG1_START = 0 * SEG_LENGTH;
    parameter SEG2_START = 1 * SEG_LENGTH;
    parameter SEG3_START = 2 * SEG_LENGTH;
    parameter SEG4_START = 3 * SEG_LENGTH;
    parameter SEG5_START = 4 * SEG_LENGTH;
    parameter SEG6_START = 5 * SEG_LENGTH;

    parameter SEG1_END = 1 * SEG_LENGTH + EXTEND;
    parameter SEG2_END = 2 * SEG_LENGTH + EXTEND;
    parameter SEG3_END = 3 * SEG_LENGTH + EXTEND;
    parameter SEG4_END = 4 * SEG_LENGTH + EXTEND;
    parameter SEG5_END = 5 * SEG_LENGTH + EXTEND;
    parameter SEG6_END = TOTOAL + EXTEND;


    reg [16:0] sig_r [6:1];
    reg [6:1] sig_out_order_r = 6'b000001;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            sig_out_order_r <= 6'b000001;
            sig_r[1] <= SEG1_START;
            sig_r[2] <= SEG2_START;
            sig_r[3] <= SEG3_START;
            sig_r[4] <= SEG4_START;
            sig_r[5] <= SEG5_START;
            sig_r[6] <= SEG6_START;
        end
        else begin
            if (sig_r[6] <= SEG6_END) begin
                sig_out_order_r <= {sig_out_order_r[5:1], sig_out_order_r[6]};
                case (sig_out_order_r)
                    6'b000001:sig_r[1] <= sig_r[1] + 17'b1;
                    6'b000010:sig_r[2] <= sig_r[2] + 17'b1;
                    6'b000100:sig_r[3] <= sig_r[3] + 17'b1;
                    6'b001000:sig_r[4] <= sig_r[4] + 17'b1;
                    6'b010000:sig_r[5] <= sig_r[5] + 17'b1;
                    6'b100000:sig_r[6] <= sig_r[6] + 17'b1;
                    default: ;
                endcase
            end
            else begin
            end
        end
    end

    assign sig_seg1_o = {12'b0, sig_r[1], 3'b0}; // Extend to 32 bits
    assign sig_seg2_o = {12'b0, sig_r[2], 3'b0};
    assign sig_seg3_o = {12'b0, sig_r[3], 3'b0};
    assign sig_seg4_o = {12'b0, sig_r[4], 3'b0};
    assign sig_seg5_o = {12'b0, sig_r[5], 3'b0};  
    assign sig_seg6_o = {12'b0, sig_r[6], 3'b0};
    assign ram_flag_o = (sig_r[1] > (EXTEND - 1) && sig_r[6] <= SEG6_END);

endmodule
