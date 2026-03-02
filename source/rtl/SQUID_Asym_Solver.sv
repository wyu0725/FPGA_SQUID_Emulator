`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/27 09:30:17
// Design Name: 
// Module Name: SQUID_Asym_Solver
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


module SQUID_Asym_Solver(
    input clk,
    input reset_n,
    input start_en_i,
    input [31:0] ax_i,
    input [31:0] bx_i,
    input [31:0] cx_i,
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

    output [14:0] ram_addr_o,
    output [15:0] ram_data_o,
    output ram_wr_en_o,

    output is_pulse_o,
    output done_o
    );

    localparam IDLE = 7'b0000001; // IDLE
    localparam S1 = 7'b0000010; // 计算周期1
    localparam S2 = 7'b0000100; // 计算周期2
    localparam S3 = 7'b0001000; // 计算周期3
    localparam S4 = 7'b0010000; // 计算周期4
    localparam S5 = 7'b0100000; // 计算周期5
    localparam S6 = 7'b1000000; // 计算周期6
    reg [6:0] state = IDLE;

    reg [23:0] ax_r = 24'b0;
    reg [23:0] bx_r = 24'b0;
    reg [31:0] cx_r = 32'b0;
    reg [23:0] dx_r = 24'b0;
    reg [23:0] ex_r = 24'b0;
    reg [23:0] fx_r = 24'b0;
    reg [23:0] gx_r = 24'b0;

    reg [23:0] ay_r = 24'b0;
    reg [23:0] by_r = 24'b0;
    reg [31:0] cy_r = 32'b0;
    reg [23:0] dy_r = 24'b0;
    reg [23:0] ey_r = 24'b0;
    reg [23:0] fy_r = 24'b0;
    reg [23:0] gy_r = 24'b0;

    reg [31:0] phi_in_r = 32'b0;
    wire [31:0] phi_in_seg_w[6:1];

    reg [31:0] theta1_list_r [1:6];
    reg [31:0] theta2_list_r [1:6];
    reg [31:0] Vo_list_r [1:6];
    wire [31:0] Vo_filtered_w [1:6];
    reg [6:1] lp_filter_en_r = 6'b0;

    reg [31:0] x_r = 32'b0;
    reg [31:0] y_r = 32'b0;
    reg [31:0] theta1_r = 32'b0;
    reg [31:0] theta2_r = 32'b0;
    wire [31:0] sin_theta1_w;
    wire [31:0] sin_theta2_w;
    wire [16:0] reduced_theta1_w;
    wire [16:0] reduced_theta2_w;
    wire [31:0] x_next_w;
    wire [31:0] y_next_w;
    wire [31:0] Vo_w;



    reg [5:1] cal_stage_en_r = 5'b0;
    reg [23:0] Vo_ratio_x_r = 24'b0;
    reg [23:0] Vo_ratio_y_r = 24'b0;

    reg [31:0] squid_vout_r = 32'b0;

    reg [15:0] squid_ram_addr_r = 16'b0;
    reg [15:0] squid_ram_data_r = 16'b0;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            ax_r <= 24'b0;
            bx_r <= 24'b0;
            cx_r <= 32'b0;
            dx_r <= 24'b0;
            ex_r <= 24'b0;
            fx_r <= 24'b0;
            gx_r <= 24'b0;

            ay_r <= 24'b0;
            by_r <= 24'b0;
            cy_r <= 32'b0;
            dy_r <= 24'b0;
            ey_r <= 24'b0;
            fy_r <= 24'b0;
            gy_r <= 24'b0;

            Vo_ratio_x_r <= 24'b0;
            Vo_ratio_y_r <= 24'b0;
        end
        else begin
            if (state == IDLE) begin
                ax_r <= ax_i[23:0];
                bx_r <= bx_i[23:0];
                cx_r <= cx_i;
                dx_r <= dx_i[23:0];
                ex_r <= ex_i[23:0];
                fx_r <= fx_i[23:0];
                gx_r <= gx_i[23:0];

                ay_r <= ay_i[23:0];
                by_r <= by_i[23:0];
                cy_r <= cy_i;
                dy_r <= dy_i[23:0];
                ey_r <= ey_i[23:0];
                fy_r <= fy_i[23:0];
                gy_r <= gy_i[23:0];

                Vo_ratio_x_r <= Vo_ratio_x_i[23:0];
                Vo_ratio_y_r <= Vo_ratio_y_i[23:0];
            end
        end
    end


//******************state machine ctrl*************************//
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            state <= IDLE;
            cal_stage_en_r <= 5'b0;
            x_r <= 32'b0;
            y_r <= 32'b0;
            theta1_r <= 32'b0;
            theta2_r <= 32'b0;
            for(integer i = 1;i <= 6;i=i+1)begin
                theta1_list_r[i] <= 32'b0;
                theta2_list_r[i] <= 32'b0;
                Vo_list_r[i] <= 32'b0;
            end
            phi_in_r <= 32'b0;
            lp_filter_en_r <= 6'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start_en_i) begin
                        state <= S1;
                        cal_stage_en_r <= 5'b00000;
                    end
                    else begin
                        state <= IDLE;
                        cal_stage_en_r <= 5'b0;
                        x_r <= 32'b0;
                        y_r <= 32'b0;
                        theta1_r <= 32'b0;
                        theta2_r <= 32'b0;
                        for(integer i = 1;i <= 6;i=i+1)begin
                            theta1_list_r[i] <= 32'b0;
                            theta2_list_r[i] <= 32'b0;
                        end
                        phi_in_r <= 32'b0;
                        lp_filter_en_r <= 6'b0;
                    end
                end
                S1: begin
                    state <= S2;
                    cal_stage_en_r[1] <= 1'b1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[1] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[1] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[1] <= theta1_list_r[1] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[1] <= theta2_list_r[1] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[1];
                    Vo_list_r[4] <= Vo_w;
                    lp_filter_en_r <= 6'b001000;
                end
                S2: begin
                    state <= S3;
                    cal_stage_en_r[2] <= 1'b1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[2] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[2] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[2] <= theta1_list_r[2] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[2] <= theta2_list_r[2] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[2];
                    Vo_list_r[5] <= Vo_w;
                    lp_filter_en_r <= 6'b010000;
                end
                S3: begin
                    state <= S4;
                    cal_stage_en_r[3] <= 1'b1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[3] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[3] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[3] <= theta1_list_r[3] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[3] <= theta2_list_r[3] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[3];
                    Vo_list_r[6] <= Vo_w;
                    lp_filter_en_r <= 6'b100000;
                end
                S4: begin
                    state <= S5;
                    cal_stage_en_r[4] <= 1'b1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[4] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[4] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[4] <= theta1_list_r[4] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[4] <= theta2_list_r[4] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[4];
                    Vo_list_r[1] <= Vo_w;
                    lp_filter_en_r <= 6'b000001;
                end
                S5: begin
                    state <= S6;
                    cal_stage_en_r[5] <= 1'b1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[5] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[5] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[5] <= theta1_list_r[5] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[5] <= theta2_list_r[5] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[5];
                    Vo_list_r[2] <= Vo_w;
                    lp_filter_en_r <= 6'b000010;
                end
                S6: begin
                    state <= S1;
                    x_r <= x_next_w;
                    y_r <= y_next_w;
                    theta1_r <= theta1_list_r[6] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_r <= theta2_list_r[6] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    theta1_list_r[6] <= theta1_list_r[6] + {{3{x_next_w[31]}}, x_next_w[31:3]};
                    theta2_list_r[6] <= theta2_list_r[6] + {{3{y_next_w[31]}}, y_next_w[31:3]};
                    phi_in_r <= phi_in_seg_w[6];
                    Vo_list_r[3] <= Vo_w;
                    lp_filter_en_r <= 6'b000100;
                end
                default: begin
                    state <= IDLE;
                    cal_stage_en_r <= 5'b0;
                end
            endcase
        end
    end

//******************x_next_w calculate*************************//
//******************stage1*********************//
    //****************a:ax*x************//
    wire [55:0] x_stage1_a_term_temp;
    wire [31:0] x_stage1_a_term;
    mult_rcsj mult_x_stage1_a_inst (
        .CLK(clk),  // input wire CLK
        .A(x_r),      // input wire [31 : 0] A
        .B(ax_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage1_a_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage1_a_term = x_stage1_a_term_temp[50:19];

    //****************b:bx*y************//
    wire [55:0] x_stage1_b_term_temp;
    wire [31:0] x_stage1_b_term;
    mult_rcsj mult_x_stage1_b_inst (
        .CLK(clk),  // input wire CLK
        .A(y_r),      // input wire [31 : 0] A
        .B(bx_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage1_b_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage1_b_term = x_stage1_b_term_temp[50:19];

    //****************c:cx******************//

    //****************d:dx * phi************//
    wire [55:0] x_stage1_d_term_temp;
    wire [31:0] x_stage1_d_term;
    mult_rcsj mult_x_stage1_d_inst (
        .CLK(clk),  // input wire CLK
        .A(phi_in_r),      // input wire [31 : 0] A
        .B(dx_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage1_d_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage1_d_term = x_stage1_d_term_temp[50:19];

    //********e: theta2 - theta1************//
    wire [31:0] theta2_sub_tehta1_w;
    sub_rcsj sub_x_stage1_e_inst (
        .A(theta2_r),      // input wire [31 : 0] A
        .B(theta1_r),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),
        .S(theta2_sub_tehta1_w)      // output wire [31 : 0] S
    );

    //****************f:sin(theta1)************//
    //****************g:sin(theta2)************//

//******************stage2*********************//
    //****************a:ax*x + bx*y************//
    //****************b:ax*x + bx*y************//
    wire [31:0] x_stage2_ab_term_w;
    add_rcsj add_x_stage2_ab_inst (
        .A(x_stage1_a_term),      // input wire [31 : 0] A
        .B(x_stage1_b_term),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage2_ab_term_w)      // output wire [31 : 0] S
    );

    //****************c:cx + dx*phi************//
    //****************d:cx + dx*phi************//
    wire [31:0] x_stage2_cd_term_w;
    add_rcsj add_x_stage2_cd_inst (
        .A(cx_r),      // input wire [31 : 0] A
        .B(x_stage1_d_term),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage2_cd_term_w)      // output wire [31 : 0] S
    );

    //****************e:ex * (theta2 - theta1)************//
    wire [55:0] x_stage2_e_term_temp;
    wire [31:0] x_stage2_e_term;
    mult_rcsj mult_x_stage2_e_inst (
        .CLK(clk),  // input wire CLK
        .A(theta2_sub_tehta1_w),      // input wire [31 : 0] A
        .B(ex_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage2_e_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage2_e_term = x_stage2_e_term_temp[50:19];

    //********************f:sin(theta1)********************//
    //********************g:sin(theta2)********************//

//******************stage3*********************//
    //**********a:ax*x + bx*y + cx + dx*phi**********//
    //**********b:ax*x + bx*y + cx + dx*phi**********//
    //**********c:ax*x + bx*y + cx + dx*phi**********//
    //**********d:ax*x + bx*y + cx + dx*phi**********//
    wire [31:0] x_stage3_abcd_term_w;
    add_rcsj add_x_stage3_abcd_inst (
        .A(x_stage2_ab_term_w),      // input wire [31 : 0] A
        .B(x_stage2_cd_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage3_abcd_term_w)      // output wire [31 : 0] S
    );
    //********e:ex * (theta2 - theta1) one stage pipe *****//
    reg [31:0] x_stage3_e_term_r = 32'b0;
    wire [31:0] x_stage3_e_term_w;
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            x_stage3_e_term_r <= 32'b0;
        end
        else begin
            x_stage3_e_term_r <= x_stage2_e_term;
        end
    end
    assign x_stage3_e_term_w = x_stage3_e_term_r;

    //********f:fx * sin(theta1) **********//
    wire [55:0] x_stage3_f_term_temp;
    wire [31:0] x_stage3_f_term_w;
    mult_rcsj mult_x_stage3_f_inst (
        .CLK(clk),  // input wire CLK
        .A(sin_theta1_w),      // input wire [31 : 0] A
        .B(fx_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage3_f_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage3_f_term_w = x_stage3_f_term_temp[50:19];

    //********g:gx * sin(theta2) **********//
    wire [55:0] x_stage3_g_term_temp;
    wire [31:0] x_stage3_g_term_w;
    mult_rcsj mult_x_stage3_g_inst (
        .CLK(clk),  // input wire CLK
        .A(sin_theta2_w),      // input wire [31 : 0] A
        .B(gx_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(x_stage3_g_term_temp)      // output wire [55 : 0] P
    );
    assign x_stage3_g_term_w = x_stage3_g_term_temp[50:19];

//******************stage4*********************//
    //**********a:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) **********//
    //**********b:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) **********//
    //**********c:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) **********//
    //**********d:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) **********//
    //**********e:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) **********//
    wire [31:0] x_stage4_abcde_term_w;
    add_rcsj add_x_stage4_abcd_inst (
        .A(x_stage3_abcd_term_w),      // input wire [31 : 0] A
        .B(x_stage3_e_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[4]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage4_abcde_term_w)      // output wire [31 : 0] S
    );

    //********f:fx * sin(theta1) + gx * sin(theta2) **********//
    //********g:fx * sin(theta1) + gx * sin(theta2) **********//
    wire [31:0] x_stage4_fg_term_w;
    add_rcsj add_x_stage4_fg_inst (
        .A(x_stage3_f_term_w),      // input wire [31 : 0] A
        .B(x_stage3_g_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[4]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage4_fg_term_w)      // output wire [31 : 0] S
    );

//******************stage5*********************//
    //**********a:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********b:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********c:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********d:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********e:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********f:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    //**********g:ax*x + bx*y + cx + dx*phi + ex*(theta2 - theta1) + fx*sin(theta1) + gx * sin(theta2)**********//
    wire [31:0] x_stage5_abcdefg_term_w;
    add_rcsj add_x_stage4_abcdefg_inst (
        .A(x_stage4_abcde_term_w),      // input wire [31 : 0] A
        .B(x_stage4_fg_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[5]),    // input wire CE
        .SCLR(~reset_n),
        .S(x_stage5_abcdefg_term_w)      // output wire [31 : 0] S
    );
    assign x_next_w = x_stage5_abcdefg_term_w;


//******************y_next_w calculate*************************//
//******************stage1*********************//
    //****************a:ay*x************//
    wire [55:0] y_stage1_a_term_temp;
    wire [31:0] y_stage1_a_term;
    mult_rcsj mult_y_stage1_a_inst (
        .CLK(clk),  // input wire CLK
        .A(x_r),      // input wire [31 : 0] A
        .B(ay_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage1_a_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage1_a_term = y_stage1_a_term_temp[50:19];

    //****************b:by*y************//
    wire [55:0] y_stage1_b_term_temp;
    wire [31:0] y_stage1_b_term;
    mult_rcsj mult_y_stage1_b_inst (
        .CLK(clk),  // input wire CLK
        .A(y_r),      // input wire [31 : 0] A
        .B(by_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage1_b_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage1_b_term = y_stage1_b_term_temp[50:19];

    //****************c:cy******************//

    //****************d:dy * phi************//
    wire [55:0] y_stage1_d_term_temp;
    wire [31:0] y_stage1_d_term;
    mult_rcsj mult_y_stage1_d_inst (
        .CLK(clk),  // input wire CLK
        .A(phi_in_r),      // input wire [31 : 0] A
        .B(dy_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage1_d_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage1_d_term = y_stage1_d_term_temp[50:19];

    //********e: theta2 - theta1 done***********//

    //****************f:sin(theta1)************//
    //****************g:sin(theta2)************//

//******************stage2*********************//
    //****************a:ay*x + by*y************//
    //****************b:ay*x + by*y************//
    wire [31:0] y_stage2_ab_term_w;
    add_rcsj add_y_stage2_ab_inst (
        .A(y_stage1_a_term),      // input wire [31 : 0] A
        .B(y_stage1_b_term),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage2_ab_term_w)      // output wire [31 : 0] S
    );

    //****************c:cy + dy*phi************//
    //****************d:cy + dy*phi************//
    wire [31:0] y_stage2_cd_term_w;
    add_rcsj add_y_stage2_cd_inst (
        .A(cy_r),      // input wire [31 : 0] A
        .B(y_stage1_d_term),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage2_cd_term_w)      // output wire [31 : 0] S
    );

    //****************e:ey * (theta2 - theta1)************//
    wire [55:0] y_stage2_e_term_temp;
    wire [31:0] y_stage2_e_term;
    mult_rcsj mult_y_stage2_e_inst (
        .CLK(clk),  // input wire CLK
        .A(theta2_sub_tehta1_w),      // input wire [31 : 0] A
        .B(ey_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage2_e_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage2_e_term = y_stage2_e_term_temp[50:19];

    //********************f:sin(theta1)********************//
    //********************g:sin(theta2)********************//

//******************stage3*********************//
    //**********a:ay*x + by*y + cy + dy*phi**********//
    //**********b:ay*x + by*y + cy + dy*phi**********//
    //**********c:ay*x + by*y + cy + dy*phi**********//
    //**********d:ay*x + by*y + cy + dy*phi**********//
    wire [31:0] y_stage3_abcd_term_w;
    add_rcsj add_y_stage3_abcd_inst (
        .A(y_stage2_ab_term_w),      // input wire [31 : 0] A
        .B(y_stage2_cd_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage3_abcd_term_w)      // output wire [31 : 0] S
    );
    //********e:ey * (theta2 - theta1) one stage pipe *****//
    reg [31:0] y_stage3_e_term_r = 32'b0;
    wire [31:0] y_stage3_e_term_w;
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            y_stage3_e_term_r <= 32'b0;
        end
        else begin
            y_stage3_e_term_r <= y_stage2_e_term;
        end
    end
    assign y_stage3_e_term_w = y_stage3_e_term_r;

    //********f:fy * sin(theta1) **********//
    wire [55:0] y_stage3_f_term_temp;
    wire [31:0] y_stage3_f_term_w;
    mult_rcsj mult_y_stage3_f_inst (
        .CLK(clk),  // input wire CLK
        .A(sin_theta1_w),      // input wire [31 : 0] A
        .B(fy_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage3_f_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage3_f_term_w = y_stage3_f_term_temp[50:19];

    //********g:gy * sin(theta2) **********//
    wire [55:0] y_stage3_g_term_temp;
    wire [31:0] y_stage3_g_term_w;
    mult_rcsj mult_y_stage3_g_inst (
        .CLK(clk),  // input wire CLK
        .A(sin_theta2_w),      // input wire [31 : 0] A
        .B(gy_r),      // input wire [23 : 0] B
        .CE(cal_stage_en_r[3]),    // input wire CE
        .SCLR(~reset_n),  // input wire SCLR
        .P(y_stage3_g_term_temp)      // output wire [55 : 0] P
    );
    assign y_stage3_g_term_w = y_stage3_g_term_temp[50:19];

//******************stage4*********************//
    //**********a:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) **********//
    //**********b:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) **********//
    //**********c:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) **********//
    //**********d:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) **********//
    //**********e:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) **********//
    wire [31:0] y_stage4_abcde_term_w;
    add_rcsj add_y_stage4_abcd_inst (
        .A(y_stage3_abcd_term_w),      // input wire [31 : 0] A
        .B(y_stage3_e_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[4]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage4_abcde_term_w)      // output wire [31 : 0] S
    );

    //********f:fy * sin(theta1) + gy * sin(theta2) **********//
    //********g:fy * sin(theta1) + gy * sin(theta2) **********//
    wire [31:0] y_stage4_fg_term_w;
    add_rcsj add_y_stage4_fg_inst (
        .A(y_stage3_f_term_w),      // input wire [31 : 0] A
        .B(y_stage3_g_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[4]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage4_fg_term_w)      // output wire [31 : 0] S
    );

//******************stage5*********************//
    //**********a:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********b:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********c:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********d:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********e:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********f:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    //**********g:ay*x + by*y + cy + dy*phi + ey*(theta2 - theta1) + fy*sin(theta1) + gy * sin(theta2)**********//
    wire [31:0] y_stage5_abcdefg_term_w;
    add_rcsj add_y_stage4_abcdefg_inst (
        .A(y_stage4_abcde_term_w),      // input wire [31 : 0] A
        .B(y_stage4_fg_term_w),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[5]),    // input wire CE
        .SCLR(~reset_n),
        .S(y_stage5_abcdefg_term_w)      // output wire [31 : 0] S
    );
    assign y_next_w = y_stage5_abcdefg_term_w;
//**********************************sin calculation********************************//

    reg [16:0] reduced_theta1_r_delay = 17'b0;
    reg [16:0] reduced_theta2_r_delay = 17'b0;
    wire [16:0] sin_theta1_w_temp;
    wire [16:0] sin_theta2_w_temp;

    assign reduced_theta1_w = theta1_r[19:3];
    assign reduced_theta2_w = theta2_r[19:3];

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            reduced_theta1_r_delay <= 17'b0;
            reduced_theta2_r_delay <= 17'b0;
        end 
        else begin
            reduced_theta1_r_delay <= reduced_theta1_w;
            reduced_theta2_r_delay <= reduced_theta2_w;
        end
    end 

    

    rcsj_sin_rom sin_rom_inst (
        .clka(clk),
        .addra(reduced_theta1_w[15:0]),
        .douta(sin_theta1_w_temp),
        .clkb(clk),
        .addrb(reduced_theta2_w[15:0]),
        .doutb(sin_theta2_w_temp)
    );


    wire [31:0] sin_theta1_w_q1219 = {{13'b0} ,sin_theta1_w_temp, {2'b0}};
    wire [31:0] sin_theta2_w_q1219 = {{13'b0} ,sin_theta2_w_temp, {2'b0}};

    reg [31:0] sin_theta1_r1 = 32'b0;
    reg [31:0] sin_theta2_r1 = 32'b0;
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            sin_theta1_r1 <= 32'b0;
            sin_theta2_r1 <= 32'b0;
        end
        else begin
            sin_theta1_r1 <= reduced_theta1_r_delay[16] ? (~sin_theta1_w_q1219 + 32'b1) : sin_theta1_w_q1219;
            sin_theta2_r1 <= reduced_theta2_r_delay[16] ? (~sin_theta2_w_q1219 + 32'b1) : sin_theta2_w_q1219;
        end
    end

    assign sin_theta1_w = sin_theta1_r1;
    assign sin_theta2_w = sin_theta2_r1;

//**********************Vo Calculate************************//
    wire [55:0] Vo_x_temp;
    wire [31:0] Vo_x;
    wire [55:0] Vo_y_temp;
    wire [31:0] Vo_y;
    mult_rcsj mult_Vo_x_inst (
        .CLK(clk),  // input wire CLK
        .A(x_r),      // input wire [31 : 0] A
        .B(Vo_ratio_x_r),      // input wire [31 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),
        .P(Vo_x_temp)      // output wire [63 : 0] P
    );
    assign Vo_x = Vo_x_temp[50:19];
    mult_rcsj mult_Vo_y_inst (
        .CLK(clk),  // input wire CLK
        .A(y_r),      // input wire [31 : 0] A
        .B(Vo_ratio_y_r),      // input wire [31 : 0] B
        .CE(cal_stage_en_r[1]),    // input wire CE
        .SCLR(~reset_n),
        .P(Vo_y_temp)      // output wire [63 : 0] P
    );
    assign Vo_y = Vo_y_temp[50:19];
    // Final output calculation
    add_rcsj add_rcsj_Vo_inst (
        .A(Vo_x),      // input wire [31 : 0] A
        .B(Vo_y),      // input wire [31 : 0] B
        .CLK(clk),  // input wire CLK
        .CE(cal_stage_en_r[2]),    // input wire CE
        .SCLR(~reset_n),
        .S(Vo_w)      // output wire [31 : 0] S
    );

//**********************phi_in_r ctrl*******************//
    wire ram_flag_w;
    Stimulus_Generator Seg_Stimulus_Generator_inst(
        .clk(clk),
        .reset_n(reset_n),
        .ram_flag_o(ram_flag_w),
        .sig_seg1_o(phi_in_seg_w[1]),
        .sig_seg2_o(phi_in_seg_w[2]),
        .sig_seg3_o(phi_in_seg_w[3]),
        .sig_seg4_o(phi_in_seg_w[4]),
        .sig_seg5_o(phi_in_seg_w[5]),
        .sig_seg6_o(phi_in_seg_w[6])
    );
//*****************low pass filter**********************//

    genvar j;
    generate for(j = 1; j < 7; j = j + 1) begin:low_pass_filter_group
        LP_Filter_Asym LP_inst(
        .clk(clk),
        .reset_n(reset_n),
        .lp_en(lp_filter_en_r[j]),
        .sig_i(Vo_list_r[j]),
        .sig_o(Vo_filtered_w[j])
    );
    end
    endgenerate

//****************BRAM Write ctrl*************************//

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            squid_ram_addr_r <= 16'b0;
            squid_ram_data_r <= 16'b0;
        end
        else begin
            if (ram_flag_w) begin
                case (state)
                    S1:begin
                        squid_ram_addr_r <= phi_in_seg_w[3][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[3][15:0];
                    end 
                    S2:begin
                        squid_ram_addr_r <= phi_in_seg_w[4][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[4][15:0];
                    end
                    S3:begin
                        squid_ram_addr_r <= phi_in_seg_w[5][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[5][15:0];
                    end
                    S4:begin
                        squid_ram_addr_r <= phi_in_seg_w[6][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[6][15:0];
                    end
                    S5:begin
                        squid_ram_addr_r <= phi_in_seg_w[1][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[1][15:0];
                    end
                    S6:begin
                        squid_ram_addr_r <= phi_in_seg_w[2][18:3] - 16'd635;
                        squid_ram_data_r <= Vo_filtered_w[2][15:0];
                    end 
                    default: begin
                        squid_ram_addr_r <= 16'b0;
                        squid_ram_data_r <= 16'b0;
                    end 
                endcase
            end
        end
    end
    assign ram_addr_o = squid_ram_addr_r[15:1];
    assign ram_data_o = (&squid_ram_data_r[15:14]) ? 16'b0 : squid_ram_data_r;
    assign ram_wr_en_o = ram_flag_w;


    reg [1:0] ram_flag_r = 2'b0;
    reg done_r = 1'b0;
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            done_r <= 1'b0;
            ram_flag_r <= 2'b0;
        end
        else begin
            ram_flag_r <= {ram_flag_r[0], ram_flag_w};
        end
    end

    (*MARK_DEBUG = "true"*) wire done_w;
    assign done_w = ram_flag_r[1] && (~ram_flag_r[0]);
    assign done_o = ram_flag_r[1] && (~ram_flag_r[0]);


    wire [23:0] peak_cnt_w;
    peak_cnt peak_cnt_inst(
        .clk(clk),
        .reset_n(reset_n),
        .data_i({{3{Vo_w[31]}},Vo_w[31:3]}),
        .state(state),

        .peak_cnt_o(peak_cnt_w)
    );

    reg is_pulse_r = 1'b0;
    always @(posedge clk) begin
        if(done_w) begin
            if (peak_cnt_w > 24'd10) begin
                is_pulse_r <= 1'b0;
            end
            else begin
                is_pulse_r <= 1'b1;
            end
        end
    end

    assign is_pulse_o = is_pulse_r;

endmodule
