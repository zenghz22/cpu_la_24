`include "D:\1Learn\24Summer\Lxb\environment_for_la24\mycpu_env_2\myCPU\defs.v"
module decoder_atomic (
//output
            op,
//input
            inst);

input wire [31:0] inst;
output reg [7:0] op;

always @(*) begin
    case (inst[31:24])
        8'b00100000: op = `OP_LL;
        8'b00100001: op = `OP_SC;
        default: op = `OP_INVALID;
    endcase
end

endmodule