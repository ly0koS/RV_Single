module rv_pc (
    input   wire   clk,
    input   wire   rst_n,
    input   wire	[63:0]pc_in,
	output   wire	[63:0]pc_out
);

reg   [63:0]pc;

always_ff @( posedge clk ) begin : program_counter
    if (rst_n == 1'b0) begin
        pc<=64'b0;
    end
    else begin
        pc<=pc_in;
    end
end

assign pc_out=pc;

    
endmodule