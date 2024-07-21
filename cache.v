
`define CACHE_H 8 
`define CACHE_W 4 
/*
    对于2^n路组相联，共有2^H组，每组有2^n行，每行有2^W个字
    index为H位的组索引
    offset为W位的行内索引
    
    8kB=2^H * 2^n * 2^W * 32 bits
    16=H+W+n+5
*/
module cache(
    clk,
    resetn,
//input from CPU
    valid,
    we,
    addr,
    wstrb,
    wdata,
//output to CPU
    addr_ok,
    data_ok,
    rdata,
//read from RAM
    ar,
    arsize,
    araddr,
    rready,
    rvalid,
    rlast,
    rdata,
//write to RAM
    aw,
    awsize,
    awaddr,
    wstrb,
    wdata,
    wready
);
//input from CPU
input  wire         valid;  //CPU向cache请求读/写有效
input  wire         we;     //写还是读
input  wire [31:0]  addr;   //查找地址，包含tag+index+offset
input  wire [ 3:0]  wstrb;  //好像是wdata的掩码
input  wire [31:0]  wdata;  //
//output to CPU
output wire         addr_ok;//地址被cache成功接收
output wire         data_ok;//数据递出/写入成功
output wire [31:0]  rdata;  //
//read from RAM
output wire         ar;     //cache向RAM请求读取之
output wire [ 2:0]  arsize; //3'b000-BYTE  3'b001-HALFWORD 3'b010-WORD 3'b100我不清楚
output wire [31:0]  araddr; //
input  wire         rready; //RAM准备好被cache读取
input  wire         rvalid; //RAM被cache读取有效
input  wire         rlast;  //RAM读取完成
input  wire [1'b1<<`CACHE_W-1:0]  rdata;//
//write to RAM
output wire         aw;     //cache向RAM请求写入之
output wire [ 2:0]  awsize; //同arsize
output wire [31:0]  awaddr; //
output wire [ 3:0]  awstrb; //awdata的掩码
output wire[1'b1<<`CACHE_W-1:0]  wdata;  //    
input  wire         wready; //RAM准备好被cache写入

wire [`CACHE_H-1:0]              index;
wire [`CACHE_W-1:0]              offset;
wire [32-`CACHE_W-`CACHE_H-1:0]   tag; 

assign tag   = addr[31          :`CACHE_W+`CACHE_H];
assign index = addr[`CACHE_H-1  :`CACHE_W         ];
assign offset= addr[`CACHE_W-1  : 0               ];

/*FSM的状态
IDLE
SEARCH
LOAD
WB
*/
parameter 

reg [2:0] state;
reg [2:0] next_state;

always@(posedge clk)begin
    if(!resetn)begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always@(*)begin
    case( state )
    
    endcase
end

endmodule