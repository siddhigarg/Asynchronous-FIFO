`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:38:30
// Design Name: Asynchronous FIFO
// Module Name: rst_sync
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Reset synchronizer. Asserts reset asynchronously, releases it
//              synchronously to clk through two flip-flops, so reset
//              de-assertion can never cause a recovery/removal violation.
//              One instance is used per clock domain.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rst_sync
(
    input clk,
    input rst_in,
    output rst_out
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] rst_ff;
    always @(posedge clk or posedge rst_in)
    begin
        if (rst_in)
            rst_ff<=2'b11;
        else
            rst_ff<={rst_ff[0],1'b0};
    end
    assign rst_out=rst_ff[1];
endmodule
