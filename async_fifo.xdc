## Timing constraints for async_fifo_top (out-of-context / standalone synthesis).
## Clock periods are examples - change them to match the real clocks.

create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 14.000 [get_ports rd_clk]

## Paths between the two clock domains (Gray pointers into the synchronizers,
## and the memory read path) are asynchronous. Instead of cutting them
## completely, bound their delay to one period of the faster clock so the
## Gray-code bits cannot skew by more than one cycle.
set_max_delay -datapath_only -from [get_clocks wr_clk] -to [get_clocks rd_clk] 10.000
set_max_delay -datapath_only -from [get_clocks rd_clk] -to [get_clocks wr_clk] 10.000

## rst is asynchronous and re-synchronized inside the design.
set_false_path -from [get_ports rst]
