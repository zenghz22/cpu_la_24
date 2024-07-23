
/*
    对于2^n路组相联，共有2^h组，每组有2^n行，每行有2^w个字
    index为H位的组索引
    offset为W位的行内索引
    
    8kB=2^h * 2^n * 2^w * 32 bits
    18=h+w+n+5

    暂定n=1, h=8, w=4 
*/
module cache(
    clk,
    resetn,
//input from CPU
    valid,
    op,
    //addr,
    index,
    tag,
    offset,
    wstrb,
    wdata,
//output to CPU
    addr_ok,
    data_ok,
    rdata,
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
    wr_data,
    wr_rdy
);
input  wire         clk;
input  wire         resetn;
//input from CPU
input  wire         valid;  //CPU向cache请求读/写有效
input  wire         op;     //写还是读
//input  wire [31:0]  addr;   //查找地址，包含tag+index+offset
input wire [19:0]             tag; 
input wire [7:0]              index;
input wire [3:0]              offset;
wire  [31:0] addr;
assign addr = {tag[19:0],index[7:0],offset[3:0]};
/*
assign index = addr[11: 4];
assign tag   = addr[31:12];
assign offset= addr[ 3: 0];
*/
input  wire [ 3:0]  wstrb;  //好像是wdata的掩码
input  wire [31:0]  wdata;  //
//output to CPU
output wire         addr_ok;//地址被cache成功接收
output wire         data_ok;//数据递出/写入成功
output wire [31:0]  rdata;  //
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



/*FSM的五个状态
IDLE
LOOKUP
MISS
REPLACE
REFILL */
parameter   IDLE    =3'b000;
parameter   LOOKUP  =3'b001;
parameter   MISS    =3'b010;
parameter   REPLACE =3'b011;
parameter   REFILL  =3'b100;
/*另一个状态机wirte_buf
WRBUF_IDLE
WRBUF_WRITE*/
parameter   WRBUF_IDLE =0;
parameter   WRBUF_WRITE=1;

reg [2:0] state;
reg [2:0] next_state;
reg wrbuf_state;
reg wrbuf_next_state;

//CPU向cache发送请求，暂存至cpubuf中
reg         cpubuf_we;
reg [ 3:0]  cpubuf_wstrb;
reg [31:0]  cpubuf_wdata;
reg [31:0]  cpubuf_addr;//addr由tag index offset组成
wire        we_r;
wire [ 3:0] wstrb_r;
wire [31:0] wdata_r;
wire [19:0] tag_r;
wire [ 7:0] index_r;
wire [ 3:0] offset_r;
always @ (posedge clk) begin
    if (~resetn) begin
        cpubuf_we <= 1'b0;
        cpubuf_wstrb <=4'b0;
        cpubuf_wdata <=32'b0;
        cpubuf_addr <=32'b0;
    end else if (valid && addr_ok) begin
        cpubuf_we <= op;
        cpubuf_wstrb <=wstrb;
        cpubuf_wdata <=wdata;
        cpubuf_addr <=addr;    
    end
end
assign  we_r = cpubuf_we;
assign  wstrb_r = cpubuf_wstrb;
assign  tag_r = cpubuf_addr[31:12];
assign  index_r = cpubuf_addr[11:4];
assign  offset_r = cpubuf_addr[3:0];
assign  wdata_r  = cpubuf_wdata;

wire        replace_way;//我要替换第几路，0还是1
wire        hit_write;
wire        hit_write_hazard;
wire        hit;    //是否hit的信号
wire [ 1:0] hit_way;    //两路的是否hit信号
wire [31:0] load_res;
//cache向RAM写数据，暂存至wrbuf中
reg  [48:0] wrbuf;
wire        wrbuf_way;
wire [ 7:0] wrbuf_index;
wire [ 3:0] wrbuf_offset;
wire [ 3:0] wrbuf_wstrb;
wire [31:0] wrbuf_wdata;
always @ (posedge clk) begin
    if (~resetn) begin
        wrbuf <= 49'b0;         
    end else if (hit_write) begin
        wrbuf <= {hit_way[1], index_r, offset_r, wstrb_r, wdata_r};
    end
end
assign {wrbuf_way, wrbuf_index, wrbuf_offset, wrbuf_wstrb, wrbuf_wdata} = wrbuf;

//cache miss时，向RAM要数据,数据的个数为rrcnt;
reg [1:0] rrcnt;
always @ (posedge clk) begin
    if (~resetn) begin
        rrcnt <= 2'b0;
    end else if (ret_valid & ~ret_last) begin
        rrcnt <= rrcnt + 2'd1;
    end else if (ret_valid &  ret_last) begin
        rrcnt <= 2'b0;
    end
end

//LFSR 伪随机数
reg [2:0] lfsr;
always @(posedge clk) begin
    if(~resetn)begin
        lfsr<= 3'b111;
    end
    else if(ret_valid & ret_last)begin
        lfsr <={lfsr[0],lfsr[2]^lfsr[0],lfsr[1]};
    end
