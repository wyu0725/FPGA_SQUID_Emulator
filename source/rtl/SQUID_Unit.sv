`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/29 09:31:21
// Design Name: 
// Module Name: SQUID_Unit
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


module SQUID_Unit(
    input clk,
    input reset_n,
    input squid_en_i,

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

    input clk_sig_in,
    input [15:0] phi_i,
    input phi_in_valid_i,
    output vo_valid_o,
    output [15:0] vo_o,

    output done_o

    );

    wire solver2mem_wr_en_w;
    wire [14:0] solver2mem_addr_w;
    wire [15:0] solver2mem_data_w;

    reg solver_en_r = 1'b0;
    reg solver_reset_n_r = 1'b0;
    reg solver_cnt_is_odd_r = 1'b0;
    (*MARK_DEBUG = "true"*) wire is_pulse_w;
    wire done_w;
    
    localparam IDLE = 3'b001; // IDLE
    localparam S1   = 3'b010; // RAM1
    localparam S2   = 3'b100; // RAM2
    reg [2:0] state = IDLE;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            state <= IDLE;
            solver_cnt_is_odd_r <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (squid_en_i) begin
                        state <= S1;
                        solver_en_r <= 1'b0;
                        solver_reset_n_r <= 1'b1;
                    end
                    else begin
                        state <= IDLE;
                        solver_en_r <= 1'b0;
                        solver_reset_n_r <= 1'b0;
                    end
                end
                S1: begin
                    state <= S2;
                    solver_en_r <= 1'b1;
                    solver_reset_n_r <= 1'b1;
                end
                S2: begin
                    if (done_w) begin
                        state <= IDLE;
                        solver_en_r <= 1'b0;
                        solver_reset_n_r <= 1'b0;
                        solver_cnt_is_odd_r <= ~solver_cnt_is_odd_r;
                    end
                    else begin
                        state <= S2;
                        solver_en_r <= 1'b1;
                        solver_reset_n_r <= 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // always @(*) begin
    //     case (state)
    //         IDLE: begin
    //             solver_en_r = 1'b0;
    //             solver_reset_n_r = 1'b0;
    //         end 
    //         S1: begin
    //             solver_en_r = 1'b0;
    //             solver_reset_n_r = 1'b1;
    //         end
    //         S2: begin
    //             solver_en_r = 1'b1;
    //             solver_reset_n_r = 1'b1;
    //         end
    //         default: begin
    //             solver_en_r = 1'b0;
    //             solver_reset_n_r = 1'b0;
    //         end
    //     endcase
    // end
    (*DONT_TOUCH="YES"*)wire solver_reset_n_w;
    (*DONT_TOUCH="YES"*) wire solver_reset_n_w_bufg;
    assign solver_reset_n_w = solver_reset_n_r;
    (*DONT_TOUCH="YES"*) BUFG BUFG_inst (
        .O(solver_reset_n_w_bufg), // 1-bit output: Clock output
        .I(solver_reset_n_w)  // 1-bit input: Clock input
    );

    SQUID_Asym_Solver SQUID_Asym_Solver_inst(
        .clk(clk),
        .reset_n(solver_reset_n_w_bufg),
        .start_en_i(solver_en_r),

        .ax_i(ax_i),
        .bx_i(bx_i),
        .cx_i(cx_i),
        .dx_i(dx_i),
        .ex_i(ex_i),
        .fx_i(fx_i),
        .gx_i(gx_i),

        .ay_i(ay_i),
        .by_i(by_i),
        .cy_i(cy_i),
        .dy_i(dy_i),
        .ey_i(ey_i),
        .fy_i(fy_i),
        .gy_i(gy_i),
        
        .Vo_ratio_x_i(Vo_ratio_x_i),
        .Vo_ratio_y_i(Vo_ratio_y_i),

        .ram_addr_o(solver2mem_addr_w),
        .ram_data_o(solver2mem_data_w),
        .ram_wr_en_o(solver2mem_wr_en_w),

        .is_pulse_o(is_pulse_w),
        .done_o(done_w)
    );

    wire [15:0] vo_mem1_data_w;
    wire [15:0] vo_mem2_data_w;
    reg [15:0] vo_mem_sel_r = 16'b0;


    squid_vphi_ram squid_vphi_ram_inst1 (
        .clka(clk),    // input wire clka
        .wea(solver2mem_wr_en_w && (~solver_cnt_is_odd_r)),      // input wire [0 : 0] wea
        .addra(solver2mem_addr_w),  // input wire [14 : 0] addra
        .dina(solver2mem_data_w),    // input wire [15 : 0] dina
        // .douta(),  // output wire [15 : 0] douta
        .clkb(clk_sig_in),    // input wire clkb
        .web(1'b0),      // input wire [0 : 0] web
        .addrb(phi_i[15:1]),  // input wire [14 : 0] addrb
        .dinb(),    // input wire [15 : 0] dinb
        .doutb(vo_mem1_data_w)  // output wire [15 : 0] doutb
    );

    squid_vphi_ram squid_vphi_ram_inst2 (
        .clka(clk),    // input wire clka
        .wea(solver2mem_wr_en_w && (solver_cnt_is_odd_r)),      // input wire [0 : 0] wea
        .addra(solver2mem_addr_w),  // input wire [14 : 0] addra
        .dina(solver2mem_data_w),    // input wire [15 : 0] dina
        // .douta(),  // output wire [15 : 0] douta
        .clkb(clk_sig_in),    // input wire clkb
        .web(1'b0),      // input wire [0 : 0] web
        .addrb(phi_i[15:1]),  // input wire [14 : 0] addrb
        .dinb(),    // input wire [15 : 0] dinb
        .doutb(vo_mem2_data_w)  // output wire [15 : 0] doutb
    );

    // reg solver_cnt_is_odd_sync_r1 = 1'b0;
    // reg solver_cnt_is_odd_sync_r2 = 1'b0;

    // reg [15:0] vo_mem1_data_sync_r1 = 16'b0;
    // reg [15:0] vo_mem1_data_sync_r2 = 16'b0;
    // reg [15:0] vo_mem2_data_sync_r1 = 16'b0;
    // reg [15:0] vo_mem2_data_sync_r2 = 16'b0;

    // always @(posedge clk_sig_in or negedge reset_n) begin
    //     if (~reset_n) begin
    //         solver_cnt_is_odd_sync_r1 <= 1'b0;
    //         solver_cnt_is_odd_sync_r2 <= 1'b0;
    //     end 
    //     else begin
    //         solver_cnt_is_odd_sync_r1 <= solver_cnt_is_odd_r;
    //         solver_cnt_is_odd_sync_r2 <= solver_cnt_is_odd_sync_r1;
    //     end
    // end


    // always @(posedge clk_sig_in or negedge reset_n) begin
    //     if (~reset_n) begin
    //         vo_mem1_data_sync_r1 <= 16'b0;
    //         vo_mem1_data_sync_r2 <= 16'b0;
    //         vo_mem2_data_sync_r1 <= 16'b0;
    //         vo_mem2_data_sync_r2 <= 16'b0;
    //         vo_mem_sel_r <= 16'b0;
    //     end 
    //     else begin
    //         vo_mem1_data_sync_r1 <= vo_mem1_data_w;
    //         vo_mem1_data_sync_r2 <= vo_mem1_data_sync_r1;
    //         vo_mem2_data_sync_r1 <= vo_mem2_data_w;
    //         vo_mem2_data_sync_r2 <= vo_mem2_data_sync_r1;
    //         if (~solver_cnt_is_odd_sync_r2) begin
    //             vo_mem_sel_r <= vo_mem2_data_sync_r2;
    //         end
    //         else begin
    //             vo_mem_sel_r <= vo_mem1_data_sync_r2;
    //         end
    //     end
    // end
    always @(posedge clk_sig_in or negedge reset_n) begin
        if (~reset_n) begin
            vo_mem_sel_r <= 16'b0;
        end
        else begin
            if (is_pulse_w) begin
                vo_mem_sel_r <= 16'b0; // Reset the output when a pulse is detected
            end
            else begin
            if (~solver_cnt_is_odd_r) begin
                vo_mem_sel_r <= vo_mem2_data_w;
            end
            else begin
                vo_mem_sel_r <= vo_mem1_data_w;
            end 
        end
        end
    end

    reg vo_valid_r = 1'b0;
    always @(posedge clk_sig_in or negedge reset_n) begin
        if (~reset_n) begin
            vo_valid_r <= 1'b0;
        end
        else begin
            vo_valid_r <= phi_in_valid_i;
        end
    end

    assign vo_valid_o = vo_valid_r;
    assign vo_o = vo_mem_sel_r;
    assign done_o = done_w;

endmodule
