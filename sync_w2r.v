`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:37:45
// Design Name: Asynchronous FIFO
// Module Name: sync_w2r
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Two flip-flop synchronizer. Synchronizes the Gray write pointer into the read clock domain.
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

module sync_w2r#(parameter ADDR_SIZE = 4)
(
    input rd_clk,
    input rst,
    input  [ADDR_SIZE:0] wptr,
    output [ADDR_SIZE:0] rq2_wptr
);
    (* ASYNC_REG = "TRUE" *) reg [ADDR_SIZE:0] rq1_wptr;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_SIZE:0] rq2_wptr_r;
    always @(posedge rd_clk or posedge rst)
    begin
        if (rst)
        begin
            rq1_wptr<=0;
            rq2_wptr_r<=0;
        end
        else
        begin
            rq1_wptr<=wptr;
            rq2_wptr_r<=rq1_wptr;
        end
    end
    assign rq2_wptr=rq2_wptr_r;
endmodule