end
assign replace_way=lfsr[0];

/*cache的存储空间分为：
标签存储（tag_ram）：两路ram, 用于存每一组两路的tag<共256组，每组两个
                    脏位dirty，共256组，每组两个
                    有效位valid，共256组，每组两个
数据存储（data_bank）:两路各四个RAM,用于存每行四个数据，共256组，每组八个
*/
//下面生成两个tag_ram
wire        tag_ram_we      [1:0];
wire [ 7:0] tag_ram_addr    [1:0];
wire [19:0] tag_ram_wdata   [1:0]; 
wire [19:0] tag_ram_rdata   [1:0];
assign tag_ram_we[0] = ret_valid & ret_last & ~replace_way;
assign tag_ram_we[1] = ret_valid & ret_last &  replace_way;
assign tag_ram_wdata[0] = tag_r;
assign tag_ram_wdata[1] = tag_r;
assign tag_ram_addr[0] = (state== IDLE)|| (state== LOOKUP) ? index : index_r;
assign tag_ram_addr[1] = (state== IDLE)|| (state== LOOKUP) ? index : index_r;
genvar i,j;
generate 
    for(i=0;i<2;i=i+1)begin
        TAG_RAM tag_ram_i(
            .clka(clk),
            .wea(tag_ram_we[i]),
            .addra(tag_ram_addr[i]),
            .dina (tag_ram_wdata[i]),
            .douta(tag_ram_rdata[i])
        );
    end
endgenerate
//V位和D位
reg [255:0] tag_dirty [1:0];
reg [255:0] tag_valid [1:0];

always @ (posedge clk) begin
    if (~resetn) begin
        tag_dirty[0] <= 256'b0;
        tag_dirty[1] <= 256'b0;
    end else if (wrbuf_state==WRBUF_WRITE) begin//hit_write
        tag_dirty[wrbuf_way][wrbuf_index] <= 1'b1;
    end else if (ret_valid & ret_last) begin 
        tag_dirty[replace_way][index_r] <= we_r;
    end
end

always @ (posedge clk) begin
    if (~resetn) begin
        tag_valid[0] <= 256'b0;
        tag_valid[1] <= 256'b0;
    end else if (ret_valid & ret_last) begin
        tag_valid[replace_way][index_r] <= 1'b1;
    end
end

//下面生成八个data_bank
wire [ 3:0] data_bank_we    [1:0][3:0];
wire [ 7:0] data_bank_addr  [1:0][3:0];
wire [31:0] data_bank_wdata [1:0][3:0];
wire [31:0] data_bank_rdata [1:0][3:0];

generate
    for (i = 0; i < 4; i = i + 1) begin
        assign data_bank_we[0][i] = {4{(wrbuf_state==WRBUF_WRITE) & (wrbuf_offset[3:2] == i) & ~wrbuf_way}} & wrbuf_wstrb
                                    | {4{ret_valid & rrcnt == i & ~replace_way}} & 4'hf;
        
        assign data_bank_we[1][i] = {4{(wrbuf_state==WRBUF_WRITE) & (wrbuf_offset[3:2] == i) & wrbuf_way}} & wrbuf_wstrb
                                    | {4{ret_valid & rrcnt == i &  replace_way}} & 4'hf;
        
        assign data_bank_wdata[0][i] = (wrbuf_state==WRBUF_WRITE) ? wrbuf_wdata ://hit_write
                                        (offset_r[3:2] != i || ~we_r)   ? ret_data    :
                                        {wstrb_r[3] ? wdata_r[31:24] : ret_data[31:24],
                                        wstrb_r[2] ? wdata_r[23:16] : ret_data[23:16],
                                        wstrb_r[1] ? wdata_r[15: 8] : ret_data[15: 8],
                                        wstrb_r[0] ? wdata_r[ 7: 0] : ret_data[ 7: 0]};
        
        assign data_bank_wdata[1][i] = (wrbuf_state==WRBUF_WRITE) ? wrbuf_wdata :
                                        (offset_r[3:2] != i || ~we_r)   ? ret_data    :
                                        {wstrb_r[3] ? wdata_r[31:24] : ret_data[31:24],
                                        wstrb_r[2] ? wdata_r[23:16] : ret_data[23:16],
                                        wstrb_r[1] ? wdata_r[15: 8] : ret_data[15: 8],
                                        wstrb_r[0] ? wdata_r[ 7: 0] : ret_data[ 7: 0]};    
    
    end
endgenerate
generate 
    for (i = 0; i < 4; i = i + 1) begin
        DATA_Bank_RAM data_bank_ram_i(
            .clka (clk),
            .wea  (data_bank_we[0][i]),
            .addra(data_bank_addr[0][i]),
            .dina (data_bank_wdata[0][i]),
            .douta(data_bank_rdata[0][i])
        );
    end
