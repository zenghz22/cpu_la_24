`include "..\defs.v"
module reg_mm2_wb (
//output

//input
            clk,
            rst_n,
            flush,
            wen,
            mm2_exe_out,
            mm2_reg_d,
            mm2_op,
            mm2_op_type,
            mm2_rdata,
            mm2_mm_access_sz,
            mm2_reg_d_wen,
            mm2_pc);

input wire clk;
input wire rst_n;
input wire flush;
input wire wen;
input wire [31:0] mm2_exe_out;
input wire [4:0] mm2_reg_d;
input wire [7:0] mm2_op;
input wire [2:0] mm2_op_type;
input wire [31:0] mm2_rdata;
input wire [1:0] mm2_mm_access_sz;
input wire mm2_reg_d_wen;
input wire [31:0] mm2_pc;

reg [31:0] exe_out;
reg [4:0] reg_d;
reg [7:0] op;
reg [2:0] op_type;
reg [31:0] rdata;
reg [1:0] mm_access_sz;
reg reg_d_wen;
reg [31:0] pc;

always @(posedge clk ) begin
    if(!rst_n) begin
        exe_out <= 32'b0;
        reg_d <= 5'b0;
        op <= 8'b0;
        op_type <= 3'b0;
        rdata <= 32'b0;
        mm_access_sz <= 2'b0;
        reg_d_wen <= 1'b0;
        pc <= 32'b0;
    end
    else if(wen) begin
        exe_out <= mm2_exe_out;
        reg_d <= mm2_reg_d;
        op <= mm2_op;
        op_type <= mm2_op_type;
        rdata <= mm2_rdata;
        reg_d_wen <= mm2_reg_d_wen;
        mm_access_sz <= mm2_mm_access_sz;
        pc <= flush ? 32'b0 : mm2_pc;
    end
end
    
endmodule