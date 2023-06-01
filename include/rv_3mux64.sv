// 3-port MUX
/*
Signal:
    INPUT:
        a : [63:0]
        b : [63:0]
        c : [63:0]
        sel: [1:0] Select Signal
    OUTPUT:
        out : [63:0]
Control Table:
    sel:
        2'b00 -> inA
        2'b01 -> inB
        2'b10 -> inC
*/
module rv_mux3_64 (
    input   wire    rst_n,
    input   wire    [63:0]inA,
    input   wire    [63:0]inB,
    input   wire    [63:0]inC,
    input   wire    [1:0]sel,
    output  wire    [63:0]out
);
    logic [63:0]o;
    always_ff @(*) begin
        if (rst_n == 1'b0) begin
            o   <=  64'h0;
        end
        else begin
            case (sel)
                2'b00:  o <= inA;
                2'b01:  o <= inB;
                2'b10:  o <= inC;
                default: o <= 64'hX;
            endcase
        end
    end
    assign out = o;
endmodule