endgenerate
generate 
    for (i = 0; i < 4; i = i + 1) begin
        DATA_Bank_RAM data_bank_ram_i(
            .clka (clk),
            .wea  (data_bank_we[1][i]),
            .addra(data_bank_addr[1][i]),
            .dina (data_bank_wdata[1][i]),
            .douta(data_bank_rdata[1][i])
        );
    end
endgenerate

generate
    for (i=0; i<2; i=i+1) begin
        for (j=0; j<4; j=j+1) begin
            assign data_bank_addr[i][j] = (state== IDLE)|| (state== LOOKUP) ? index : index_r;
        end
    end
endgenerate

//控制信号


assign  hit_way[0] = tag_valid[0][index_r] && (tag_r==tag_ram_rdata[0]);
assign  hit_way[1] = tag_valid[1][index_r] && (tag_r==tag_ram_rdata[1]);
assign  hit        = hit_way[0] || hit_way[1];
assign  hit_write  = (state ==LOOKUP) && we_r && hit;
assign  hit_write_hazard =(( (state== LOOKUP) && hit_write && valid && ~op && {index, offset} == {index_r, offset_r} )
                            || ((wrbuf_state== WRBUF_WRITE) && valid && ~op && offset[3:2]== offset_r[3:2]));
assign  load_res   = data_bank_rdata[hit_way[1]][offset_r[3:2]];                            

assign  rdata      = ret_valid? ret_data : load_res;

//FSM
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
                if(hit_write_hazard) begin
                    next_state = IDLE;
                end
                else if(valid) begin
                    next_state = LOOKUP; 
                end       
                else begin
                    next_state = IDLE;
                end
            LOOKUP:
                if(hit_write_hazard) begin
                    next_state = IDLE;
                end
                else if(hit & ~valid) begin
                    next_state = IDLE;
                end
                else if (hit & valid) begin
                    next_state = LOOKUP;
                end  
                else if (~tag_dirty[replace_way][index_r] | ~tag_valid[replace_way][index_r]) begin
                    next_state = REPLACE;
                end
                else begin
                    next_state = MISS;
                end
            MISS:
                if (~wr_rdy) begin
                        next_state = MISS;
                end
                else begin
                    next_state = REPLACE;
                end
               
            REPLACE:
                if(~rd_rdy) begin
                    next_state = REPLACE;
                end
                else  begin
                    next_state = REFILL;
                end
            REFILL:
                if (ret_valid & ret_last) begin
                    next_state = IDLE;
                end else begin
                    next_state = REFILL;
                end
            default:
                next_state = IDLE;
        endcase
    end 

//WRBUF FSM
always @ (posedge clk) begin
        if (~resetn) begin
            wrbuf_state <= WRBUF_IDLE;
        end else begin
            wrbuf_state <= wrbuf_next_state;
        end
    end
    always @ (*) begin
        case (wrbuf_state)
            //没有待写的数据
            WRBUF_IDLE:
                if (hit_write) begin
                    wrbuf_next_state = WRBUF_WRITE;
                end else begin
                    wrbuf_next_state = WRBUF_IDLE;
                end
            //有待写的数据
            WRBUF_WRITE:
                if (hit_write) begin
                    wrbuf_next_state = WRBUF_WRITE;
                end else begin
                    wrbuf_next_state = WRBUF_IDLE;
                end
            default:wrbuf_next_state = WRBUF_IDLE;
        endcase
    end

//两侧接口的控制信号
assign wr_type= 3'b100;
assign rd_type= 3'b100;
assign rd_addr = {tag_r, index_r, offset_r};
assign wr_addr = {tag_ram_rdata[replace_way][19:0], index_r, offset_r};

reg wr_req_r;
assign wr_req= wr_req_r;
always @ (posedge clk) begin
    if (~resetn) begin
        wr_req_r <= 1'b0;
    end 
    else if( state==MISS & next_state==REPLACE)begin
        wr_req_r <=1'b1;
    end
    // else if (state==MISS & next_state==REPLACE & dirty_arr[replace_way][index_r] & valid_arr[replace_way][index_r] ) begin
    //     wr_req_r <= 1'b1; 
    // end 
    // else if(state==MISS & next_state==REPLACE & ( ~dirty_arr[replace_way][index_r] | ~valid_arr[replace_way][index_r]) )begin
    //     wr_req_r <= 1'b0;
    // end
    else if(wr_rdy)begin
        wr_req_r <= 1'b0;
    end
end
assign addr_ok =(state==IDLE) || ( state==LOOKUP & valid &hit & op) || (state==LOOKUP & valid & hit & ~op & ~hit_write_hazard);
assign data_ok =(state== LOOKUP && hit)|| (state==LOOKUP && we_r) || (~we_r && state==REFILL && ret_valid && rrcnt==offset_r[3:2]);
assign rd_req  =(state==REPLACE);
assign wr_wstrb = 4'hf;
assign wr_data  = {data_bank_rdata[replace_way][3],
                    data_bank_rdata[replace_way][2],
                    data_bank_rdata[replace_way][1],
                    data_bank_rdata[replace_way][0]};

endmodule