`include ".\defs.v"
module tag_ram(
    input               clk,
    input               resetn,
    input               we  [N-1:0],
    input [LOG_H-1:0]   addr,
    input [TAG_LEN-1:0] din ,
    output[TAG_LEN-1:0] dout[N-1:0]
);

reg [TAG_LEN-1:0] ram [H-1:0][N-1:0];
always @(posedge clk)begin
    if(~resetn)begin
        for(integer i=0;i<H;i+=1)begin
            for(integer j=0;j<N;j+=1)begin
                ram[i][j] <= TAG_LEN'b0;
            end
        end 
    end
    else begin
        for(integer j=0;j<N;j+=1)begin 
            if(we[j]) ram[addr][j] <=din;
        end        
    end
end
for(integer j=0;j<N;j+=1)begin
    assign  dout[j] = ram[addr][j];
end
endmodule