`include ".\defs.v"
module data_ram(
    input                   clk,
    input                   reset,
    input  wire             we     [W-1:0];
    input  wire             replace;//等价于data_ram_we全为1
    input  wire [LOG_H-1:0] index;
    input  wire [LOG_N-1:0] way  ;
    input  wire [31:0]      din    [W-1:0];//一次写一行
    output wire [31:0]      dout   [W-1:0]//一次读一行
);

reg [31:0] ram [H-1:0][N-1:0][W-1:0];

always @(posedge clk)begin
    if(~resetn)begin
        for(integer i=0;i<H;i+=1)begin
            for(integer j=0;j<N;j+=1)begin
                for(integer k=0;k<W;k+=1)begin
                    ram[i][j][k] <= 32'b0;
                end
            end
        end 
    end
    else begin
        for(integer k=0;k<W;k+=1)begin 
            if(we[k]||replace) ram[index][way][k] <=din[k];
        end        
    end
end
for(integer k=0;k<W;k+=1)begin
    assign  dout[k] = ram[index][way][k];
end
endmodule