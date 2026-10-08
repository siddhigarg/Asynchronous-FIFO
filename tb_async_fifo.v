`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NXP WIT Mini Project
// Engineer: Group 9
//
// Create Date: 20.09.2026 21:41:19
// Design Name: Asynchronous FIFO
// Module Name: tb_async_fifo
// Project Name: RTL Design of an Asynchronous FIFO using Verilog-HDL
// Target Devices:
// Tool Versions:
// Description: Self-checking testbench.
//              - A reference model (scoreboard) stores every accepted write
//                and checks every read for correct data and order.
//              - FULL/EMPTY are checked continuously: the FIFO must never
//                report "not full" while holding DEPTH words, or "not empty"
//                while holding no words.
//              - Tests: fill/overflow/drain/underflow, concurrent random
//                read+write at five write/read clock ratios, reset in the
//                middle of operation.
//              - Inputs are driven on the falling clock edge (no races with
//                the DUT, which samples on the rising edge).
//              Ends with "TEST PASSED" or "TEST FAILED".
//
// Dependencies: async_fifo_top
//
// Revision:
// Revision 0.02 - Self-checking scoreboard, multi-frequency tests
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module tb_async_fifo;

    parameter DATA_WIDTH = 8;
    parameter ADDR_SIZE  = 4;
    localparam DEPTH      = 1 << ADDR_SIZE;
    localparam MODEL_SIZE = 1024;

    // Inputs
    reg wr_clk;
    reg rd_clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] wr_data;

    // Outputs
    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    // Clock half-periods in ns (changed between test phases)
    real wr_half;
    real rd_half;

    //Instantiate DUT
    async_fifo_top #(.DATA_WIDTH(DATA_WIDTH),.ADDR_SIZE(ADDR_SIZE))
     DUT (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    initial begin
        wr_half=5.0;
        wr_clk=0;
        forever #(wr_half) wr_clk=~wr_clk;
    end

    initial begin
        rd_half=7.0;
        rd_clk=0;
        forever #(rd_half) rd_clk=~rd_clk;
    end

    // Waveform dump (for ModelSim/Icarus; Vivado shows waves in its GUI)
    initial begin
        $dumpfile("tb_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    //------------------------------------------------------------------
    // Scoreboard
    //------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] model [0:MODEL_SIZE-1];
    integer wr_cnt;        // words accepted by the FIFO (since last reset)
    integer rd_cnt;        // words read from the FIFO (since last reset)
    integer total_reads;   // data checks over the whole simulation
    integer errors;
    reg chk_pending;
    reg [DATA_WIDTH-1:0] exp_data;

    // Write side: record accepted writes, check FULL is never missed
    always @(posedge wr_clk) begin
        if (!rst) begin
            if (!full && (wr_cnt-rd_cnt) >= DEPTH) begin
                errors=errors+1;
                $display("%0t ERROR: FIFO holds %0d words but FULL is low", $time, wr_cnt-rd_cnt);
            end
            if (wr_en && !full) begin
                model[wr_cnt % MODEL_SIZE]=wr_data;
                wr_cnt=wr_cnt+1;
            end
        end
    end

    // Read side: check EMPTY is never missed, capture expected data
    always @(posedge rd_clk) begin
        chk_pending<=1'b0;
        if (!rst) begin
            if (!empty && wr_cnt==rd_cnt) begin
                errors=errors+1;
                $display("%0t ERROR: FIFO holds no words but EMPTY is low", $time);
            end
            if (rd_en && !empty) begin
                exp_data<=model[rd_cnt % MODEL_SIZE];
                chk_pending<=1'b1;
                rd_cnt=rd_cnt+1;
            end
        end
    end

    // rd_data is registered: compare it half a read cycle after the read
    always @(negedge rd_clk) begin
        if (chk_pending) begin
            total_reads=total_reads+1;
            if (rd_data !== exp_data) begin
                errors=errors+1;
                $display("%0t ERROR: read %0d, expected %0d", $time, rd_data, exp_data);
            end
        end
    end

    //------------------------------------------------------------------
    // Helper tasks (all inputs change on the falling edge)
    //------------------------------------------------------------------
    task check_bit(input actual, input expected, input [8*40-1:0] what);
        begin
            if (actual !== expected) begin
                errors=errors+1;
                $display("%0t ERROR: %0s is %b, expected %b", $time, what, actual, expected);
            end
        end
    endtask

    task check_flags(input exp_full, input exp_empty, input [8*48-1:0] where);
        begin
            if (full !== exp_full || empty !== exp_empty) begin
                errors=errors+1;
                $display("%0t ERROR [%0s]: full=%b empty=%b, expected full=%b empty=%b",
                         $time, where, full, empty, exp_full, exp_empty);
            end
        end
    endtask

    // Let both pointers cross to the other domain
    task wait_sync;
        begin
            repeat (4) @(posedge wr_clk);
            repeat (4) @(posedge rd_clk);
        end
    endtask

    // Write n words, only when not full
    task write_words(input integer n);
        integer k;
        begin
            k=0;
            while (k<n) begin
                @(negedge wr_clk);
                if (!full) begin
                    wr_en=1; wr_data=$random; k=k+1;
                end
                else
                    wr_en=0;
            end
            @(negedge wr_clk);
            wr_en=0;
        end
    endtask

    // Read n words, only when not empty
    task read_words(input integer n);
        integer k;
        begin
            k=0;
            while (k<n) begin
                @(negedge rd_clk);
                if (!empty) begin
                    rd_en=1; k=k+1;
                end
                else
                    rd_en=0;
            end
            @(negedge rd_clk);
            rd_en=0;
        end
    endtask

    // Hold wr_en high for n cycles regardless of FULL (overflow attempt)
    task force_writes(input integer n);
        begin
            repeat (n) begin
                @(negedge wr_clk);
                wr_en=1; wr_data=$random;
            end
            @(negedge wr_clk);
            wr_en=0;
        end
    endtask

    // Hold rd_en high for n cycles regardless of EMPTY (underflow attempt)
    task force_reads(input integer n);
        begin
            repeat (n) begin
                @(negedge rd_clk);
                rd_en=1;
            end
            @(negedge rd_clk);
            rd_en=0;
        end
    endtask

    // Concurrent random reads and writes until n words have passed through.
    // wr_en/rd_en are also raised while full/empty to stress the flag logic.
    task random_traffic(input integer n, input integer wr_pct, input integer rd_pct);
        integer nw, nr;
        begin
            nw=0; nr=0;
            fork
                begin
                    while (nw<n) begin
                        @(negedge wr_clk);
                        if (({$random} % 100) < wr_pct) begin
                            wr_en=1; wr_data=$random;
                            if (!full) nw=nw+1;
                        end
                        else
                            wr_en=0;
                    end
                    @(negedge wr_clk);
                    wr_en=0;
                end
                begin
                    while (nr<n) begin
                        @(negedge rd_clk);
                        if (({$random} % 100) < rd_pct) begin
                            rd_en=1;
                            if (!empty) nr=nr+1;
                        end
                        else
                            rd_en=0;
                    end
                    @(negedge rd_clk);
                    rd_en=0;
                end
            join
        end
    endtask

    // Run writer-heavy and reader-heavy traffic at a given clock ratio
    task run_phase(input real wh, input real rh, input [8*48-1:0] name);
        begin
            $display("%0t TEST: concurrent traffic, %0s", $time, name);
            wr_half=wh;
            rd_half=rh;
            wait_sync;
            random_traffic(200, 90, 40);   // FIFO tends to fill up
            random_traffic(200, 40, 90);   // FIFO tends to run empty
            wait_sync;
            check_flags(0, 1, name);
        end
    endtask

    task apply_reset;
        begin
            @(negedge wr_clk);
            wr_en=0;
            rd_en=0;
            rst=1;
            wr_cnt=0;
            rd_cnt=0;
            chk_pending=0;
            #1 check_flags(0, 1, "during reset");
            repeat (3) @(posedge wr_clk);
            repeat (3) @(posedge rd_clk);
            @(negedge wr_clk);
            rst=0;
            wait_sync;
            check_flags(0, 1, "after reset");
        end
    endtask

    //------------------------------------------------------------------
    // Test sequence
    //------------------------------------------------------------------
    initial begin
        rst=1;
        wr_en=0;
        rd_en=0;
        wr_data=0;
        wr_cnt=0;
        rd_cnt=0;
        total_reads=0;
        errors=0;
        chk_pending=0;

        #30;
        @(negedge wr_clk);
        rst=0;
        wait_sync;
        check_flags(0, 1, "after power-on reset");

        // TEST 1: fill, overflow attempt, drain, underflow attempt
        $display("%0t TEST: fill to full / overflow / drain / underflow", $time);
        write_words(DEPTH);
        check_bit(full, 1'b1, "full after DEPTH writes");
        force_writes(4);
        wait_sync;
        check_flags(1, 0, "still full after overflow attempt");
        read_words(DEPTH);
        check_bit(empty, 1'b1, "empty after DEPTH reads");
        wait_sync;
        check_flags(0, 1, "empty after draining");
        force_reads(4);
        wait_sync;
        check_flags(0, 1, "still empty after underflow attempt");

        // TEST 2: concurrent read/write at different clock ratios
        run_phase(5.0,  7.0,  "wr 100 MHz / rd 71 MHz (write faster)");
        run_phase(10.0, 3.0,  "wr 50 MHz / rd 167 MHz (read faster)");
        run_phase(5.0,  5.0,  "wr = rd = 100 MHz");
        run_phase(3.65, 5.95, "wr 137 MHz / rd 84 MHz (non-integer)");
        run_phase(2.0,  18.5, "wr 250 MHz / rd 27 MHz (large ratio)");

        // TEST 3: reset in the middle of operation
        $display("%0t TEST: reset while FIFO is full", $time);
        wr_half=5.0;
        rd_half=7.0;
        write_words(DEPTH);
        apply_reset;
        $display("%0t TEST: reset while FIFO is partly full", $time);
        write_words(10);
        wait_sync;
        read_words(3);
        apply_reset;
        $display("%0t TEST: normal operation after reset", $time);
        random_traffic(100, 70, 70);
        wait_sync;
        check_flags(0, 1, "end of test");

        // Summary
        $display("------------------------------------------------");
        $display("Data words checked : %0d", total_reads);
        $display("Errors             : %0d", errors);
        if (errors==0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
        $display("------------------------------------------------");
        $finish;
    end

    // Watchdog
    initial begin
        #2000000;
        $display("ERROR: simulation timeout");
        $display("TEST FAILED");
        $finish;
    end
endmodule
