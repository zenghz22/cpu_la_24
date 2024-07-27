//如果我连续dirty，会怎么样

`include ".\defs.v"
/*
    对于N路组相联，共有H组，每组有N行，每行有W个字，即4W个Byte
    index为LOG_H位的组索引
    offset为LOG_W+2位的行内索引
    tag为32-`LOG_H-`LOG_W-2位的标签,定义为TAG_LEN
    总容量=2^`h * 2^`n * 2^`w * 32 bits
*/
module cache(
    clk,
    resetn,
//input from CPU
    op,
    addr_en,
    addr,
    wsize,
    wdata,    
//output to CPU
    rdata,
    rdata_valid,
    wdata_valid,
//read from RAM
    rd_req,
    rd_type,
    rd_addr,
    rd_rdy,
    ret_valid,
    ret_last,
    ret_data,
//write to RAM
    wr_req,
    wr_type,
    wr_addr,
    wr_wstrb,
    wr_size,
    wr_data,
    wr_rdy
);
input  wire         clk;
input  wire         resetn;
//input from CPU
input  wire         op,
input  wire         addr_en,
input  wire  [31:0] addr,
input  wire  [ 1:0] wsize,
input  wire  [31:0] wdata,
//output to CPU
output wire         rdata_valid
output wire         rdata,
//read from RAM
output wire         rd_req;     //cache向RAM请求读取之
output wire [ 2:0]  rd_type; //3'b000-BYTE  3'b001-HALFWORD 3'b010-WORD 3'b100我不清楚
output wire [31:0]  rd_addr; //
input  wire         rd_rdy; //RAM准备好被cache读取
input  wire         ret_valid; //RAM被cache读取有效
input  wire         ret_last;  //RAM读取完成
input  wire [31:0]  ret_data;//
//write to RAM
output wire         wr_req;     //cache向RAM请求写入之
output wire [ 2:0]  wr_type; //同rd_type
output wire [31:0]  wr_addr; //
output wire [ 3:0]  wr_wstrb; //wr_data的掩码
output wire[127:0]  wr_data;  //    
input  wire         wr_rdy; //RAM准备好被cache写入

wire [`LOG_H-1:0]        index;
wire [`LOG_W+1:0]        offset;
wire [`TAG_LEN-1:0]      tag;
assign index = addr[`LOG_H+`LOG_W+1:`LOG_W+2      ];
assign tag   = addr[31           :`LOG_H+`LOG_W+2];
assign offset= addr[`LOG_W+1      :0            ];

//CPU向cache发送请求，暂存至cpubuf中
reg   [67:0] cpubuf;
wire         op_r,
wire         addr_en_r,
wire  [31:0] addr_r,
wire  [`TAG_LEN-1:0]    tag_r;
wire  [`LOG_H-1:0]      index_r;
wire  [`LOG_W+1:0]      offset_r;
wire  [ 1:0] wsize_r,
wire  [31:0] wdata_r,
always @ (posedge clk) begin
    if (~resetn) begin
        cpubuf <= 68'b0;
    end
    else if(valid)begin
        cpubuf <= {op,addr_en,addr,wsize,wdata};
    end
end
assign   {op_r,addr_en_r,addr_r,wsize_r,wdata_r} = cpubuf;
assign   {tag_r,index_r,offset_r} = addr_r;

/*cache的存储空间分为：
标签存储（tag_ram）：一读读一组N个
数据存储（data_bank）：
*/
//tag_ram
wire               tag_ram_we      [`N-1:0];
wire [`LOG_H-1:0]   tag_ram_index;
wire [`TAG_LEN-1:0] tag_ram_wdata   [`N-1:0]; 
wire [`TAG_LEN-1:0] tag_ram_rdata   [`N-1:0];

tag_ram my_tag_ram(
    .clk(clk),
    .resetn(resetn),
    .we(tag_ram_we),
    .addr(tag_ram_index),
    .din(tag_ram_rdata),
    .dout(tag_ram_wdata)
)

