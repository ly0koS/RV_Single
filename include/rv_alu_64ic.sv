//ALU for RV64IC Instruction Set
/*
Signals:
    INPUT:
        [63:0]a:OpA
        [63:0]b:OpB
        [3:0]alu_ctrl: Control Signal for ALU
    OUPUT:
        [63:0]result: Result output

Control Table: 
    alu_ctrl:
        4'b0000:    ADD
        4'b0001:    SUB
        4'b0010:    AND
        4'b0011:    OR
        4'b0100:    XOR
        4'b0101:    SLL
        4'b0110:    SRL
        4'b0111:    SRA
        4'b1000:    SLT
        4'b1001:    SLTU
*/
module rv_alu_64ic (
    input   wire    rst_n,
    input   wire    [63:0]opa,
    input   wire    [63:0]opb,
    input   wire    [3:0]alu_ctrl,

    output  wire    zero,
    output  wire    neg,
    output  wire    [63:0]result
);

    logic   [63:0]alu_o;
    logic   n;
    logic   z;

    always_comb begin
        if (rst_n == 1'b0) begin
            alu_o = 64'd0;
            z     = 1'b0;
            n     = 1'b0;
        end
        else begin
            case (alu_ctrl)
                4'b0000:    alu_o = opa + opb;
                4'b0001:    alu_o = opa - opb;
                4'b0010:    alu_o = opa & opb;
                4'b0011:    alu_o = opa | opb;
                4'b0100:    alu_o = opa ^ opb;
                4'b0101:    alu_o = opa << opb;
                4'b0110:    alu_o = opa >> opb;
                4'b0111:    alu_o = $signed(opa) >> opb;
                4'b1000:    alu_o = ($signed(opa) < $signed(opb)) ? 64'h1 : 64'h0;
                4'b1001:    alu_o = (opa < opb) ? 64'h1 : 64'h0;
                default:    alu_o = 64'b0;
            endcase
            if (opa-opb==0) begin
                z = 1'b1;
            end
            else begin
                z = 1'b0;
            end
            if (alu_o == 1) begin
                n = 1'b1;
            end
            else begin
                n = 1'b0;
            end
        end
    end

    assign  neg         =   n;
    assign  zero        =   z;
    assign  result      =   alu_o;

endmodule