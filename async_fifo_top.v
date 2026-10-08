`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
// 
// Create Date: 20.09.2026 21:39:26
// Design Name: Asynchronous FIFO
// Module Name: async_fifo_top
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices: 
// Tool Versions: 
// Description: Top level of the asynchronous FIFO. Depth = 2**ADDR_SIZE words
//              of DATA_WIDTH bits (ADDR_SIZE >= 2). Writes while full and
//              reads while empty are ignored. rd_data is valid on the rd_clk
//              cycle after a read is accepted (rd_en=1 and empty=0).
//              rst is asynchronous; it is re-synchronized into each domain.
// 
// Dependencies: fifo_mem, wptr_full, rptr_empty, sync_r2w, sync_w2r, rst_sync
// 
// Revision:
// Revision 0.02 - Added wptr_full, per-domain reset synchronizers,
//                 rd_en-qualified memory read
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module async_fifo_top#(parameter DATA_WIDTH=8,parameter ADDR_SIZE =4)
(
    input wr_clk,
    input rd_clk,
    input rst,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] wr_data,

    output [DATA_WIDTH-1:0] rd_data,
    output full,
    output empty
);
    wire wr_rst;
    wire rd_rst;
    wire [ADDR_SIZE-1:0] waddr;
    wire [ADDR_SIZE-1:0] raddr;
    wire [ADDR_SIZE:0] wptr;
    wire [ADDR_SIZE:0] rptr;
    wire [ADDR_SIZE:0] wq2_rptr;
    wire [ADDR_SIZE:0] rq2_wptr;

    // Reset Synchronizers (one per clock domain)
    rst_sync wr_reset_sync (
        .clk(wr_clk),
        .rst_in(rst),
        .rst_out(wr_rst)
    );

    rst_sync rd_reset_sync (
        .clk(rd_clk),
        .rst_in(rst),
        .rst_out(rd_rst)
    );

    // FIFO Memory
    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_SIZE)
    )
    memory (
        .wr_clk(wr_clk),
        .wr_en(wr_en & ~full),
        .wr_addr(waddr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_en(rd_en & ~empty),
        .rd_addr(raddr),
        .rd_data(rd_data)
    );

    // Write Pointer
    wptr_full #(.ADDR_SIZE(ADDR_SIZE))
    write_logic (
        .wr_clk(wr_clk),
        .rst(wr_rst),
        .wr_en(wr_en),
        .wq2_rptr(wq2_rptr),
        .full(full),
        .waddr(waddr),
        .wptr(wptr)
    );

    // Read Pointer
    rptr_empty #(.ADDR_SIZE(ADDR_SIZE))
    read_logic (
        .rd_clk(rd_clk),
        .rst(rd_rst),
        .rd_en(rd_en),
        .rq2_wptr(rq2_wptr),
        .empty(empty),
        .raddr(raddr),
        .rptr(rptr)
    );

    // Synchronizer: read pointer -> write clock domain
    sync_r2w #(.ADDR_SIZE(ADDR_SIZE))
    sync_read (
        .wr_clk(wr_clk),
        .rst(wr_rst),
        .rptr(rptr),
        .wq2_rptr(wq2_rptr)
    );

    // Synchronizer: write pointer -> read clock domain
    sync_w2r #(.ADDR_SIZE(ADDR_SIZE))
    sync_write (
        .rd_clk(rd_clk),
        .rst(rd_rst),
        .wptr(wptr),
        .rq2_wptr(rq2_wptr)
    );
endmodule
