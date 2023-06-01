# rv_single

This repo contains a single-stage general purpose RV64IC core.

It is designed to be cross-platform.

It is coded using SystemVerilog.

The code needed for the core is ```rv_single.sv``` and files inside ```./include``` 

Tested with DE10-Nano and Perf-V development board. It can run at 30MHz

Note that the memory initialzation is achieved by ```include/*.mem```. And the instruction memory is actually a ROM. Thus changing program loaded need to change the content of ```include/instr_mem.mem``` and may require a **full** compile flow re-run.

The GPIO is set to connect x31 register. It is connected to it's MSB.