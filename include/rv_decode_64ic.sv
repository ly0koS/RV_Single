//Instruction Decoder:Support for RV64IC(included RV32IC)
module rv_decode_64ic (
    input   wire    [31:0]instr,
    input   wire    rst_n,
    input   wire    c_en,
    output  logic   [1:0]XLEN,
    output  wire    [4:0]Wr_idx,
    output  wire    [4:0]R1_idx,
    output  wire    [4:0]R2_idx,
    output  wire    [6:0]opcode,
    output  wire    [1:0]funct2_o,
    output  wire    [2:0]funct3_o,
    output  wire    [6:0]funct7_o,
    output  wire    [20:0]imm,
    output  wire    c_flag_o
);
    logic   [6:0]op;
    logic   [1:0]bitlen;  //00:Undeined    01:16-bits  10:32-bits 11:64-bits
    logic   [4:0]rd;
    logic   [4:0]rs1;
    logic   [4:0]rs2;
    logic   [20:0]i;
    logic   [1:0]funct2;
    logic   [2:0]funct3;
    logic   [6:0]funct7;
    logic   c_flag;

//XLEN?
    always_comb begin
        if (rst_n == 1'b0) begin
            bitlen = 2'b00;
        end
        else begin
            if (instr[1:0] != 2'b11) begin
                bitlen = 2'b01;                //16-bits
            end
            else begin
                if (instr[5:2]!=3'b111) begin
                    bitlen = 2'b10;            //32-bits
                end
                else begin
                    if (instr[6]==1'b0) begin
                        bitlen = 2'b11;        //64-bits IGNORE THIS THE STANDARD IS NON-SENSE!
                    end
                    else begin
                        bitlen = 2'b00;
                    end
                end
            end
        end
        XLEN = bitlen;
    end

//decode
    always_comb begin : decoder
        if (rst_n == 1'b0) begin
            op  =  7'b0;               //Reset the opcode
            rd  =  5'd0;               //Reset rd
            rs1  =  5'd0;              //Reset rs1
            rs2  =  5'd0;              //Reset rs2
            i   =  21'd0;              //Reset imm
            funct2  =  2'd0;           //Reset funct2
            funct3  =  3'd0;           //Reset funct3
            funct7  =  7'd0;           //Reset funct7
            c_flag       =  1'b0;           //Reset c_flag
        end
        else begin
            if (bitlen == 2'b01) begin              // 16-bits
                if (c_en == 1'b1) begin
                    op  =  {5'd0,instr[1:0]};
                    funct3 = instr[15:13];
                    case (op)
                        2'b00: begin
                            funct2  =  2'd0;           //Reset funct2
                            funct7  =  7'd0;           //Reset funct7
                            c_flag       =  1'b0;           //Reset c_flag
                            if (instr[15:13] == 3'b000) begin                                   // C.ADDI4SPN
                                rd  =  instr[4:2]+4'd8;
                                rs1  =  5'd2;                                                   // rs1 = x2 (SP)
                                rs2  = 5'd0;                             
                                i   =  {instr[10:7],instr[12:11],instr[5],instr[6],2'd0};
                            end
                            else if (instr[15:13] == 3'b010 || instr[15:13] == 3'b110) begin         //C.LW & C.SW    
                                rs1 =  {instr[9:7]}+4'd8;
                                rs2  =  {instr[4:2]}+4'd8;
                                rd  =   5'd0;
                                i   =  {{13{instr[5]}},instr[5],instr[12:10],instr[6],2'b00};
                            end
                            else if (instr[15:13] == 3'b011 || instr[15:13] == 3'b111) begin         //C.LD & C.SD
                                rd  =  instr[4:2]+4'd8;    
                                rs1 =  instr[9:7]+4'd8;
                                rs2 =  5'd0;
                                i   =  {{13{instr[6]}},instr[6:5],instr[12:10],3'b000};
                            end
                            else begin
                                rd  =  5'd0;               //Reset rd
                                rs1 =  5'd0;               //Reset rs1 
                                rs2 =  5'd0;                //Reset rs2
                                i   =  21'd0;              //Reset imm
                            end
                        end
                        2'b01: begin
                            c_flag       =  1'b0;           //Reset c_flag
                            if (instr[15:13] == 3'b000 || instr[15:13] == 3'b001 ) begin               // C.ADDI & C.NOP & C.ADDIW
                                if (instr[11:7] != 5'b00000) begin
                                    i       =  {{15{instr[12]}},instr[12],instr[6:2]};
                                    rd      =  instr[11:7];
                                    rs1     =  instr[11:7];         //rs1 = rd
                                    rs2     =  5'd0;                //Reset rs2
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7 
                                end
                                else begin
                                    rd      =  5'd0;                //Reset rd
                                    rs1     =  5'd0;                //Reset rs1
                                    rs2     =  5'd0;                //Reset rs2
                                    i       =  21'b0;               //Reset imm
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                end
                            end
                            else if (instr[15:13] == 3'b010) begin                                  // C.LI
                                if (instr[11:7]!=5'd0) begin
                                    i       =  {{15{instr[12]}},instr[12],instr[6:2]};
                                    rd      =  instr[11:7];
                                    rs1     =  5'd0;                //rs1 = x0
                                    rs2     =  5'd0;                //Reset rs2
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                end
                                else begin
                                    rd      =  5'd0;                //Reset rd
                                    rs1     =  5'd0;                //Reset rs1
                                    rs2     =  5'd0;                //Reset rs2
                                    i       =  21'b0;               //Reset imm
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                end
                            end
                            else if (instr[15:13] == 3'b011) begin
                                if (instr[11:7] != 0 && instr[11:7] != 2) begin                                                 //C.LUI
                                    rd      =  instr[11:7];
                                    i       =  {{3{instr[12]}},instr[12],instr[6:2],12'd0};
                                    rs1     =  5'd0;                //rs1 = x0
                                    rs2     =  5'd0;                //Reset rs2
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                end
                                else begin
                                    if (instr[11:7] == 2) begin                                                                 //C.ADDI16SP
                                        rd      =  instr[11:7];
                                        i       =  {{11{instr[12]}},instr[12],instr[4:3],instr[5],instr[2],instr[6],4'b0000};
                                        rs1     =  instr[11:7];             //rs1 = rd = x2
                                        rs2     =  5'd0;                    //Reset rs2
                                        funct2  =  2'd0;                    //Reset funct2
                                        funct7  =  7'd0;                    //Reset funct7
                                    end
                                    else begin
                                        rd  =  5'b0;               //Reset rd
                                        rs1  =  5'b0;              //Reset rs1
                                        rs2  =  5'b0;              //Reset rs2
                                        i   =  21'd0;              //Reset imm
                                        funct2  =  2'b0;           //Reset funct2
                                        funct7  =  7'b0;           //Reset funct7
                                    end
                                end
                            end
                            else if (instr[15:13] == 3'b100) begin
                                if (instr[11:10] == 2'b00 || instr[11:10] == 2'b01 || instr[11:10] == 2'b10) begin              //C.SRLI & C.SRAI & C.ANDI
                                    i   =  {{15{instr[12]}},instr[12],instr[6:2]};
                                    rd  =  instr[9:7]+4'd8;
                                    funct2  =  instr[11:10];
                                    rs1  =  instr[9:7]+4'd8;            //rs1 = rd
                                    rs2  =  5'd0;                       //Reset rs2
                                    funct7  =  7'd0;                    //Reset funct7
                                end
                                else if (instr[11:10] == 2'b11) begin                                                                //C.SUB & C.XOR & C.OR & C.AND & C.SUBW & C.ADDW 
                                    funct2  =  instr[6:5];
                                    rd  =  instr[9:7]+4'd8;
                                    rs2 =  instr[4:2]+4'd8;
                                    funct7  =  {instr[15:10],1'b0};
                                    i = 21'd0;
                                    rs1 = instr[9:7]+4'd8;
                                end
                                else begin
                                    rd  =  5'd0;               //Reset rd
                                    rs1  =  5'd0;              //Reset rs1
                                    rs2  =  5'd0;              //Reset rs2
                                    i   =  21'd0;              //Reset imm
                                    funct2  =  2'd0;           //Reset funct2
                                    funct7  =  7'd0;           //Reset funct7
                                end
                            end
                            else if (instr[15:13] == 3'b101) begin                                                                   //C.J
                                i   =  {{9{instr[12]}},instr[12],instr[8],instr[10:9],instr[6],instr[7],instr[2],instr[11],instr[5:3],1'b0};
                                rd  =  5'd0;               //Reset rd
                                rs1  =  5'd0;              //Reset rs1
                                rs2  =  5'd0;              //Reset rs2
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                            end
                            else if (instr[15:13] == 3'b110 || instr[15:13] == 3'b111) begin                                         //C.BEQZ & C.BNEZ
                                rs1 =  instr[9:7]+4'd8;
                                i   =  {{12{instr[12]}},instr[12],instr[6:5],instr[2],instr[11:10],instr[4:3],1'b0};
                                rd  =  5'd0;               //Reset rd
                                rs2  =  5'd0;              //Reset rs2
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                            end
                            else begin
                                rd  =  5'd0;               //Reset rd
                                rs1  =  5'd0;              //Reset rs1
                                rs2  =  5'd0;              //Reset rs2
                                i   =  21'd0;              //Reset imm
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                            end
                        end
                        2'b10: begin
                            if (instr[15:13] == 3'b000) begin                                                                   //C.SLLI
                                rd      =  instr[11:7];
                                i       =  {{15{instr[12]}},instr[12],instr[6:2]};
                                rs1     =  instr[11:7];         //rs1 = rd
                                rs2     =  5'd0;                //Reset rs2
                                funct2  =  2'd0;                //Reset funct2
                                funct7  =  7'd0;                //Reset funct7
                                c_flag       =  1'b0;                //Reset c_flag
                            end
                            else if (instr[15:13] == 3'b010) begin
                                if (instr[11:7]!=5'd0) begin        //C.LWSP
                                    rd  =   instr[11:7];
                                    i   =   {{13{instr[3]}},instr[3:2],instr[12],instr[6:4],2'd0};
                                    rs1 =   5'd2;
                                    rs2 =   5'd0;
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                    c_flag       =  1'b0;                //Reset c_flag
                                end
                                else begin
                                    rd  =  5'd0;               //Reset rd
                                    rs1  =  5'd0;              //Reset rs1
                                    rs2  =  5'd0;              //Reset rs2
                                    i   =  21'd0;              //Reset imm
                                    funct2  =  2'd0;           //Reset funct2
                                    funct7  =  7'd0;           //Reset funct7
                                    c_flag       =  1'b0;           //Reset c_flag
                                end
                            end
                            else if (instr[15:13] == 3'b011) begin
                                if (instr[11:7]!=5'd0) begin        //C.LDSP
                                    rd  =   instr[11:7];
                                    i   =   {{12{instr[3]}},instr[4:2],instr[12],instr[6:5],3'd0};
                                    rs1 =   5'd2;
                                    rs2 =   5'd0;
                                    funct2  =  2'd0;                //Reset funct2
                                    funct7  =  7'd0;                //Reset funct7
                                    c_flag  =  1'b0;                //Reset c_flag
                                end
                                else begin
                                    rd  =  5'd0;               //Reset rd
                                    rs1  =  5'd0;              //Reset rs1
                                    rs2  =  5'd0;              //Reset rs2
                                    i   =  21'd0;              //Reset imm
                                    funct2  =  2'd0;           //Reset funct2
                                    funct7  =  7'd0;           //Reset funct7
                                    c_flag       =  1'b0;           //Reset c_flag
                                end
                            end
                            else if (instr[15:13] == 3'b100) begin
                                funct7  =  {instr[15:12],3'b000};
                                rs2     =  instr[6:2];                            
                                i       =  21'b0;               //Reset imm
                                funct2  =  2'd0;                //Reset funct2
                                if (instr[15:12] == 4'b1000) begin
                                    rd  =  instr[11:7];
                                    if (instr[11:7] != 5'd0 & instr[6:2] != 0) begin                    // C.MV
                                        c_flag   =  1'b1;
                                        rs1 =  5'd0;
                                        rd = instr[11:7];      
                                    end
                                    else begin                                                          // C.JR
                                        c_flag   =  1'b0;
                                        rs1 =  instr[11:7];         //rs1 = rd
                                        rd  =  5'd0;
                                    end
                                end
                                else if (instr[15:12] == 4'b1001) begin
                                    rs1  =  instr[11:7];
                                    if (instr[11:7] != 5'd0 & instr[6:2] == 0) begin                    // C.JALR
                                        rd  =  5'd1;                // rd = x1
                                        c_flag   =  1'b1;
                                    end
                                    else begin
                                        c_flag   =  1'b0;
                                        rd  =  instr[11:7];
                                    end
                                end
                                else begin
                                    rd  =  5'd0;               //Reset rd
                                    rs1  =  5'd0;              //Reset rs1
                                    rs2  =  5'd0;              //Reset rs2
                                    i   =  21'd0;              //Reset imm
                                    funct2  =  2'd0;           //Reset funct2
                                    funct7  =  7'd0;           //Reset funct7
                                    c_flag       =  1'b0;           //Reset c_flag
                                end
                            end
                            else if (instr[15:13] == 3'b111) begin //C.SDSP
                                rd  =  5'd0;               //Reset rd
                                rs1  =  5'd2;              //rs1 = x2
                                rs2  =  instr[6:2];
                                i   =  {{12{instr[9]}},instr[9:7],instr[12:10],3'd0};
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                                c_flag       =  1'b0;           //Reset c_flag
                            end
                            else if (instr[15:13] == 3'b110) begin //C.SWSP   
                                rd  =  5'd0;               //Reset rd
                                rs1  =  5'd2;              //rs1 = x2
                                rs2  =  instr[6:2];
                                i   =  {{13{instr[9]}},instr[9:7],instr[12:10],2'd0};
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                                c_flag       =  1'b0;           //Reset c_flag
                            end
                            else begin
                                rd  =  5'd0;               //Reset rd
                                rs1  =  5'd0;              //Reset rs1
                                rs2  =  5'd0;              //Reset rs2
                                i   =  21'd0;              //Reset imm
                                funct2  =  2'd0;           //Reset funct2
                                funct7  =  7'd0;           //Reset funct7
                                c_flag       =  1'b0;           //Reset c_flag
                            end
                        end
                        default: begin
                            rd  =  5'd0;               //Reset rd
                            rs1  =  5'd0;              //Reset rs1
                            rs2  =  5'd0;              //Reset rs2
                            i   =  21'd0;              //Reset imm
                            funct2  =  2'd0;           //Reset funct2
                            funct7  =  7'd0;           //Reset funct7
                            c_flag       =  1'b0;           //Reset c_flag
                        end
                    endcase
                end
                else begin
                    op      =   7'b0;
                    funct3  =   3'd0;
                    rd      =   5'd0;               //Reset rd
                    rs1     =   5'd0;              //Reset rs1
                    rs2     =   5'd0;              //Reset rs2
                    i       =   21'b0;              //Reset imm
                    funct2  =   2'd0;           //Reset funct2
                    funct7  =   7'd0;           //Reset funct7
                    c_flag  =   1'b0;           //Reset c_flag
                end
            end
            else begin                              // 32/64-bits
                c_flag       =  1'b0;           //Reset c_flag
                op  =  instr[6:0];
                if (op == 7'b0110111 || op ==7'b0010111) begin      //U-type
                    rd = instr[11:7];
                    i = {instr[31],instr[31:12]};
                    rs1  =  5'd0;              //Reset rs1
                    rs2  =  5'd0;              //Reset rs2
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                    funct3  =  3'd0;           //Reset funct3
                end
                else if (op == 7'b1101111) begin                         //J-type
                    rd = instr[11:7];
                    i = {instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
                    rs1  =  5'd0;              //Reset rs1
                    rs2  =  5'd0;              //Reset rs2
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                    funct3  =  3'd0;           //Reset funct3
                end
                else if (op == 7'b1100111 || op == 7'b0000011 || op == 7'b0010011|| op == 7'b0011011 || op == 7'b0011011) begin             //I-type
                    rd = instr[11:7];
                    funct3  =  instr[14:12];
                    rs1 =  instr[19:15];
                    i   = {{9{instr[31]}},instr[31:20]};
                    rs2  =  5'd0;              //Reset rs2
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                end
                else if (op == 7'b0110011|| op==7'b0111011) begin                   //R-type
                    rd  =  instr[11:7];
                    funct3  =  instr[14:12];
                    rs1 =  instr[19:15];
                    rs2 =  instr[24:20];
                    funct7  =  instr[31:25];    
                    funct2  =  2'd0;           //Reset funct2
                    i   =   21'd0;
                end
                else if (op == 7'b1100011) begin                                    //B-type
                    funct3  =  instr[14:12];
                    rs1 =  instr[19:15];
                    rs2 =  instr[24:20];
                    i   =  {{8{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
                    rd = 5'd0;
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                end
                else if (op == 7'b0100011) begin                                     //S-type
                    funct3  =  instr[14:12];
                    rs1 =  instr[19:15];
                    rs2 =  instr[24:20];
                    i   =  {{9{instr[31]}},instr[31:25],instr[11:7]};
                    rd  =  5'd0;              //Reset rd
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                end
                else if (op == 7'b0001111) begin
                    rd  =  instr[11:7];
                    funct3  =  3'b000;
                    rs1 =  instr[19:15];
                    i   =  {{9'd0},instr[31:20]};
                    rs2  =  5'd0;              //Reset rs2
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                end
                else if (op == 7'b1110011) begin
                    i   =  {{9'd0},instr[31:20]};
                    rd  =  5'd0;              //Reset rd
                    rs1  =  5'd0;              //Reset rs1
                    rs2  =  5'd0;              //Reset rs2
                    funct2  =  2'd0;           //Reset funct2
                    funct7  =  7'd0;           //Reset funct7
                    funct3  =  3'd0;           //Reset funct3
                end
                else begin
                    op  =  6'b0;               //Reset the opcode
                    rd  =  5'd0;               //Reset rd
                    rs1  =  5'd0;              //Reset rs1
                    rs2  =  5'd0;              //Reset rs2
                    i   =  21'd0;              //Reset imm
                    funct2  =  2'd0;           //Reset funct2
                    funct3  =  3'b0;           //Reset funct3
                    funct7  =  7'd0;           //Reset funct7
                end
            end
        end
    end

    assign  Wr_idx=rd;
    assign  R1_idx=rs1;
    assign  R2_idx=rs2;
    assign  funct2_o=funct2;
    assign  funct3_o=funct3;
    assign  funct7_o=funct7;
    assign  imm=i;
    assign  opcode=op;
//    assign  XLEN=bitlen;
    assign  c_flag_o=c_flag;
endmodule
