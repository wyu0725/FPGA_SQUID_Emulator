`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/07 17:18:19
// Design Name: 
// Module Name: peak_cnt
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


module peak_cnt(
    input clk,
    input reset_n,
    input signed [31:0] data_i,
    input [6:0] state,

    output [23:0] peak_cnt_o
    );
    reg [23:0] peak_cnt_r = 24'b0;
    reg signed [31:0] VTH = 32'd200; // threshold

    reg signed [31:0] data_fifo_s1_r [5:1];
    reg signed [31:0] data_fifo_s2_r [5:1];
    reg signed [31:0] data_fifo_s3_r [5:1];
    reg signed [31:0] data_fifo_s4_r [5:1];
    reg signed [31:0] data_fifo_s5_r [5:1];
    reg signed [31:0] data_fifo_s6_r [5:1];

    // reg signed [31:0] data_max_r [6:1];
    // reg signed [31:0] data_min_r [6:1];

    reg [3:0] fresh_cnt_r [6:1];
    (*MARK_DEBUG = "true"*) reg [6:1] is_fresing_r = 6'b0;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            peak_cnt_r <= 24'd0;
            for (int i = 1; i <= 5;i++ ) begin
                data_fifo_s1_r[i] <= 32'd0;
                data_fifo_s2_r[i] <= 32'd0;
                data_fifo_s3_r[i] <= 32'd0;
                data_fifo_s4_r[i] <= 32'd0;
                data_fifo_s5_r[i] <= 32'd0;
                data_fifo_s6_r[i] <= 32'd0;
            end
            for (int i = 1; i <= 6;i++ ) begin
                fresh_cnt_r[i] <= 4'd0;
                is_fresing_r[i] <= 1'b0;
            end
        end
        else begin
            case (state)
                7'b0000010:begin
                    data_fifo_s1_r[5] <= data_fifo_s1_r[4];
                    data_fifo_s1_r[4] <= data_fifo_s1_r[3];
                    data_fifo_s1_r[3] <= data_fifo_s1_r[2];
                    data_fifo_s1_r[2] <= data_fifo_s1_r[1];
                    data_fifo_s1_r[1] <= data_i;
                    if ((data_fifo_s1_r[3] > data_fifo_s1_r[1]) && (data_fifo_s1_r[3] >= data_fifo_s1_r[5]) && data_fifo_s1_r[3] >= VTH && (~is_fresing_r[1])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[1] <= 1'b1;
                        fresh_cnt_r[1] <= fresh_cnt_r[1] + 1'b1;
                    end
                    else if (is_fresing_r[1] && (~(&fresh_cnt_r[1]))) begin
                        fresh_cnt_r[1] <= fresh_cnt_r[1] + 1'b1;
                    end
                    else if (&fresh_cnt_r[1]) begin
                        is_fresing_r[1] <= 1'b0;
                        fresh_cnt_r[1] <= 4'd0;
                    end
                end 
                7'b0000100:begin
                    data_fifo_s2_r[5] <= data_fifo_s2_r[4];
                    data_fifo_s2_r[4] <= data_fifo_s2_r[3];
                    data_fifo_s2_r[3] <= data_fifo_s2_r[2];
                    data_fifo_s2_r[2] <= data_fifo_s2_r[1];
                    data_fifo_s2_r[1] <= data_i;
                    if ((data_fifo_s2_r[3] > data_fifo_s2_r[1]) && (data_fifo_s2_r[3] >= data_fifo_s2_r[5]) && data_fifo_s2_r[3] >= VTH && (~is_fresing_r[2])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[2] <= 1'b1;
                        fresh_cnt_r[2] <= fresh_cnt_r[2] + 1'b1;
                    end
                    else if (is_fresing_r[2] && (~(&fresh_cnt_r[2]))) begin
                        fresh_cnt_r[2] <= fresh_cnt_r[2] + 1'b1;
                    end
                    else if (&fresh_cnt_r[2]) begin
                        is_fresing_r[2] <= 1'b0;
                        fresh_cnt_r[2] <= 4'd0;
                    end
                end
                7'b0001000:begin
                    data_fifo_s3_r[5] <= data_fifo_s3_r[4];
                    data_fifo_s3_r[4] <= data_fifo_s3_r[3];
                    data_fifo_s3_r[3] <= data_fifo_s3_r[2];
                    data_fifo_s3_r[2] <= data_fifo_s3_r[1];
                    data_fifo_s3_r[1] <= data_i;
                    if ((data_fifo_s3_r[3] > data_fifo_s3_r[1]) && (data_fifo_s3_r[3] >= data_fifo_s3_r[5]) && data_fifo_s3_r[3] >= VTH && (~is_fresing_r[3])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[3] <= 1'b1;
                        fresh_cnt_r[3] <= fresh_cnt_r[3] + 1'b1;
                    end
                    else if (is_fresing_r[3] && (~(&fresh_cnt_r[3]))) begin
                        fresh_cnt_r[3] <= fresh_cnt_r[3] + 1'b1;
                    end
                    else if (&fresh_cnt_r[3]) begin
                        is_fresing_r[3] <= 1'b0;
                        fresh_cnt_r[3] <= 4'd0;
                    end
                end
                7'b0010000:begin
                    data_fifo_s4_r[5] <= data_fifo_s4_r[4];
                    data_fifo_s4_r[4] <= data_fifo_s4_r[3];
                    data_fifo_s4_r[3] <= data_fifo_s4_r[2];
                    data_fifo_s4_r[2] <= data_fifo_s4_r[1];
                    data_fifo_s4_r[1] <= data_i;
                    if ((data_fifo_s4_r[3] > data_fifo_s4_r[1]) && (data_fifo_s4_r[3] >= data_fifo_s4_r[5]) && data_fifo_s4_r[3] >= VTH && (~is_fresing_r[4])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[4] <= 1'b1;
                        fresh_cnt_r[4] <= fresh_cnt_r[4] + 1'b1;
                    end
                    else if (is_fresing_r[4] && (~(&fresh_cnt_r[4]))) begin
                        fresh_cnt_r[4] <= fresh_cnt_r[4] + 1'b1;
                    end
                    else if (&fresh_cnt_r[4]) begin
                        is_fresing_r[4] <= 1'b0;
                        fresh_cnt_r[4] <= 4'd0;
                    end
                end
                7'b0100000:begin
                    data_fifo_s5_r[5] <= data_fifo_s5_r[4];
                    data_fifo_s5_r[4] <= data_fifo_s5_r[3];
                    data_fifo_s5_r[3] <= data_fifo_s5_r[2];
                    data_fifo_s5_r[2] <= data_fifo_s5_r[1];
                    data_fifo_s5_r[1] <= data_i;
                    if ((data_fifo_s5_r[3] > data_fifo_s5_r[1]) && (data_fifo_s5_r[3] >= data_fifo_s5_r[5]) && data_fifo_s5_r[3] >= VTH && (~is_fresing_r[5])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[5] <= 1'b1;
                        fresh_cnt_r[5] <= fresh_cnt_r[5] + 1'b1;
                    end
                    else if (is_fresing_r[5] && (~(&fresh_cnt_r[5]))) begin
                        fresh_cnt_r[5] <= fresh_cnt_r[5] + 1'b1;
                    end
                    else if (&fresh_cnt_r[5]) begin
                        is_fresing_r[5] <= 1'b0;
                        fresh_cnt_r[5] <= 4'd0;
                    end
                end
                7'b1000000:begin
                    data_fifo_s6_r[5] <= data_fifo_s6_r[4];
                    data_fifo_s6_r[4] <= data_fifo_s6_r[3];
                    data_fifo_s6_r[3] <= data_fifo_s6_r[2];
                    data_fifo_s6_r[2] <= data_fifo_s6_r[1]; 
                    data_fifo_s6_r[1] <= data_i;
                    if ((data_fifo_s6_r[3] > data_fifo_s6_r[1]) && (data_fifo_s6_r[3] >= data_fifo_s6_r[5]) && data_fifo_s6_r[3] >= VTH && (~is_fresing_r[6])) begin
                        peak_cnt_r <= peak_cnt_r + 1'b1;
                        is_fresing_r[6] <= 1'b1;
                        fresh_cnt_r[6] <= fresh_cnt_r[6] + 1'b1;
                    end
                    else if (is_fresing_r[6] && (~(&fresh_cnt_r[6]))) begin
                        fresh_cnt_r[6] <= fresh_cnt_r[6] + 1'b1;
                    end
                    else if (&fresh_cnt_r[6]) begin
                        is_fresing_r[6] <= 1'b0;
                        fresh_cnt_r[6] <= 4'd0;
                    end
                end
            endcase
        end
    end
    assign peak_cnt_o = peak_cnt_r;
endmodule