//V位和D位
reg  tag_dirty [`H-1:0][`N-1:0];
reg  tag_valid [`H-1:0][`N-1:0];

always @ (posedge clk) begin
    if (~resetn) begin
        for(integer i=0;i<`H;i+=1)
            for(integer j=0;j<`N;j+=1)begin
                tag_dirty[i][j] <= 0;
                tag_valid[i][j] <= 0;
            end
    end                
end

//Cache计数器,为了LRU算法
reg   tag_count [`H-1:0][`N-1:0];
//LRU等待完善
wire [`LOG_N-1:0] replace_way;

//data_bank
wire               data_ram_we      [`W-1:0];
wire               data_ram_replace;//等价于data_ram_we全为1
wire [`LOG_H-1:0]   data_ram_index;
wire [`LOG_N-1:0]   data_ram_way  ;
wire [`LOG_W-1:0]   data_ram_offset;
wire [31:0] data_ram_wdata   [`W-1:0];//一次写一行
wire [31:0] data_ram_rdata   [`W-1:0];//一次读一行

data_ram my_data_ram(
    .clk(clk),
    .resetn(resetn),
    .we(data_ram_we),
    .replace(data_ram_replace),
    .index(data_ram_index),
    .way(data_ram_way),
    .din(data_ram_wdata),
    .dout(data_ram_rdata)
)


//控制信号



/*FSM的五个状态
IDLE
RW
MISS
REPLACE
REFILL */
parameter   IDLE    =3'b000;
parameter   RW      =3'b001;
parameter   MISS    =3'b010;
parameter   REPLACE =3'b011;
parameter   REFILL  =3'b100;

/*
assign  hit_way[0] = tag_valid[0][index_r] && (tag_r==tag_ram_rdata[0]);
assign  hit_way[1] = tag_valid[1][index_r] && (tag_r==tag_ram_rdata[1]);
assign  hit        = hit_way[0] || hit_way[1];
assign  hit_write  = (state ==LOOKUP) && we_r && hit;
assign  hit_write_hazard =(( (state== LOOKUP) && hit_write && valid && ~op && {index, offset} == {index_r, offset_r} )
                            || ((wrbuf_state== WRBUF_WRITE) && valid && ~op && offset[3:2]== offset_r[3:2]));
assign  load_res   = data_bank_rdata[hit_way[1]][offset_r[3:2]];                            

assign  rdata      = ret_valid? ret_data : load_res;
*/

//FSM
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

always@(*) begin    
    case(state)
        IDLE:
            if(valid&&hit)       next_state = RW;
            else if(valid&&~hit&&op)next_state = RW;
            else if(valid&&~hit&&~op) next_state = MISS;
            else                 next_state = IDLE;
        RW:
            if(valid&&hit)       next_state = RW;
            else if(valid&&~hit&&op)next_state = RW;
            else if(valid&&~hit&&~op) next_state = MISS;
            else                 next_state = IDLE;
        MISS：
            if(op_r&&ret_valid&&ret_last)next_state = IDLE;
            if(往AXI写完了)next_state = REFILL; 
            else next_state =MISS;
        REFILL:
            if(ret_last)next_state = IDLE;
    endcase
end

wire tag_hit   [`N-1:0];
wire hit;
wire hit_way [`LOG_N-1:0];
wire dirty;

assign  tag_ram_index = index;
assign  hit = 0;

if(state == IDLE ||state == RW ) begin
    //tag比较
    for(integer j=0;j<`N;j+=1)begin
        tag_hit[j] = (tag_valid[index][j])&&(tag==tag_ram_rdata[j]) 
        if(tag_hit[j])hit_way = j;
        hit = hit ||tag_hit[j];
        
    end
    //命中了，分为写和读两种情况
    if(valid&&hit&&op)begin
        tag_valid[index][hit_way] =1'b1;
        tag_dirty[index][hit_way] =1'b1;
        data_ram_index = index;
        data_ram_offset= offset;
        data_ram_way   = hit_way;
        data_ram_we[offset] =1'b1;
        data_ram_wdata[offset] = wdata;
    end
    else if(valid&&hit&&~op)begin
        data_ram_index = index;
        data_ram_offset= offset;
        data_ram_way   = hit_way;
    end
    //上一拍发出了读/写指令并命中，这一拍返回，同时正常接收读写指令
    if(state==RW && op_r)begin
        w_next_statedata_valid = 1'b1;
    end
    else if(state==RW && ~op_r)begin
        rdata = data_ram_rdata[offset_r];
        rdata_valid =1'b1;
    end
    //MISS了，但是写，比较好处理
    if(valid&&~hit&&op)begin
        tag_valid[index][replace_way] =1'b1;
        tag_dirty[index][replace_way] =1'b1;
        data_ram_index = index;
        data_ram_offset= offset;
        data_ram_way   = replace_way;
        data_bank_we[replace_way] =1;
        data_ram_wdata[replace_way] = wdata;
        tag_ram_index =index;
        tag_ram_we[replace_way]=1;
        tag_ram_wdata[replace_way]=tag;
        dirty =tag_dirty[index][hit_way];
    end
    //MISS了，是读，不好处理，要阻塞
    if(valid&&~hit&&~op)begin
        rd_req  = 1'b1;
        rd_type = 3'b010;
        rd_addr = addr; 
        rd_size = //N个32位
        
        dirty=tag_dirty[index][replace_way];
    end
