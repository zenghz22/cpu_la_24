`timescale 1ns / 1ps
`define CLK_PERIOD 10

module cache_tb();
reg         clk;
reg         resetn;

reg         icache_op; // 1写0读
reg         icache_valid; //有效
reg [31:0]  icache_addr; //地址
reg [1:0]   icache_wsize; //写数据大小
reg [31:0]  icache_wdata; //写数据

wire        icache_rdata_valid;
wire [31:0] icache_rdata;
wire        icache_rd_req;
wire [2:0]  icache_rd_type;
wire [31:0] icache_rd_addr;

wire         icache_rd_rdy; //RAM准备好被cache读取
wire         icache_ret_valid; //RAM被cache读取有效
wire         icache_ret_last; //RAM读取完成
wire[31:0]  icache_ret_data;

wire        icache_wr_req;
wire [2:0]  icache_wr_type;
wire [31:0] icache_wr_addr;
wire [3:0]  icache_wr_wstrb;
wire [127:0] icache_wr_data;

reg         dcache_op; // 1写0读
reg         dcache_valid; //有效
reg [31:0]  dcache_addr; //地址
reg [1:0]   dcache_wsize; //写数据大小
reg [31:0]  dcache_wdata; //写数据

wire        dcache_rdata_valid;
wire [31:0] dcache_rdata;
wire        dcache_rd_req;
wire [2:0]  dcache_rd_type;
wire [31:0] dcache_rd_addr;

wire        dcache_rd_rdy; //RAM准备好被cache读取
wire        dcache_ret_valid; //RAM被cache读取有效
wire        dcache_ret_last; //RAM读取完成
wire[31:0]  dcache_ret_data;

wire        dcache_wr_req;
wire [2:0]  dcache_wr_type;
wire [31:0] dcache_wr_addr;
wire [3:0]  dcache_wr_wstrb;
wire [127:0] dcache_wr_data;

wire wr_rdy; //RAM准备好被cache写入

wire wdata_valid;
wire wr_size;
//AXI 从Bridge到MEM
wire               aclk;
wire               aresetn;
// read req channel
wire  [ 3:0]      arid;
wire  [31:0]      araddr;
wire  [ 7:0]      arlen;
wire  [ 2:0]      arsize;
wire  [ 1:0]      arburst;
wire  [ 1:0]      arlock;
wire  [ 3:0]      arcache;
wire  [ 2:0]      arprot;
wire              	arvalid;
wire               	arready;
// read response channel
wire   	[ 3:0]      rid;
wire   	[31:0]      rdata;
wire   	[ 1:0]      rresp;
wire               	rlast;
wire               	rvalid;
wire              	rready;
// write req channel
wire  [ 3:0]      awid;
wire  [31:0]      awaddr;
wire  [ 7:0]      awlen;
wire  [ 2:0]      awsize;
wire  [ 1:0]      awburst;
wire  [ 1:0]      awlock;
wire  [ 3:0]      awcache;
wire  [ 2:0]      awprot;
wire              	awvalid;
wire               	awready;
// write data channel
wire  [ 3:0]      wid;
wire  [31:0]      wdata;
wire  [ 3:0]      wstrb;
wire              	wlast;
wire              	wvalid;
wire               	wready;
// write response channel
wire   	[ 3:0]      bid;
wire   	[ 1:0]      bresp;
wire               	bvalid;
wire              	bready;

data_mem U_data_mem(
        .s_aclk               (aclk               ),
    .s_aresetn            (aresetn            ),

    .s_axi_arid               (arid               ),
    .s_axi_araddr             (araddr             ),
    .s_axi_arlen              (arlen              ),
    .s_axi_arsize             (arsize             ),
    .s_axi_arburst            (arburst            ),
    //.s_axi_arlock             (arlock             ),
    //.s_axi_arcache            (arcache            ),
    //.s_axi_arprot             (arprot             ),
    .s_axi_arvalid            (arvalid            ),
    .s_axi_arready            (arready            ),

    .s_axi_rid                (rid                ),
    .s_axi_rdata              (rdata              ),
    .s_axi_rvalid             (rvalid             ),
    .s_axi_rlast              (rlast              ),
    .s_axi_rready             (rready             ),

    .s_axi_awid               (awid               ),
    .s_axi_awaddr             (awaddr             ),
    .s_axi_awlen              (awlen              ),
    .s_axi_awsize             (awsize             ),
    .s_axi_awburst            (awburst            ),
    //.s_axi_awlock             (awlock             ),
    //.s_axi_awcache            (awcache            ),
    //.s_axi_awprot             (awprot             ),
    .s_axi_awvalid            (awvalid            ),
    .s_axi_awready            (awready            ),

    //.s_axi_wid                (wid                ),
    .s_axi_wdata              (wdata              ),
    .s_axi_wstrb              (wstrb              ),
    .s_axi_wlast              (wlast              ),
    .s_axi_wvalid             (wvalid             ),
    .s_axi_wready             (wready             ),

    .s_axi_bid                (bid                ),
    .s_axi_bvalid             (bvalid             ),
    .s_axi_bready             (bready             )
);


