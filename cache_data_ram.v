`include ".\defs.v"
module data_ram(
    input                   clk,
    input                   resetn,
    input  wire             we,
    input  wire [`LOG_H-1:0] index,
    input  wire [`LOG_N-1:0] way  ,
    input  wire [`LOG_W-1:0] offset,
    input  wire [31:0]      din   ,//一次写一字
    output reg [31:0]       dout  ,//一次读一行
    output wire [`W*32-1:0] dout_replace
);

reg [31:0] ram [`H-1:0][`N-1:0][`W-1:0];

always @(posedge clk)begin
    if(~resetn)begin
        for(integer i=0;i<`H;i+=1)begin
            for(integer j=0;j<`N;j+=1)begin
                for(integer k=0;k<`W;k+=1)begin
                    ram[i][j][k] <= 32'b0;
                end
            end
        end 
    end
    else begin 
        if(we) ram[index][way][offset] <= din;
        dout <= ram[index][way][offset];
    end
end
for(integer k;k<`W;k+=1)begin
    dout_replace[32*k+31 : 32*k] = ram[index][way][k];
end
endmodule