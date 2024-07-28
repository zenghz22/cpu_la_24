`timescale 1ns / 1ps
`define CLK_PERIOD 10

module cache_tb();
    reg clk;
    reg resetn;
    reg op; // 1写0读
    reg valid; //有效
    reg [31:0] addr; //地址
    reg [1:0] wsize; //写数据大小
    reg [31:0] wdata; //写数据

    wire rdata_valid;
    wire [31:0] rdata;
    wire rd_req;
    wire [2:0] rd_type;
    wire [31:0] rd_addr;

    reg rd_rdy; //RAM准备好被cache读取
    reg ret_valid; //RAM被cache读取有效
    reg ret_last; //RAM读取完成
    reg [31:0] ret_data;

    wire wr_req;
    wire [2:0] wr_type;
    wire [31:0] wr_addr;
    wire [3:0] wr_wstrb;
    wire [127:0] wr_data;

    reg wr_rdy; //RAM准备好被cache写入

    wire wdata_valid;
    wire wr_size;

    cache U_cache(
              .clk(clk),
              .resetn(resetn),
              .op(op),
              .valid(valid),
              .addr(addr),
              .wsize(wsize),
              .wdata(wdata),
              .rdata_valid(rdata_valid),
              .wdata_valid(wdata_valid),
              .rdata(rdata),
              .rd_req(rd_req),
              .rd_type(rd_type),
              .rd_addr(rd_addr),
              .rd_rdy(rd_rdy),
              .ret_valid(ret_valid),
              .ret_last(ret_last),
              .ret_data(ret_data),
              .wr_req(wr_req),
              .wr_type(wr_type),
              .wr_addr(wr_addr),
              .wr_wstrb(wr_wstrb),
              .wr_size(wr_size),
              .wr_data(wr_data),
              .wr_rdy(wr_rdy)
          );

    always #(`CLK_PERIOD / 2) clk = ~clk;

    integer i;
    initial begin
        // set all inputs
        clk = 1;
        resetn = 0;
        op = 0;
        valid = 0;
        addr = 0;
        wsize = 0;
        wdata = 0;
        rd_rdy = 0;
        ret_valid = 0;
        ret_last = 0;
        ret_data = 0;
        wr_rdy = 0;

        #(`CLK_PERIOD) resetn = 1;

        // write
        for (i = 0; i < 4; i = i + 1) begin
            #(`CLK_PERIOD);
            op = 1;
            valid = 1;
            addr = 32'h00000020 + i * 4;
            wsize = 2'b10;
            wdata = 32'hAAAAAAAA + (i * 32'h11111111);
            // #(`CLK_PERIOD) valid = 0;
        end

        // read
        for (i = 0; i < 4; i = i + 1) begin
            #(`CLK_PERIOD);
            op = 0;
            valid = 1;
            addr = 32'h00000020 + i * 4;
            // #(`CLK_PERIOD) valid = 0;
        end

        #(`CLK_PERIOD) $finish;
    end

endmodule