axi_bridge U_axi_bridge(
    .aclk               (aclk               ),
    .aresetn            (aresetn            ),

    .arid               (arid               ),
    .araddr             (araddr             ),
    .arlen              (arlen              ),
    .arsize             (arsize             ),
    .arburst            (arburst            ),
    .arlock             (arlock             ),
    .arcache            (arcache            ),
    .arprot             (arprot             ),
    .arvalid            (arvalid            ),
    .arready            (arready            ),

    .rid                (rid                ),
    .rdata              (rdata              ),
    .rvalid             (rvalid             ),
    .rlast              (rlast              ),
    .rready             (rready             ),

    .awid               (awid               ),
    .awaddr             (awaddr             ),
    .awlen              (awlen              ),
    .awsize             (awsize             ),
    .awburst            (awburst            ),
    .awlock             (awlock             ),
    .awcache            (awcache            ),
    .awprot             (awprot             ),
    .awvalid            (awvalid            ),
    .awready            (awready            ),

    .wid                (wid                ),
    .wdata              (wdata              ),
    .wstrb              (wstrb              ),
    .wlast              (wlast              ),
    .wvalid             (wvalid             ),
    .wready             (wready             ),

    .bid                (bid                ),
    .bvalid             (bvalid             ),
    .bready             (bready             ),

    .icache_rd_req      (icache_rd_req      ),
    .icache_rd_type     (icache_rd_type     ),
    .icache_rd_addr     (icache_rd_addr     ),
    .icache_rd_rdy      (icache_rd_rdy      ),
    .icache_ret_valid   (icache_ret_valid   ),
    .icache_ret_last    (icache_ret_last    ),
    .icache_ret_data    (icache_ret_data    ),

    .dcache_rd_req      (dcache_rd_req      ),
    .dcache_rd_type     (dcache_rd_type     ),
    .dcache_rd_addr     (dcache_rd_addr     ),
    .dcache_rd_rdy      (dcache_rd_rdy      ),
    .dcache_ret_valid   (dcache_ret_valid   ),
    .dcache_ret_last    (dcache_ret_last    ),
    .dcache_ret_data    (dcache_ret_data    ),

    .dcache_wr_req      (dcache_wr_req      ),
    .dcache_wr_type     (dcache_wr_type     ),
    .dcache_wr_addr     (dcache_wr_addr     ),
    .dcache_wr_wstrb    (dcache_wr_wstrb    ),
    .dcache_wr_data     (dcache_wr_data     ),
    .dcache_wr_rdy      (dcache_wr_rdy      )
);

cache Icache(
    .clk(clk),
    .resetn(resetn),
    .op(icache_op),
    .valid(icache_valid),
    .addr(icache_addr),
    .wsize(icache_wsize),
    .wdata(icache_wdata),
    .rdata_valid(icache_rdata_valid),
    .wdata_valid(icache_wdata_valid),
    .rdata(icache_rdata),
    .rd_req(icache_rd_req),
    .rd_type(icache_rd_type),
    .rd_addr(icache_rd_addr),
    .rd_rdy(icache_rd_rdy),
    .ret_valid(icache_ret_valid),
    .ret_last(icache_ret_last),
    .ret_data(icache_ret_data),
    .wr_req(icache_wr_req),
    .wr_type(icache_wr_type),
    .wr_addr(icache_wr_addr),
    .wr_wstrb(icache_wr_wstrb),
    .wr_size(icache_wr_size),
    .wr_data(icache_wr_data),
    .wr_rdy(icache_wr_rdy)
);
cache Dcache(
    .clk(clk),
    .resetn(resetn),
    .op(dcache_op),
    .valid(dcache_valid),
    .addr(dcache_addr),
    .wsize(dcache_wsize),
    .wdata(dcache_wdata),
    .rdata_valid(dcache_rdata_valid),
    .wdata_valid(dcache_wdata_valid),
    .rdata(dcache_rdata),
    .rd_req(dcache_rd_req),
    .rd_type(dcache_rd_type),
    .rd_addr(dcache_rd_addr),
    .rd_rdy(dcache_rd_rdy),
    .ret_valid(dcache_ret_valid),
    .ret_last(dcache_ret_last),
    .ret_data(dcache_ret_data),
    .wr_req(dcache_wr_req),
    .wr_type(dcache_wr_type),
    .wr_addr(dcache_wr_addr),
    .wr_wstrb(dcache_wr_wstrb),
    .wr_size(dcache_wr_size),
    .wr_data(dcache_wr_data),
    .wr_rdy(dcache_wr_rdy)
);


assign aclk =clk;
assign aresetn =resetn;

always #(`CLK_PERIOD / 2) clk = ~clk;

integer i;
initial begin
    // set all inputs
    clk = 1;
    resetn = 0;
    dcache_op = 0;
    dcache_valid = 0;
    dcache_addr = 0;
    dcache_wsize = 0;
    dcache_wdata = 0;
    //dcache_rd_rdy = 0;
    //dcache_ret_valid = 0;
    //dcache_ret_last = 0;
    //dcache_ret_data = 0;
    //dcache_wr_rdy = 0;

    #200 resetn = 1;

    //挂机
    for (i = 0; i < 4; i = i + 1) begin
        #(`CLK_PERIOD);
        dcache_op = 0;
        dcache_valid = 0;
        dcache_addr = 32'h00000020 + i * 4;
        dcache_wsize = 2'b10;
        dcache_wdata = 32'haaaaaaaa + (i * 32'h11111111);
        // #(`CLK_PERIOD) dcache_valid = 0;
    end

    // 写入
    for (i = 0; i < 4; i = i + 1) begin
        #(`CLK_PERIOD);
        dcache_op = 1;
        dcache_valid = 1;
        dcache_addr = 32'h00000020 + i * 4;
        dcache_wsize = 2'b10;
        dcache_wdata = 32'haaaaaaaa + (i * 32'h11111111);
    end

    #(`CLK_PERIOD) $finish;
end

endmodule
