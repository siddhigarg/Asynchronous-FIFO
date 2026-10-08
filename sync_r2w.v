`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:37:45
// Design Name: Asynchronous FIFO
// Module Name: sync_r2w
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Two flip-flop synchronizer. Synchronizes the Gray read pointer into the write clock domain.
//              ASYNC_REG tells Vivado these are synchronizer flops (placed
//              close together, no logic in between).
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - Added ASYNC_REG attribute
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sync_r2w#(parameter ADDR_SIZE = 4)
(
    input wr_clk,
    input rst,
    input  [ADDR_SIZE:0] rptr,
    output [ADDR_SIZE:0] wq2_rptr
);
    (* ASYNC_REG = "TRUE" *) reg [ADDR_SIZE:0] wq1_rptr;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_SIZE:0] wq2_rptr_r;
    always @(posedge wr_clk or posedge rst)
    begin
        if (rst)
        begin
            wq1_rptr<=0;
            wq2_rptr_r<=0;
        end
        else
        begin
            wq1_rptr<=rptr;
            wq2_rptr_r<=wq1_rptr;
        end
    end
    assign wq2_rptr=wq2_rptr_r;
endmodule
