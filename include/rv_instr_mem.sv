module rv_instr_mem #(parameter IMEM_SIZE = 64)(
    input   wire    clk,
    input   wire    instr_wr_en,
    input   wire    [31:0]instr_in,
    input   wire    [15:0]addr,
    output  wire    [31:0]instr_o
);

    reg   [31:0]instr_mem[0:IMEM_SIZE*1024-1];
    logic   [31:0]instr;

    initial begin
        $readmemh("C:/Users/Jeremy/OneDrive/Documents/Study/Master/Thesis/Cores/rv_single/include/instr_mem.mem",instr_mem);
    end

    always_ff @( posedge clk) begin
        if (instr_wr_en) begin
            instr_mem[addr] <= instr_in;
        end
        else begin
            instr <= instr_mem[addr];
        end
    end

    assign instr_o=instr;

endmodule