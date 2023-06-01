module rv_reg (
    input   wire   clk,
    input   wire   rst_n,
    input   wire   [4:0]Wr_idx,
    input   wire   [4:0]R1_idx,
    input   wire   [4:0]R2_idx,
    input   wire   [63:0]Data_in,
    input   wire   wr_en,
    output  wire   [63:0]out1,
    output  wire   [63:0]out2,
    output  wire   [7:0]gpio
);

    reg     [63:0]regs[0:31];  // 32 64-bits regs
    
    logic     [63:0]rs1_data;
    logic     [63:0]rs2_data;
    logic     [7:0]gpio_data;

    always_ff @( posedge clk ) begin
        if (rst_n == 1'b0) begin
            // Clear the RF
            for (int i = 0; i < 32; i = i + 1) begin
                regs[i] = 0;
            end
            regs[2] = 16'h7fff;
        end 
        else begin
            if (wr_en == 1'b1) begin
                if (Wr_idx != 5'd0) begin
                    regs[Wr_idx]    =  Data_in;
                end
                else begin
                    regs[Wr_idx]    =  5'd0;
                end
            end
        end
    end

    //Read
    always_comb begin
        rs1_data = regs[R1_idx];
        rs2_data = regs[R2_idx];
    end
    
    always_comb begin
        gpio_data = regs[31][7:0];
    end

    assign  out1    =   rs1_data;
    assign  out2    =   rs2_data;
    assign  gpio    =   gpio_data;

endmodule
