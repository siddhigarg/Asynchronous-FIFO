`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:35:19
// Design Name: Asynchronous FIFO
// Module Name: rptr_empty
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Read pointer (binary + Gray) and EMPTY flag generation in the
//              read clock domain. EMPTY is set when the next Gray read pointer
//              equals the synchronized Gray write pointer.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rptr_empty#(parameter ADDR_SIZE=4)
(
    input rd_clk,
    input rst,
    input rd_en,
    input [ADDR_SIZE:0] rq2_wptr,
    output reg empty,
    output [ADDR_SIZE-1:0] raddr,
    output reg [ADDR_SIZE:0] rptr
);

    reg [ADDR_SIZE:0] rbin;
    wire [ADDR_SIZE:0] rbin_next;
    wire [ADDR_SIZE:0] rgray_next;
    wire rempty_val;

    // Next binary pointer
    assign rbin_next=rbin+(rd_en&~empty);
    // Binary to Gray conversion
    assign rgray_next=(rbin_next>>1)^rbin_next;
    // Memory read address
    assign raddr=rbin[ADDR_SIZE-1:0];
    // Empty detection
    assign rempty_val=(rgray_next==rq2_wptr);

    always @(posedge rd_clk or posedge rst)
    begin
        if(rst)
        begin
            rbin<=0;
            rptr<=0;
            empty<=1;
        end
        else
        begin
            rbin<=rbin_next;
            rptr<=rgray_next;
            empty<=rempty_val;
        end
    end
endmodule