end

if(state == MISS)begin
    rdata_valid =1'b0;
end

reg [`LOG_W-1:0] refill_count;//充当一个0~W计数器的作用

always @(posedge clk)begin
    if(state==MISS && next_state == REFILL)begin
        refill_count = (`LOG_W)'b0;
    end
    else if(state == REFILL)begin
        refill_count <=refill_count + 1'b1;
    end
end

if(state == REFILL)begin
    if(ret_valid)begin
        data_ram_we[refill_count] =1'b1;
        data_ram_index  = index_r;
        data_ram_way    = replace_way;
        data_ram_wdata[refill_count] = ret_data;
        //如果从AXI返回的时候到了CPU要求的这个字，直接返回给CPU
        if(refill_count == offset_r)begin
            rdata = ret_data;
            rdata_valid = 1'b1;
        end
    end    
    if(ret_valid && ret_last)begin
        tag_valid[index_r][replace_way] = 1'b1;
    end
end
    
//如果tag比较发生了dirty，把另一个状态机wirte_buf置为1,把要被写回的行放入wrbuf
WRBUF_IDLE
WRBUF_WRITE*/
parameter   WRBUF_IDLE =0;
parameter   WRBUF_WRITE=1;
reg wrbuf_state;
reg wrbuf_next_state;
always@(posedge clk)begin
    if(!resetn)begin
        state <= WRBUF_IDLE;
    end
    else begin
        state <= next_state;
    end
end
always@(*) begin    
    case(wrbuf_state)
        WRBUF_IDLE:
            if(valid&&~hit&&dirty) wrbuf_next_state = WRBUF_WRITE;
            else                wrbuf_next_state = WRBUF_IDLE;
        WRBUF_WRITE:
            if(wr_rdy)          wrbuf_next_state = IDLE;
            else                wrbuf_next_state = WRBUF_WRITE
    endcase
end
reg [32*`W-1:0]  write_buf_data;
reg [31    :0]  write_buf_addr;
always@(posedge clk)begin
    if(valid&&~hit&&dirty)begin
        write_buf_addr <= {tag_ram_rdata[replace_way],data_ram_index,data_ram_offset,2'b0} ;
        for(integer k=0;k<`W;k+=1)begin
            write_buf_data[k*32+31 : k*32] <= data_ram_rdata;
        end
    end
end
if(wrbuf_state==WRBUF_WRITE)begin
    wr_req      = 1'b1;
    wr_type     = 3'b010;
    wr_addr     = write_buf_addr;
    wr_wstrb    = 4'hf;
    wr_size     = //N个32位;
    wr_data     = write_buf_data;
end

endmodule