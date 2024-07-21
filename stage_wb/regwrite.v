`include "..\defs.v"
module regwrite (
//output
        gr_waddr,
        gr_wdata,
//input
        exe_out,
        reg_d,
        op,
        // op_type,
        wb_mm_access_sz,
        rdata);

input wire[31:0] exe_out;
input wire[4:0] reg_d;
input wire[7:0] op;
// input wire[3:0] op_type;
input wire[1:0] wb_mm_access_sz;
input wire[31:0] rdata;

output reg[4:0] gr_waddr;
output reg[31:0] gr_wdata;

always @(*) begin
    // if(op == `OP_LL || op == `OP_LD || op == `OP_LDU) begin
    //     gr_wdata = rdata;
    // end
    if(op == `OP_LD) begin
        case(wb_mm_access_sz)
            `ACCESS_SZ_BYTE: gr_wdata = {{24{rdata[7]}}, rdata[7:0]};
            `ACCESS_SZ_HALF: gr_wdata = {{16{rdata[15]}}, rdata[15:0]};
            default: gr_wdata = rdata;
        endcase
    end
    else if(op == `OP_LDU) begin
        case(wb_mm_access_sz)
            `ACCESS_SZ_BYTE: gr_wdata = {{24{1'b0}}, rdata[7:0]};
            `ACCESS_SZ_HALF: gr_wdata = {{16{1'b0}}, rdata[15:0]};
            default: gr_wdata = rdata;
        endcase
    end
    else if(op == `OP_LL) begin
        gr_wdata = rdata;
    end
    else begin
        gr_wdata = exe_out;
    end
end

always @(*) begin
    if(op == `OP_BL) 
        gr_waddr = 5'h01;
    else
        gr_waddr = reg_d;
end
    
endmodule