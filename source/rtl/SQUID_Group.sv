`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/29 14:38:38
// Design Name: 
// Module Name: SQUID_Group
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


module SQUID_Group(
        input clk,
        input reset_n,
        input squid_en_i,

        input [31:0] ax_i,
        input [31:0] bx_i,
        (*MARK_DEBUG = "true"*) input [31:0] cx_i,
        input [31:0] dx_i,
        input [31:0] ex_i,
        input [31:0] fx_i,
        input [31:0] gx_i,

        input [31:0] ay_i,
        input [31:0] by_i,
        input [31:0] cy_i,
        input [31:0] dy_i,
        input [31:0] ey_i,
        input [31:0] fy_i,
        input [31:0] gy_i,

        input [31:0] Vo_ratio_x_i,
        input [31:0] Vo_ratio_y_i,

        input clk_sig_in,
        input [15:0] phi_i,
        input [15:0] phi_in_valid_i,
        output vo_valid_o,
        output [15:0] vo_o
    );

    reg [6:1] squid_unit_en_r = 6'b0000;
    localparam IDLE = 7'b0000001; 
    localparam S1   = 7'b0000010; 
    localparam S2   = 7'b0000100; 
    localparam S3   = 7'b0001000; 
    localparam S4   = 7'b0010000; 
    localparam S5   = 7'b0100000; 
    localparam S6   = 7'b1000000; 
    reg [6:0] state = IDLE;
    reg [15:0] solve_cnt_r = 16'd0;
    reg [6:1] vo_sel_flag = 6'b100000;
    reg [6:1] vo_sel_flag_delay = 6'b100000;
    wire [6:1] done_w;
    reg [6:1] done_r = 6'b0;
    reg [15:0] vo_sel_r = 16'd0;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            state <= IDLE;
            solve_cnt_r <= 16'd0;
        end
        else begin
            case (state)
                IDLE:begin
                    if (squid_en_i) begin
                        state <= S1;
                    end
                    else begin
                        state <= IDLE;
                    end
                    solve_cnt_r <= 16'd0;
                    squid_unit_en_r <= 6'b000000;
                end
                S1:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S2;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S1;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[1] <= 1'b1;
                end
                S2:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S3;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S2;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[2] <= 1'b1;
                end
                S3:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S4;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S3;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[3] <= 1'b1;
                end
                S4:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S5;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S4;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[4] <= 1'b1;
                end
                S5:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S6;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S5;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[5] <= 1'b1;
                end
                S6:begin
                    if (solve_cnt_r == 16'd12971) begin
                        state <= S1;
                        solve_cnt_r <= 16'd0;
                    end
                    else begin
                        state <= S6;
                        solve_cnt_r <= solve_cnt_r + 16'd1;
                    end
                    squid_unit_en_r[6] <= 1'b1;
                end
                default: begin
                    state <= IDLE;
                    solve_cnt_r <= 16'd0;
                    squid_unit_en_r <= 4'b0000;
                end
            endcase
        end
    end

    reg [31:0] ax_r [6:1];
    reg [31:0] bx_r [6:1];
    reg [31:0] cx_r [6:1];
    reg [31:0] dx_r [6:1];
    reg [31:0] ex_r [6:1];
    reg [31:0] fx_r [6:1];
    reg [31:0] gx_r [6:1];

    reg [31:0] ay_r [6:1];
    reg [31:0] by_r [6:1];
    reg [31:0] cy_r [6:1];
    reg [31:0] dy_r [6:1];
    reg [31:0] ey_r [6:1];
    reg [31:0] fy_r [6:1];
    reg [31:0] gy_r [6:1];

    reg [31:0] Vo_ratio_x_r[6:1];
    reg [31:0] Vo_ratio_y_r[6:1];

    reg [15:0] phi_in_r[6:1];
    reg [15:0] phi_in_r2[6:1];
    reg [6:1] phi_in_valid_sync_r;
    reg [6:1] phi_in_valid_sync_r2;
    wire [6:1] vo_valid_w;
    wire [15:0] vo_w[6:1];

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            for(integer i = 1;i <= 6;i=i+1)begin
                ax_r[i] <= 32'd0;
                bx_r[i] <= 32'd0;
                cx_r[i] <= 32'd0;
                dx_r[i] <= 32'd0;
                ex_r[i] <= 32'd0;
                fx_r[i] <= 32'd0;
                gx_r[i] <= 32'd0;

                ay_r[i] <= 32'd0;
                by_r[i] <= 32'd0;
                cy_r[i] <= 32'd0;
                dy_r[i] <= 32'd0;
                ey_r[i] <= 32'd0;
                fy_r[i] <= 32'd0;
                gy_r[i] <= 32'd0;

                Vo_ratio_x_r[i] <= 32'd0;
                Vo_ratio_y_r[i] <= 32'd0;

                phi_in_r[i] <= 16'd0;
                phi_in_r2[i] <= 16'b0;
                phi_in_valid_sync_r[i] <= 16'b0;
                phi_in_valid_sync_r2[i] <= 16'b0;
            end
        end
        else begin
            for(integer i = 1;i <= 6;i=i+1)begin
                ax_r[i] <= ax_i;
                bx_r[i] <= bx_i;
                cx_r[i] <= cx_i;
                dx_r[i] <= dx_i;
                ex_r[i] <= ex_i;
                fx_r[i] <= fx_i;
                gx_r[i] <= gx_i;

                ay_r[i] <= ay_i;
                by_r[i] <= by_i;
                cy_r[i] <= cy_i;
                dy_r[i] <= dy_i;
                ey_r[i] <= ey_i;
                fy_r[i] <= fy_i;
                gy_r[i] <= gy_i;

                Vo_ratio_x_r[i] <= Vo_ratio_x_i;
                Vo_ratio_y_r[i] <= Vo_ratio_y_i;

                phi_in_r[i] <= phi_i;
                phi_in_r2[i] <= phi_in_r[i];
                phi_in_valid_sync_r[i] <= phi_in_valid_i;
                phi_in_valid_sync_r2[i] <= phi_in_valid_sync_r[i];
            end
        end
    end

    genvar j;
    generate for(j = 1; j < 7; j = j + 1) begin:squid_group

        SQUID_Unit SQUID_Unit_inst(
            .clk(clk),
            .reset_n(reset_n),
            .squid_en_i(squid_unit_en_r[j]),

            .ax_i(ax_r[j]),
            .bx_i(bx_r[j]),
            .cx_i(cx_r[j]),
            .dx_i(dx_r[j]),
            .ex_i(ex_r[j]),
            .fx_i(fx_r[j]),
            .gx_i(gx_r[j]),

            .ay_i(ay_r[j]),
            .by_i(by_r[j]),
            .cy_i(cy_r[j]),
            .dy_i(dy_r[j]),
            .ey_i(ey_r[j]),
            .fy_i(fy_r[j]),
            .gy_i(gy_r[j]),
            
            .Vo_ratio_x_i(Vo_ratio_x_r[j]),
            .Vo_ratio_y_i(Vo_ratio_y_r[j]),

            .clk_sig_in(clk_sig_in),
            .phi_i(phi_in_r2[j]),
            .phi_in_valid_i(phi_in_valid_sync_r2[j]),
            .vo_valid_o(vo_valid_w[j]),
            .vo_o(vo_w[j]),

            .done_o(done_w[j])
        );
    end
    endgenerate
    
    reg [15:0] vo_r [6:1];

    always @(posedge clk_sig_in or negedge reset_n) begin
        if (~reset_n) begin
            for(integer i = 1;i <= 6;i=i+1)begin
                vo_r[i] <= 16'd0;
            end
        end
        else begin
            for(integer i = 1;i <= 6;i=i+1)begin
                vo_r[i] <= vo_w[i];
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            done_r <= 4'b0;
        end
        else begin
            for(integer i = 1;i <= 6;i=i+1)begin
                done_r[i] <= done_w[i];
            end
        end
    end
    

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            vo_sel_flag <= 6'b100000;
            vo_sel_flag_delay <= 6'b100000;
        end
        else begin
            if (|done_r) begin
               vo_sel_flag <= {vo_sel_flag[5:1],vo_sel_flag[6]}; 
            end
            vo_sel_flag_delay <= vo_sel_flag;
        end
    end


    always @(posedge clk_sig_in or negedge reset_n) begin
        if (~reset_n) begin
            vo_sel_r <= 16'd0;
        end
        else begin
            case (vo_sel_flag_delay)
                6'b000001: vo_sel_r <= vo_r[1];
                6'b000010: vo_sel_r <= vo_r[2];
                6'b000100: vo_sel_r <= vo_r[3];
                6'b001000: vo_sel_r <= vo_r[4];
                6'b010000: vo_sel_r <= vo_r[5];
                6'b100000: vo_sel_r <= vo_r[6];
                default: vo_sel_r <= 16'd0;
            endcase
        end
    end

    reg vo_valid_sync_r1 = 1'b0;
    reg vo_valid_sync_r2 = 1'b0;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            vo_valid_sync_r1 <= 1'b0;
            vo_valid_sync_r2 <= 1'b0;
        end
        else begin
            vo_valid_sync_r1 <= vo_valid_w[6];
            vo_valid_sync_r2 <= vo_valid_sync_r1;
        end
    end
    assign vo_valid_o = vo_valid_sync_r2;
    assign vo_o = vo_sel_r;

endmodule
