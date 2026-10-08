`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:33:10
// Design Name: Asynchronous FIFO
// Module Name: wptr_full
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Write pointer (binary + Gray) and FULL flag generation in the
//              write clock domain. FULL is set when the next Gray write pointer
//              equals the synchronized Gray read pointer with its two MSBs
//              inverted (writer is exactly one lap ahead of the reader).
//              Requires ADDR_SIZE >= 2.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module wptr_full#(parameter ADDR_SIZE=4)
(
    input wr_clk,
    input rst,
    input wr_en,
    input [ADDR_SIZE:0] wq2_rptr,
    output reg full,
    output [ADDR_SIZE-1:0] waddr,
    output reg [ADDR_SIZE:0] wptr
);

    reg [ADDR_SIZE:0] wbin;
    wire [ADDR_SIZE:0] wbin_next;
    wire [ADDR_SIZE:0] wgray_next;
    wire wfull_val;

    // Next binary pointer
    assign wbin_next=wbin+(wr_en&~full);
    // Binary to Gray conversion
    assign wgray_next=(wbin_next>>1)^wbin_next;
    // Memory write address
    assign waddr=wbin[ADDR_SIZE-1:0];
    // Full detection
    assign wfull_val=(wgray_next=={~wq2_rptr[ADDR_SIZE:ADDR_SIZE-1],wq2_rptr[ADDR_SIZE-2:0]});

    always @(posedge wr_clk or posedge rst)
    begin
        if(rst)
        begin
            wbin<=0;
            wptr<=0;
            full<=0;
        end
        else
        begin
            wbin<=wbin_next;
            wptr<=wgray_next;
            full<=wfull_val;
        end
    end
endmodule
