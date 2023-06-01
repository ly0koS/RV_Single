module rv_mem_1024 #(parameter DMEM_SIZE = 32)(
    input   wire   clk,
    input   wire   [15:0] addr,
    input   wire   [63:0] data_in,
    input   wire   wr_en,
    output  wire   [63:0] data_out
);
	reg     [63:0]dmem [0:DMEM_SIZE*1024-1];
    logic   [63:0]data;

    initial begin
        $readmemh("C:/Users/Jeremy/OneDrive/Documents/Study/Master/Thesis/Cores/rv_single/include/d_mem.mem",dmem);
    end

    always_ff @(posedge clk) begin
        if (wr_en) begin
            dmem[addr] <= data_in;
        end
        else begin
            data  <= dmem[addr];
        end
    end

    assign data_out=data;
endmodule