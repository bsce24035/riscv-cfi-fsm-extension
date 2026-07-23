`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 02:32:22 PM
// Design Name: 
// Module Name: module_cfi
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

module module_cfi(
    input  logic clk,          // clock
    input  logic rst_n,        // Active-low reset
    input  logic [31:0] pkt,   // 32-bit packet input 
    output logic error_o,      // High when in ERROR state
    output logic [1:0] state_o // State output 
);

    // Command Opcodes
    localparam logic [7:0] CMD_SET  = 8'h01;
    localparam logic [7:0] CMD_JUMP = 8'h02;
    localparam logic [7:0] CMD_LPAD = 8'h03;

    // FSM State Encoding
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        CHECK = 2'b01,
        ERROR = 2'b10
    } state_t;

    state_t state_q, state_d;

    // Internal register for target label storage (24-bit)
    logic [23:0] label_q, label_d;

    // Field extraction from input packet
    logic [7:0]  cmd;
    logic [23:0] data;

    assign cmd  = pkt[31:24];
    assign data = pkt[23:0];

    // Output assignments
    assign error_o = (state_q == ERROR);
    assign state_o = state_q;

    // Next-State & Register Update Logic (Combinational)
    always_comb begin
        // Default assignments (retain current state and label)
        state_d = state_q;
        label_d = label_q;

        case (state_q)
            IDLE: begin
                if (cmd == CMD_SET) begin
                    label_d = data;       // Store label
                    state_d = IDLE;       // Remain IDLE
                end else if (cmd == CMD_JUMP) begin
                    state_d = CHECK;      // Move to CHECK
                end else begin
                    state_d = IDLE;       // Remain IDLE for unknown/other commands
                end
            end

            CHECK: begin
                if ((cmd == CMD_LPAD) && (data == label_q)) begin
                    state_d = IDLE;       // Verification successful
                end else begin
                    state_d = ERROR;      // Security violation
                end
            end

            ERROR: begin
                state_d = ERROR;          // Sticky error state
            end

            default: begin
                state_d = ERROR;
            end
        endcase
    end

    // State Register (Sequential)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            label_q <= 24'h0;
        end else begin
            state_q <= state_d;
            label_q <= label_d;
        end
    end
    
endmodule
