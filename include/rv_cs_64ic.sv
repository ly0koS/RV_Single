// RV64ic Contron Signal Generator
/*
Signal:
    INPUT:
        wire    neg,
        wire    zero,
        wire   [5:0]opcode,
        wire   [1:0]funct2_o,
        wire   [2:0]funct3_o,
        wire   [6:0]funct7_o,
        wire   [20:0]imm
    OUTPUT:
        wire    pc_sel,
        wire    pc_adder_sel,
        wire    OpA_Sel,
        wire    OpB_Sel,
        wire    alu_Sel,
        wire    reg_wr_en,
        wire    Data_wr_en,
        wire    Out_Sel
        wire    [63:0]imm_out
Control Table:
    
*/

module rv_cs_64ic (
    input   wire    rst_n,
    input   wire    [63:0]rs1,
    input   wire    [63:0]rs2,
    input   wire    [6:0]opcode,
    input   wire    [1:0]funct2,
    input   wire    [2:0]funct3,
    input   wire    [6:0]funct7,
    input   wire    [20:0]imm_in,
    input   wire    [1:0]bitlen,
    input   wire    c_flag,
    input   wire    stall_top,

    output  wire    stall_csg,
    output  wire    [1:0]pc_sel,
    output  wire    pc_adder_sel,
    output  wire    OpA_Sel,
    output  wire    OpB_Sel,
    output  wire    [3:0]alu_Sel,
    output  wire    reg_wr_en,
    output  wire    Data_wr_en,
    output  wire    [1:0]Out_Sel,
    output  wire    [63:0]imm_out
);
    logic    [1:0]pc_ctrl;
    logic    pc_adder_ctrl;
    logic    opa_ctrl;
    logic    opb_ctrl;
    logic    [3:0]alu_ctrl;
    logic    reg_en;
    logic    data_en;
    logic    [1:0]out_ctrl;
    logic    [63:0]imm_o;
    logic    zero;
    logic    neg;
    logic    stall;

    always_comb begin
        zero    =   (rs1 == rs2) ? 1'b1 : 1'b0;
        neg     =   (rs1 < rs2) ? 1'b1 : 1'b0;
    end


    always_comb begin
       if (rst_n == 1'b0) begin 
            pc_ctrl         =  2'b00;
            pc_adder_ctrl   =  1'b0;
            opa_ctrl        =  1'b0;
            opb_ctrl        =  1'b0;
            alu_ctrl        =  4'b0000;
            reg_en          =  1'b0;
            data_en         =  1'b0;
            out_ctrl        =  2'b00;
            imm_o           =  64'd0;
            stall           =  1'b0;
       end
       else begin
            case (bitlen)
                2'b01: begin                        // 16-bit
                    pc_adder_ctrl   =  1'b1;
                    if (opcode[1:0] == 2'b00) begin
                        case (funct3)
                            3'b000: begin                                   // C.ADDI4SPN
                                pc_ctrl         =  2'b00; 
                                opa_ctrl        =  1'b1;                            // OpA = rs1
                                opb_ctrl        =  1'b1;                            // OpB = imm
                                alu_ctrl        =  4'b0000;                         // ALU_Ctrl = Add
                                reg_en          =  1'b1;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b01;                           // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                stall           =  1'b0;
                            end 
                            3'b010: begin                                   // C.LW
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;                            // OpA = rs1
                                opb_ctrl        =  1'b1;                            // OpB = imm
                                alu_ctrl        =  4'b0000;                         // ALU_Ctrl = Add
                                reg_en          =  1'b1;                            // Enable Reg WR
                                data_en         =  1'b0;
                                out_ctrl        =  2'b10;                           // Output MEM
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b011: begin                                   // C.LD
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;                            // OpA = rs1
                                opb_ctrl        =  1'b1;                            // OpB = imm
                                alu_ctrl        =  4'b0000;                         // ALU_Ctrl = Add
                                reg_en          =  1'b1;                            // Enable Reg WR
                                data_en         =  1'b0;
                                out_ctrl        =  2'b10;                           // Output MEM
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b110: begin                                   // C.SW
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;                            // OpA = rs1
                                opb_ctrl        =  1'b1;                            // OpB = imm
                                alu_ctrl        =  4'b0000;                         // ALU_Ctrl = Add
                                reg_en          =  1'b0;                            // Disable Reg WR
                                data_en         =  1'b1;                            // Enable MEM Write
                                out_ctrl        =  2'b01;                           // Output ALU
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b111: begin                                   // C.SD
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;                            // OpA = rs1
                                opb_ctrl        =  1'b1;                            // OpB = imm
                                alu_ctrl        =  4'b0000;                         // ALU_Ctrl = Add
                                reg_en          =  1'b0;                            // Disable Reg WR
                                data_en         =  1'b1;                            // Enable MEM Write
                                out_ctrl        =  2'b01;                           // Output ALU
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            default: begin
                                pc_ctrl         =  2'b00;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b0;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  64'd0;
                                stall           =  1'b0;
                            end 
                        endcase
                    end
                    else if (opcode[1:0] == 2'b01) begin
                        stall           =  1'b0;                    
                        case (funct3)
                            3'b000: begin                                   // C.ADDI & C.NOP                              
                                pc_ctrl         =  2'b00;
                                
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0000;                     // ALU_Ctrl = Add
                                reg_en          =  1'b1;                        // Enable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end 
                            3'b001: begin                                   // C.ADDIW
                                pc_ctrl         =  2'b00;
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0000;                     // ALU_Ctrl = Add
                                reg_en          =  1'b1;                        // Enable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b010: begin                                   // C.LI  
                                pc_ctrl         =  2'b00;
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0000;                     // ALU_Ctrl = Add
                                reg_en          =  1'b1;                        // Enable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b011: begin                                   // C.LUI & C.ADDI16SP
                                pc_ctrl         =  2'b00;
                                
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0000;                     // ALU_Ctrl = Add
                                reg_en          =  1'b1;                        // Enable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b100: begin
                                if (funct7 != 7'd0) begin
                                    case (funct2)
                                        2'b00: begin                        // C.SRLI 
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b1;                        // OpA = rs1
                                            opb_ctrl        =  1'b1;                        // OpB = imm
                                            alu_ctrl        =  4'b0110;                     // ALU_Ctrl = SRL
                                            reg_en          =  1'b1;                        // Enable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end 
                                        2'b01: begin                        // C.SRAI
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b1;                        // OpA = rs1
                                            opb_ctrl        =  1'b1;                        // OpB = imm
                                            alu_ctrl        =  4'b0111;                     // ALU_Ctrl = SRA
                                            reg_en          =  1'b1;                        // Enable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        2'b10: begin                        // C.ANDI
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b1;                        // OpA = rs1
                                            opb_ctrl        =  1'b1;                        // OpB = imm
                                            alu_ctrl        =  4'b0010;                     // ALU_Ctrl = AND
                                            reg_en          =  1'b1;                        // Enable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        default: begin
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b0;
                                            opb_ctrl        =  1'b0;
                                            alu_ctrl        =  4'b0000;
                                            reg_en          =  1'b0;
                                            data_en         =  1'b0;
                                            out_ctrl        =  2'b00;
                                            imm_o           =  64'd0;
                                        end
                                    endcase
                                end
                                else begin
                                    case (funct7)   // NOTE: For easier decoding, I added '0' at the end to convert to funct7
                                        7'b1000110: begin
                                            case (funct2)
                                                2'b00: begin            // C.SUB
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0001;                     // ALU_Ctrl = SUB
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end 
                                                2'b01: begin            // C.XOR
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0100;                     // ALU_Ctrl = XOR
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end
                                                2'b10: begin            // C.OR
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0011;                     // ALU_Ctrl = OR
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end
                                                2'b11: begin            // C.AND
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0010;                     // ALU_Ctrl = AND
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end
                                                default: begin
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b0;
                                                    opb_ctrl        =  1'b0;
                                                    alu_ctrl        =  4'b0000;
                                                    reg_en          =  1'b0;
                                                    data_en         =  1'b0;
                                                    out_ctrl        =  2'b00;
                                                    imm_o           =  64'd0;
                                                end
                                            endcase
                                        end
                                        7'b1001110: begin
                                            case (funct2)
                                                2'b00: begin            // C.SUBW
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0001;                     // ALU_Ctrl = SUB
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end 
                                                2'b01: begin            // C.ADDW
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b1;                        // OpA = rs1
                                                    opb_ctrl        =  1'b0;                        // OpB = rs2
                                                    alu_ctrl        =  4'b0000;                     // ALU_Ctrl = ADD
                                                    reg_en          =  1'b1;                        // Enable Reg WR
                                                    data_en         =  1'b0;                        // Disable MEM Write
                                                    out_ctrl        =  2'b01;                       // Output ALU Result
                                                    imm_o           =  {{43{imm_in[20]}},imm_in};
                                                end
                                                default: begin
                                                    pc_ctrl         =  2'b00;
                                                    
                                                    opa_ctrl        =  1'b0;
                                                    opb_ctrl        =  1'b0;
                                                    alu_ctrl        =  4'b0000;
                                                    reg_en          =  1'b0;
                                                    data_en         =  1'b0;
                                                    out_ctrl        =  2'b00;
                                                    imm_o           =  64'd0;
                                                end
                                            endcase
                                        end
                                        default: begin
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b0;
                                            opb_ctrl        =  1'b0;
                                            alu_ctrl        =  4'b0000;
                                            reg_en          =  1'b0;
                                            data_en         =  1'b0;
                                            out_ctrl        =  2'b00;
                                            imm_o           =  64'd0;
                                        end 
                                    endcase
                                end
                            end
                            3'b101: begin                                   // C.J            
                                pc_ctrl         =  2'b01;                        // Next PC = ALU Result
                                
                                opa_ctrl        =  1'b0;                        // OpA = PC
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0000;                     // ALU_Ctrl = Add
                                reg_en          =  1'b0;                        // Disable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b110: begin                                   // C.BEQZ
                                
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b0;                        // OpB = rs2 = x0
                                alu_ctrl        =  4'b0001;                     // ALU_Ctrl = SUB
                                reg_en          =  1'b0;                        // Disable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (zero == 1'b1) begin                         // Jump take
                                    alu_ctrl    =  4'b0000;
                                    opa_ctrl    =  1'b0;                        // OpA = PC
                                    opb_ctrl    =  1'b1;                        // OpB = imm
                                    pc_ctrl     =  1'b1;                        // Next PC = ALU Result
                                end
                                else begin
                                    pc_ctrl     =  1'b0;
                                end
                            end
                            3'b111: begin                                   // C.BNEZ
                                
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b0;                        // OpB = rs2 = x0
                                alu_ctrl        =  4'b0001;                     // ALU_Ctrl = SUB
                                reg_en          =  1'b0;                        // Disable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (zero == 1'b0) begin                         // Jump take
                                    alu_ctrl    =  4'b0000;
                                    opa_ctrl    =  1'b0;                        // OpA = PC
                                    opb_ctrl    =  1'b1;                        // OpB = imm
                                    pc_ctrl     =  1'b1;                        // Next PC = ALU Result
                                end
                                else begin
                                    pc_ctrl     =  1'b0;
                                end
                            end
                            default: begin
                                pc_ctrl         =  2'b00;
                                
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b0;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  64'd0;
                            end 
                        endcase
                    end
                    else if (opcode[1:0] == 2'b10) begin
                        case (funct3)
                            3'b000: begin                               // C.SLLI
                                pc_ctrl         =  2'b00;
                                opa_ctrl        =  1'b1;                        // OpA = rs1
                                opb_ctrl        =  1'b1;                        // OpB = imm
                                alu_ctrl        =  4'b0101;                     // ALU_Ctrl = SLL
                                reg_en          =  1'b1;                        // Enable Reg WR
                                data_en         =  1'b0;                        // Disable MEM Write
                                out_ctrl        =  2'b01;                       // Output ALU Result
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                stall           =  1'b0;
                            end
                            3'b010: begin                               // C.LWSP       
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b1;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b10;
                                imm_o           =  {{43'd0,imm_in}};
                            end 
                            3'b011: begin                               // C.LDSP
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b1;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b10;
                                imm_o           =  {{43'd0,imm_in}};
                            end
                            3'b100: begin
                                stall           =  1'b0;                               
                                case (funct7)
                                    7'b1000000: begin
                                        if (c_flag  ==  1'b0) begin        // C.JR                    
                                            pc_ctrl         =  2'b01;                        // Next PC = ALU Result
                                                
                                            opa_ctrl        =  1'b1;                        // OpA = rs1
                                            opb_ctrl        =  1'b0;                        // OpB = rs2 = x0
                                            alu_ctrl        =  4'b0000;                     // ALU_Ctrl = ADD
                                            reg_en          =  1'b0;                        // Disable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        else if (c_flag  ==  1'b1) begin    // C.MV
                                            pc_ctrl         =  2'b00;                        
                                                
                                            opa_ctrl        =  1'b1;                        // OpA = rs1 = x0
                                            opb_ctrl        =  1'b0;                        // OpB = rs2
                                            alu_ctrl        =  4'b0000;                     // ALU_Ctrl = ADD
                                            reg_en          =  1'b1;                        // Disable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        else begin
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b0;
                                            opb_ctrl        =  1'b0;
                                            alu_ctrl        =  4'b0000;
                                            reg_en          =  1'b0;
                                            data_en         =  1'b0;
                                            out_ctrl        =  2'b00;
                                            imm_o           =  64'd0;
                                        end
                                    end 
                                    7'b1001000: begin
                                        if (c_flag  ==  1'b1) begin           // C.JALR
                                            pc_ctrl         =  2'b01;                        // Next PC = ALU Result
                                            pc_adder_ctrl   =  1'b1;                        // PC+2
                                            opa_ctrl        =  1'b1;                        // OpA = rs1
                                            opb_ctrl        =  1'b0;                        // OpB = rs2 = x0
                                            alu_ctrl        =  4'b0000;                     // ALU_Ctrl = ADD
                                            reg_en          =  1'b1;                        // Enable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        else if (c_flag  ==  1'b0) begin   // C.ADD
                                            pc_ctrl         =  2'b00;                        
                                                
                                            opa_ctrl        =  1'b1;                        // OpA = rs1 = rd
                                            opb_ctrl        =  1'b0;                        // OpB = rs2
                                            alu_ctrl        =  4'b0000;                     // ALU_Ctrl = ADD
                                            reg_en          =  1'b1;                        // Disable Reg WR
                                            data_en         =  1'b0;                        // Disable MEM Write
                                            out_ctrl        =  2'b01;                       // Output ALU Result
                                            imm_o           =  {{43{imm_in[20]}},imm_in};
                                        end
                                        else begin
                                            pc_ctrl         =  2'b00;
                                            
                                            opa_ctrl        =  1'b0;
                                            opb_ctrl        =  1'b0;
                                            alu_ctrl        =  4'b0000;
                                            reg_en          =  1'b0;
                                            data_en         =  1'b0;
                                            out_ctrl        =  2'b00;
                                            imm_o           =  64'd0;
                                        end
                                    end
                                    default: begin
                                        pc_ctrl         =  2'b00;
                                        
                                        opa_ctrl        =  1'b0;
                                        opb_ctrl        =  1'b0;
                                        alu_ctrl        =  4'b0000;
                                        reg_en          =  1'b0;
                                        data_en         =  1'b0;
                                        out_ctrl        =  2'b00;
                                        imm_o           =  64'd0;
                                    end
                                endcase
                            end
                            3'b110: begin                               // C.SWSP
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b1;
                                out_ctrl        =  2'b01;
                                imm_o           =  {{43'd0,imm_in}};
                            end
                            3'b111: begin                               // C.SDSP
                                if (stall_top == 1'b0) begin
                                    pc_ctrl         =  2'b10;
                                    stall           =  1'b1;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                    stall           =  1'b0;
                                end
                                opa_ctrl        =  1'b1;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b1;
                                out_ctrl        =  2'b01;
                                imm_o           =  {{43'd0,imm_in}};
                            end
                            default: begin
                                pc_ctrl         =  2'b00;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b0;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  64'd0;
                                stall           =  1'b0;
                            end 
                        endcase
                    end
                    else begin
                        pc_ctrl         =  2'b00;
                        opa_ctrl        =  1'b0;
                        opb_ctrl        =  1'b0;
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b0;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b00;
                        imm_o           =  64'd0;
                        stall           =  1'b0;
                    end
                end
                2'b10: begin                        // 32-bit
                    if (opcode == 7'b0010011) begin                 // I-type
                        opa_ctrl        =   1'b1;
                        opb_ctrl        =   1'b1;
                        pc_ctrl         =   1'b0;
                        pc_adder_ctrl   =   1'b0;
                        reg_en          =   1'b1;
                        data_en         =   1'b0;
                        out_ctrl        =   2'b01;
                        stall           =   1'b0;
                        case (funct3)
                            3'b000: begin                       // ADDI
                                alu_ctrl        =   4'b0000;
                                imm_o           =   {{43{imm_in[20]}},imm_in};                               
                            end 
                            3'b010: begin                       // SLTI
                                alu_ctrl        =   4'b1000;
                                imm_o           =   {{43{imm_in[20]}},imm_in};                                
                            end 
                            3'b011: begin                       // SLTIU
                                alu_ctrl        =   4'b1001;
                                imm_o           =   {{43'd0},imm_in};                               
                            end 
                            3'b100: begin                       // XORI
                                alu_ctrl        =   4'b0100;
                                imm_o           =   {{43{imm_in[20]}},imm_in};                                
                            end 
                            3'b110: begin                       // ORI
                                alu_ctrl        =   4'b0011;
                                imm_o           =   {{43{imm_in[20]}},imm_in};                                
                            end 
                            3'b111: begin                       // ANDI
                                alu_ctrl        =   4'b0010;
                                imm_o           =   {{43{imm_in[20]}},imm_in};                                
                            end
                            3'b001: begin                       // SLLI
                                alu_ctrl        =   4'b0101;
                                imm_o           =   {{59{imm_in[4]}},imm_in[4:0]};                                
                            end
                            3'b101: begin                       // SRLI & SRAI
                                if (imm_in[10]==1'b1) begin     // SRLI
                                    alu_ctrl    =   4'b0110; 
                                end
                                else begin                      // SRAI
                                    alu_ctrl    =   4'b0111;
                                end
                                imm_o           =   {{59{imm_in[4]}},imm_in[4:0]};                                
                            end
                            default: begin
                                alu_ctrl        =   4'b0000;
                                imm_o           =   64'd0; 
                            end                        
                        endcase
                    end
                    else if (opcode == 7'b0110011) begin            // R-type
                        opa_ctrl        =   1'b1;
                        opb_ctrl        =   1'b0;
                        pc_ctrl         =   1'b0;
                        pc_adder_ctrl   =   1'b0;
                        reg_en          =   1'b1;
                        data_en         =   1'b0;
                        out_ctrl        =   2'b01;
                        imm_o           =   64'd0;
                        stall           =   1'b0;
                        case (funct3)
                            3'b000: begin                       // ADD & SUB
                                if (funct7 == 0000000) begin    // ADD
                                    alu_ctrl    =   4'b0000;
                                end
                                else begin                      // SUB
                                    alu_ctrl    =   4'b0001;
                                end
                            end 
                            3'b001: begin                       // SLL
                                
                                alu_ctrl    =   4'b0101;
                            end
                            3'b010: begin                       // SLT
                                alu_ctrl        =   4'b1000;
                            end 
                            3'b011: begin                       // SLTU
                                alu_ctrl        =   4'b1001;
                            end 
                            3'b100: begin                       // XOR
                                alu_ctrl        =   4'b0100;
                            end 
                            3'b101: begin                       // SRL & SRA
                                if (funct7 == 0000000) begin    // SRL
                                    alu_ctrl    =   4'b0110;
                                end
                                else begin                      // SRA
                                    alu_ctrl    =   4'b0111;
                                end
                            end 
                            3'b110: begin                       // OR
                                alu_ctrl        =   4'b0011;
                            end 
                            3'b111: begin                       // AND
                                alu_ctrl        =   4'b0010;
                            end
                            default: begin
                                alu_ctrl        =   4'b0000;
                            end                    
                        endcase
                    end
                    else if (opcode == 7'b0110111) begin               // LUI
                        pc_ctrl         =  2'b00;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;        // OpA = rs1 = x0
                        opb_ctrl        =  1'b1;        // OpB = imm
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b01;
                        imm_o           =  {{43'd0},imm_in};
                        stall           =   1'b0;
                    end
                    else if (opcode == 7'b0010111) begin               // AUIPC
                        pc_ctrl         =  2'b00;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b0;        // OpA = PC
                        opb_ctrl        =  1'b1;        // OpB = imm
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b01;
                        imm_o           =  {{43'd0},imm_in};
                        stall           =   1'b0;
                    end
                    else if (opcode == 7'b1101111) begin               // JAL
                        pc_ctrl         =  2'b01;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b0;
                        opb_ctrl        =  1'b1;
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b00;
                        imm_o           =  {{43{imm_in[20]}},imm_in};
                        stall           =   1'b0;
                    end
                    else if (opcode == 7'b1100111) begin               // JALR
                        pc_ctrl         =  2'b01;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;
                        opb_ctrl        =  1'b1;
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b00;
                        imm_o           =  {{43{imm_in[20]}},imm_in};
                        stall           =   1'b0;
                    end
                    else if (opcode == 7'b1100011) begin
                        stall           =   1'b0;
                        case (funct3)
                            3'b000: begin                           // BEQ
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (zero == 1'b1) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            3'b001: begin                           // BNE
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (zero == 1'b0) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            3'b100: begin                           // BLT
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (neg == 1'b1) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            3'b101: begin                           // BGE
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                 if (neg == 1'b0) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            3'b110: begin                           // BLTU
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43'd0},imm_in};
                                 if (neg == 1'b1) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            3'b111: begin                           // BGEU
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b0;
                                opb_ctrl        =  1'b1;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43'd0},imm_in};
                                if (neg == 1'b0) begin
                                    pc_ctrl         =  2'b01;
                                end
                                else begin
                                    pc_ctrl         =  2'b00;
                                end
                            end
                            default: begin
                                pc_ctrl         =  2'b00;
                                pc_adder_ctrl   =  1'b0;
                                opa_ctrl        =  1'b1;
                                opb_ctrl        =  1'b0;
                                alu_ctrl        =  4'b0000;
                                reg_en          =  1'b0;
                                data_en         =  1'b0;
                                out_ctrl        =  2'b00;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end 
                        endcase
                    end
                    else if (opcode == 7'b0000011) begin               // LOAD
                        if (stall_top == 1'b0) begin
                            pc_ctrl         =  2'b10;
                            stall           =  1'b1;
                        end
                        else begin
                            pc_ctrl         =  2'b00;
                            stall           =  1'b0;
                        end
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;
                        opb_ctrl        =  1'b1;
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b10;
                        imm_o           =  {{43{imm_in[20]}},imm_in};
                    end
                    else if (opcode == 7'b0100011) begin               // STORE
                        if (stall_top == 1'b0) begin
                            pc_ctrl         =  2'b10;
                            stall           =  1'b1;
                        end
                        else begin
                            pc_ctrl         =  2'b00;
                            stall           =  1'b0;
                        end
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;
                        opb_ctrl        =  1'b1;
                        alu_ctrl        =  4'b0000;
                        reg_en          =  1'b0;
                        data_en         =  1'b1;
                        out_ctrl        =  2'b01;
                        imm_o           =  {{43{imm_in[20]}},imm_in};
                    end
                    else if (opcode == 7'b0011011) begin            // I-type
                        pc_ctrl         =  2'b00;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;
                        opb_ctrl        =  1'b1;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b01;
                        stall           =  1'b0;
                        case (funct3)
                            3'b000: begin                           // ADDW
                                reg_en          =  1'b1;
                                alu_ctrl        =  4'b0000;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end 
                            3'b001: begin                           // SLLIW
                                reg_en          =  1'b1;
                                alu_ctrl        =  4'b0101;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                            3'b101: begin                           // SRLIW & SRAIW
                                reg_en          =  1'b1;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                                if (funct7 == 7'd0) begin           // SRLIW
                                    alu_ctrl    =   4'b0110;
                                end
                                else begin                          // SRAIW
                                    alu_ctrl    =   4'b0111;
                                end
                            end
                            default: begin
                                reg_en          =  1'b0;
                                alu_ctrl        =  4'b0101;
                                imm_o           =  {{43{imm_in[20]}},imm_in};
                            end
                        endcase
                    end
                    else if (opcode == 7'b0111011) begin            // R-type
                        pc_ctrl         =  2'b00;
                        pc_adder_ctrl   =  1'b0;
                        opa_ctrl        =  1'b1;
                        opb_ctrl        =  1'b0;
                        data_en         =  1'b0;
                        out_ctrl        =  2'b01;
                        imm_o           =  64'd0;
                        stall           =  1'b0;
                        case (funct3)
                            3'b000: begin                           // ADDW & SUBW
                                reg_en          =   1'b1;
                                if (funct7 == 7'd0) begin           // ADDW
                                    alu_ctrl    =   4'b0000;
                                end
                                else begin                          // SUBW
                                    alu_ctrl    =   4'b0001;
                                end
                            end
                            3'b001: begin                           // SLLW
                                reg_en          =   1'b1;
                                alu_ctrl        =   4'b0000;
                            end
                            3'b101: begin                           // SRLW & SRAW
                                reg_en          =   1'b1;
                                if (funct7 == 7'd0) begin           // SRLW
                                    alu_ctrl    =   4'b0110;
                                end
                                else begin                          // SRAW
                                    alu_ctrl    =   4'b0111;
                                end
                            end
                            default: begin
                                reg_en          =   1'b0;
                                alu_ctrl        =   4'b0000;
                            end 
                        endcase 
                    end
                    else begin
                        alu_ctrl        =   4'b0000;
                        opa_ctrl        =   1'b1;
                        opb_ctrl        =   1'b1;
                        pc_ctrl         =   1'b0;
                        pc_adder_ctrl   =   1'b0;
                        reg_en          =   1'b0;
                        data_en         =   1'b0;
                        out_ctrl        =   2'b00;
                        imm_o           =   64'd0;
                        stall           =   1'b0;
                    end
                end
                2'b11: begin                        // 64-bit    
                    pc_ctrl         =  2'b00;
                    pc_adder_ctrl   =  1'b0;
                    opa_ctrl        =  1'b0;
                    opb_ctrl        =  1'b0;
                    alu_ctrl        =  4'b0000;
                    reg_en          =  1'b0;
                    data_en         =  1'b0;
                    out_ctrl        =  2'b00;
                    imm_o           =  64'd0;
                    stall           =  1'b0;
                end
                default: begin
                    pc_ctrl         =  2'b00;
                    pc_adder_ctrl   =  1'b0;
                    opa_ctrl        =  1'b0;
                    opb_ctrl        =  1'b0;
                    alu_ctrl        =  4'b0000;
                    reg_en          =  1'b0;
                    data_en         =  1'b0;
                    out_ctrl        =  2'b00;
                    imm_o           =  64'd0;
                    stall           =  1'b0;
                end
            endcase
       end 
    end



    assign pc_sel = pc_ctrl;
    assign pc_adder_sel = pc_adder_ctrl;
    assign OpA_Sel = opa_ctrl;
    assign OpB_Sel = opb_ctrl;
    assign alu_Sel = alu_ctrl;
    assign reg_wr_en = reg_en;
    assign Data_wr_en = data_en;
    assign Out_Sel = out_ctrl;
    assign imm_out = imm_o;
    assign stall_csg =stall;

endmodule