`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:27:35
// Design Name: Asynchronous FIFO
// Module Name: fifo_mem
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Dual-port memory. Write port on wr_clk, registered read port
//              on rd_clk. rd_data only updates when a word is actually read.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - Read port qualified with rd_en
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_mem #(
    parameter DATA_WIDTH=8,
    parameter ADDR_WIDTH=4
)(
    input wr_clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    input rd_clk,
    input rd_en,
    input [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data
);
    //Memory array-(2**ADDR_WIDTH) x DATA_WIDTH
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    //Write operation
    always @(posedge wr_clk) begin
        if (wr_en)
            mem[wr_addr]<=wr_data;
    end
    //Read operation: rd_data holds the word popped on the last read
    always @(posedge rd_clk) begin
        if (rd_en)
            rd_data<=mem[rd_addr];
    end
endmodule
