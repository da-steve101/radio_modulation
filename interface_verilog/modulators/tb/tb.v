`timescale 1ns / 1ps

module testbench();

    parameter THRESHOLD_R_HOST = 256;
    parameter TOTAL_RECV = 800;
    parameter IQ_BW = 32; // I+Q sample bitwidth
    parameter IorQ_BW = 16; // I or Q sample bitwidth
    parameter C_S_AXI_CTRL_DATA_WIDTH = 32;
    parameter C_S_AXI_CTRL_ADDR_WIDTH = 6;
    parameter C_S_AXI_DATA_WIDTH = 32;

    parameter C_S_AXI_CTRL_WSTRB_WIDTH = (32 / 8);
    parameter C_S_AXI_WSTRB_WIDTH = (32 / 8);

    reg config_clk, samp_clk;
    reg config_rst_n, samp_rst_n;

    wire iq_out_tvalid;
    reg iq_out_tready;
    wire [IQ_BW-1:0] iq_out_tdata;

    reg s_axi_ctrl_awvalid = 0;
    wire s_axi_ctrl_awready;
    reg [C_S_AXI_CTRL_ADDR_WIDTH - 1:0] s_axi_ctrl_awaddr = 0;
    reg s_axi_ctrl_wvalid = 0;
    wire s_axi_ctrl_wready;
    reg [C_S_AXI_CTRL_DATA_WIDTH - 1:0] s_axi_ctrl_wdata = 0;
    reg [C_S_AXI_CTRL_WSTRB_WIDTH - 1:0] s_axi_ctrl_wstrb = 0;
    reg s_axi_ctrl_arvalid = 0;
    wire s_axi_ctrl_arready;
    reg [C_S_AXI_CTRL_ADDR_WIDTH - 1:0] s_axi_ctrl_araddr = 0;
    wire s_axi_ctrl_rvalid;
    reg s_axi_ctrl_rready = 0;
    wire [C_S_AXI_CTRL_DATA_WIDTH - 1:0] s_axi_ctrl_rdata;
    wire [1:0] s_axi_ctrl_rresp;
    wire s_axi_ctrl_bvalid;
    reg s_axi_ctrl_bready = 0;
    wire [1:0] s_axi_ctrl_bresp;

    Top # (
        .IQ_BW(IQ_BW),
        .IorQ_BW(IorQ_BW)
    ) DUT (
        .config_clk(config_clk),
        .config_rst_n(config_rst_n),
        .samp_clk(samp_clk),
        .samp_rst_n(samp_rst_n),
        .iq_out_TREADY(iq_out_tready),
        .iq_out_TVALID(iq_out_tvalid),
        .iq_out_TDATA(iq_out_tdata),
        .s_axi_ctrl_AWVALID(s_axi_ctrl_awvalid),
        .s_axi_ctrl_AWREADY(s_axi_ctrl_awready),
        .s_axi_ctrl_AWADDR(s_axi_ctrl_awaddr),
        .s_axi_ctrl_WVALID(s_axi_ctrl_wvalid),
        .s_axi_ctrl_WREADY(s_axi_ctrl_wready),
        .s_axi_ctrl_WDATA(s_axi_ctrl_wdata),
        .s_axi_ctrl_WSTRB(s_axi_ctrl_wstrb),
        .s_axi_ctrl_ARVALID(s_axi_ctrl_arvalid),
        .s_axi_ctrl_ARREADY(s_axi_ctrl_arready),
        .s_axi_ctrl_ARADDR(s_axi_ctrl_araddr),
        .s_axi_ctrl_RVALID(s_axi_ctrl_rvalid),
        .s_axi_ctrl_RREADY(s_axi_ctrl_rready),
        .s_axi_ctrl_RDATA(s_axi_ctrl_rdata),
        .s_axi_ctrl_RRESP(s_axi_ctrl_rresp),
        .s_axi_ctrl_BVALID(s_axi_ctrl_bvalid),
        .s_axi_ctrl_BREADY(s_axi_ctrl_bready),
        .s_axi_ctrl_BRESP(s_axi_ctrl_bresp)
    );

    always #1 samp_clk = ~samp_clk;
    always #4 config_clk = ~config_clk;

    initial begin
        samp_clk = 1;
        config_clk = 1;
        samp_rst_n = 0;
        config_rst_n = 0;
        @(posedge config_clk);
        samp_rst_n = 1;
        config_rst_n = 1;
    end

    reg [31:0] cycle = 0;
    reg [7:0] r_host = 0;
    reg [31:0] recv_count = 0;
    always @ (posedge samp_clk) begin
        r_host <= $random % 256;
        if (!samp_rst_n) begin
            cycle <= 0;
            recv_count <= 0;
        end else begin
            testbench.DUT.modulators.force_start <= 1; // manual start
            cycle <= cycle + 1;

            if (iq_out_tready && iq_out_tready) begin
                $display("[Cycle %0d] Symbol received = %0d, %0d.",cycle,iq_out_tdata[(2*IorQ_BW)-1:IorQ_BW],iq_out_tdata[IorQ_BW-1:0]);
                recv_count <= recv_count + 1;
            end

            if (r_host < THRESHOLD_R_HOST) begin
                iq_out_tready <= 1;
            end else begin
                iq_out_tready <= 0;
            end

            if (recv_count == TOTAL_RECV) begin
                $finish;
            end

            if (cycle == 32'd200) begin
                testbench.DUT.modulators.use_mod_type_hook <= 1;
                testbench.DUT.modulators.mod_type_hook <= 3'b001; // BPSK
                $display("\n----------- Switched to BPSK -------------\n");
            end
            if (cycle == 32'd400) begin
                testbench.DUT.modulators.use_mod_type_hook <= 1;
                testbench.DUT.modulators.mod_type_hook <= 3'b010; // QAM16
                $display("\n----------- Switched to QAM-16 -------------\n");
            end
            if (cycle == 32'd600) begin
                testbench.DUT.modulators.use_mod_type_hook <= 1;
                testbench.DUT.modulators.mod_type_hook <= 3'b011; // 8PSK
                $display("\n----------- Switched to 8PSK -------------\n");
            end
        end
    end

endmodule
