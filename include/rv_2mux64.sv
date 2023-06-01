// 2-port MUX Sync
/*
Signal:
    INPUT:
        rst_n
        a
        b
        sel: Select Signal
    OUTPUT:
        out
Control Table:
    sel:
        0 -> inA
        1 -> inB
*/
module rv_mux2_64 (
	input   wire    rst_n,
    input   wire    [63:0]inA,
    input   wire    [63:0]inB,
    input   wire    sel,
    output  wire    [63:0]out
);
    logic [63:0]o;
    always_ff @(*) begin
        if (rst_n == 1'b0) begin
            o <= 64'd0;
        end
        else begin
            o <= sel ? inB : inA;
        end
    end
    assign out = o;
endmodule