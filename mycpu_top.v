`include "C:\Users\Lenovo\Desktop\cdp_ede_local-master\mycpu_env\myCPU\defs.v"

module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // read req channel
    output [ 3:0] arid   ,  
    output [31:0] araddr ,  
    output [ 7:0] arlen  ,  
    output [ 2:0] arsize ,  
    output [ 1:0] arburst, 
    output [ 1:0] arlock ,  
    output [ 3:0] arcache,  
    output [ 2:0] arprot ,  
    output        arvalid,  
    input         arready, 
    // read response channel
    input [ 3:0]  rid    ,  
    input [31:0]  rdata  ,  
    input [ 1:0]  rresp  ,                 
    input         rlast  ,             
    input         rvalid , 
    output        rready ,  
    // write req channel
    output [ 3:0] awid   , 
    output [31:0] awaddr ,  
    output [ 7:0] awlen  ,  
    output [ 2:0] awsize ,  
    output [ 1:0] awburst,  
    output [ 1:0] awlock ,  
    output [ 3:0] awcache,  
    output [ 2:0] awprot ,  
    output        awvalid,  
    input         awready,     
    // write data channel
    output [ 3:0] wid    ,  
    output [31:0] wdata  ,  
    output [ 3:0] wstrb  ,  
    output        wlast  ,  
    output        wvalid , 
    input         wready ,     
    // write response channel
    input  [ 3:0] bid    ,      
    input  [ 1:0] bresp  ,        
    input         bvalid , 
    output        bready ,  
    
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

wire inst_cache_re;
wire [31:0] inst_cache_raddr;
wire [31:0] inst_cache_rdata;
wire inst_cache_hit;
wire inst_cache_we;
wire [31:0] inst_cache_waddr;
wire [31:0] inst_cache_wdata;
wire [2:0] inst_cache_access_sz;
wire data_cache_re;
wire [31:0] data_cache_raddr;
wire [31:0] data_cache_rdata;
wire data_cache_hit;
wire data_cache_we;
wire [31:0] data_cache_waddr;
wire [31:0] data_cache_wdata;
wire [2:0] data_cache_access_sz;

core U_core (
//output
            .inst_cache_re(inst_cache_re),
            .inst_cache_we(inst_cache_we),
            .inst_cache_raddr(inst_cache_raddr),
            .inst_cache_waddr(inst_cache_waddr),
            .inst_cache_wdata(inst_cache_wdata),
            .inst_cache_access_sz(inst_cache_access_sz),

            .data_cache_re(data_cache_re),
            .data_cache_we(data_cache_we),
            .data_cache_raddr(data_cache_raddr),
            .data_cache_waddr(data_cache_waddr),
            .data_cache_wdata(data_cache_wdata),
            .data_cache_access_sz(data_cache_access_sz),

            .debug_wb_pc(debug_wb_pc),
            .debug_wb_rf_we(debug_wb_rf_we),
            .debug_wb_rf_wnum(debug_wb_rf_wnum),
            .debug_wb_rf_wdata(debug_wb_rf_wdata),
//input
            .inst_cache_rdata(inst_cache_rdata),
            .inst_cache_hit(inst_cache_hit),
            .data_cache_rdata(data_cache_rdata),
            .data_cache_hit(data_cache_hit),
            .clk(clk),
            .rst_n(resetn));

fakecache U_fakecache_inst(
            .clk(clk),
            .rst_n(resetn),
            .cache_re(inst_cache_re),
            .cache_raddr(inst_cache_raddr),
            .cache_rdata(inst_cache_rdata),
            .cache_hit(inst_cache_hit),
            .cache_we(inst_cache_we),
            .cache_waddr(inst_cache_waddr),
            .cache_wdata(inst_cache_wdata),
            .cache_access_sz(inst_cache_access_sz),
            .sram_en(inst_sram_en),
            .sram_we(inst_sram_we),
            .sram_addr(inst_sram_addr),
            .sram_wdata(inst_sram_wdata),
            .sram_rdata(inst_sram_rdata));
    
fakecache U_fakecache_data(
            .clk(clk),
            .rst_n(resetn),
            .cache_re(data_cache_re),
            .cache_raddr(data_cache_raddr),
            .cache_rdata(data_cache_rdata),
            .cache_hit(data_cache_hit),
            .cache_we(data_cache_we),
            .cache_waddr(data_cache_waddr),
            .cache_wdata(data_cache_wdata),
            .cache_access_sz(data_cache_access_sz),
            .sram_en(data_sram_en),
            .sram_we(data_sram_we),
            .sram_addr(data_sram_addr),
            .sram_wdata(data_sram_wdata),
            .sram_rdata(data_sram_rdata));

axi_bridge U_axi_bridge (
            .clk(clk),
            .reset(reset),

            .arid(arid),
            .araddr(araddr),
            .arlen(arlen),
            .arsize(arsize),
            .arburst(arburst),
            .arlock(arlock),
            .arcache(arcache),
            .arprot(arprot),
            .arvalid(arvalid),
            .arready(arready),

            .rid(rid),
            .rdata(rdata),
            .rresp(rresp),
            .rlast(rlast),
            .rvalid(rvalid),
            .rready(rready),

            .awid(awid),
            .awaddr(awaddr),
            .awlen(awlen),
            .awsize(awsize),
            .awburst(awburst),
            .awlock(awlock),
            .awcache(awcache),
            .awprot(awprot),
            .awvalid(awvalid),
            .awready(awready),

            .wid(wid),
            .wdata(wdata),
            .wstrb(wstrb),
            .wlast(wlast),
            .wvalid(wvalid),
            .wready(wready),

            .bid(bid),
            .bresp(bresp),
            .bvalid(bvalid),
            .bready(bready),

            .inst_sram_req      (1'b1      ),
            .inst_sram_wr       (inst_cache_we       ),
            .inst_sram_size     (inst_cache_access_sz     ),
            .inst_sram_addr     (inst_cache_raddr----inst_cache_waddr     ),
            .inst_sram_wstrb    (1'b1    ),
            .inst_sram_wdata    (inst_sram_wdata    ),
            .inst_sram_addr_ok  (  ),
            .inst_sram_data_ok  (  ),
            .inst_sram_rdata    (inst_cache_rdata    ),

            .data_sram_req      (1'b1      ),
            .data_sram_wr       (data_cache_we       ),
            .data_sram_size     (data_cache_access_sz     ),
            .data_sram_addr     (data_cache_raddr---data_cache_waddr     ),
            .data_sram_wstrb    (1'b1    ),
            .data_sram_wdata    (data_cache_wdata    ),
            .data_sram_addr_ok  (  ),
            .data_sram_data_ok  (  ),
            .data_sram_rdata    (data_cache_rdata    )
);
endmodule





