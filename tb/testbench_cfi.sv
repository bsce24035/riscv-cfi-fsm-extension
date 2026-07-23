`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2026 02:32:22 PM
// Design Name: 
// Module Name: testbench_cfi
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


module testbench_cfi();
    logic clk;
    logic rst_n;
    logic [31:0] pkt;
    logic error_o;
    logic [1:0] state_o;

    module_cfi tb (.clk(clk), .rst_n(rst_n), .pkt(pkt), .error_o(error_o), .state_o(state_o));

    // Generate Clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        pkt = 32'h0;

        // Reset Sequence
        #15;
        rst_n = 1;
        #10;

        // TEST CASE 1: Valid Path
        // 1. SET Label to 0xABCDEF
        pkt = {8'h01, 24'hABCDEF}; 
        #10;
        
        // Idle command cycle
        pkt = 32'h0; 
        #10;

        // 2. JUMP Command 
        pkt = {8'h02, 24'h000000}; 
        #10;

        // 3. Right on next cycle, pass correct LPAD label 0xABCDEF
        pkt = {8'h03, 24'hABCDEF}; 
        #10;

        // Clear packet, verify FSM returned to IDLE safely
        pkt = 32'h0;
        #20;

        // TEST CASE 2: Security Violation (Invalid Path)
        // 1. JUMP Command again
        pkt = {8'h02, 24'h000000}; 
        #10;

        // 2. Immediate violation: Next cycle has wrong label (0x111111)
        pkt = {8'h03, 24'h111111}; 
        #10;

        // 3. Verify sticky error state stays forever even if correct label sent late
        pkt = {8'h03, 24'hABCDEF}; 
        #20;

        $finish;
    end

endmodule

