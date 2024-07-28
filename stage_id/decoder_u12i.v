`include "D:\1Learn\24Summer\Lxb\environment_for_la24\mycpu_env_2\myCPU\defs.v"
module decoder_u12i (
//output
            op,
//input
            inst);

input wire [31:0] inst;
output reg [7:0] op;

always @(*) begin
    case (inst[31:25])
        7'b0001010: op = `OP_LU12I;
        7'b0001110: op = `OP_PCADDU12I;
        default: op = `OP_INVALID;
    endcase
end

endmodule