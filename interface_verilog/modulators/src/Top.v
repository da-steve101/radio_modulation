`timescale 1 ns / 1 ps 

/*
*
* Minor issue: Just after modulation type is changed, it takes one
* "symbol-burst" for the output to stabilize. This is flagged as a minor issue
* because it's unlikely to affect real operation.
*
*/

module Top # (
    parameter IQ_BW = 32, // bit-width of I + Q sample
    parameter IorQ_BW = 16
) (
    // clocks and resets
    config_clk,
    config_rst_n,
    samp_clk,
    samp_rst_n,

    // I samples AXI-stream out
    iq_out_TREADY,
    iq_out_TVALID,
    iq_out_TDATA,

    // AXI-Lite control signals
    s_axi_ctrl_AWVALID,
    s_axi_ctrl_AWREADY,
    s_axi_ctrl_AWADDR,
    s_axi_ctrl_WVALID,
    s_axi_ctrl_WREADY,
    s_axi_ctrl_WDATA,
    s_axi_ctrl_WSTRB,
    s_axi_ctrl_ARVALID,
    s_axi_ctrl_ARREADY,
    s_axi_ctrl_ARADDR,
    s_axi_ctrl_RVALID,
    s_axi_ctrl_RREADY,
    s_axi_ctrl_RDATA,
    s_axi_ctrl_RRESP,
    s_axi_ctrl_BVALID,
    s_axi_ctrl_BREADY,
    s_axi_ctrl_BRESP
);

    parameter    C_S_AXI_CTRL_DATA_WIDTH = 32;
    parameter    C_S_AXI_CTRL_ADDR_WIDTH = 6;
    parameter    C_S_AXI_DATA_WIDTH = 32;

    parameter C_S_AXI_CTRL_WSTRB_WIDTH = (32 / 8);
    parameter C_S_AXI_WSTRB_WIDTH = (32 / 8);

    input   config_clk;
    input   config_rst_n;
    input   samp_clk;
    input   samp_rst_n;

    output [IQ_BW-1:0] iq_out_TDATA;
    output iq_out_TVALID;
    input iq_out_TREADY;

    input   s_axi_ctrl_AWVALID;
    output   s_axi_ctrl_AWREADY;
    input  [C_S_AXI_CTRL_ADDR_WIDTH - 1:0] s_axi_ctrl_AWADDR;
    input   s_axi_ctrl_WVALID;
    output   s_axi_ctrl_WREADY;
    input  [C_S_AXI_CTRL_DATA_WIDTH - 1:0] s_axi_ctrl_WDATA;
    input  [C_S_AXI_CTRL_WSTRB_WIDTH - 1:0] s_axi_ctrl_WSTRB;
    input   s_axi_ctrl_ARVALID;
    output   s_axi_ctrl_ARREADY;
    input  [C_S_AXI_CTRL_ADDR_WIDTH - 1:0] s_axi_ctrl_ARADDR;
    output   s_axi_ctrl_RVALID;
    input   s_axi_ctrl_RREADY;
    output  [C_S_AXI_CTRL_DATA_WIDTH - 1:0] s_axi_ctrl_RDATA;
    output  [1:0] s_axi_ctrl_RRESP;
    output   s_axi_ctrl_BVALID;
    input   s_axi_ctrl_BREADY;
    output  [1:0] s_axi_ctrl_BRESP;

    reg    config_rst_n_inv;
    reg    samp_rst_n_inv;
    wire [31:0] amplitude, samples_per_symbol;
    wire [2:0] mod_type;
    wire start;

    // clock-domain crossing registers
    reg [31:0] amplitude_r, amplitude_rr;
    reg [31:0] samples_per_symbol_r, samples_per_symbol_rr;
    reg [2:0] mod_type_r, mod_type_rr;
    reg start_r, start_rr;

    AXILite #(
        .C_S_AXI_ADDR_WIDTH( C_S_AXI_CTRL_ADDR_WIDTH ),
        .C_S_AXI_DATA_WIDTH( C_S_AXI_CTRL_DATA_WIDTH ))
    AXILite_Inst (
        .AWVALID(s_axi_ctrl_AWVALID),
        .AWREADY(s_axi_ctrl_AWREADY),
        .AWADDR(s_axi_ctrl_AWADDR),
        .WVALID(s_axi_ctrl_WVALID),
        .WREADY(s_axi_ctrl_WREADY),
        .WDATA(s_axi_ctrl_WDATA),
        .WSTRB(s_axi_ctrl_WSTRB),
        .ARVALID(s_axi_ctrl_ARVALID),
        .ARREADY(s_axi_ctrl_ARREADY),
        .ARADDR(s_axi_ctrl_ARADDR),
        .RVALID(s_axi_ctrl_RVALID),
        .RREADY(s_axi_ctrl_RREADY),
        .RDATA(s_axi_ctrl_RDATA),
        .RRESP(s_axi_ctrl_RRESP),
        .BVALID(s_axi_ctrl_BVALID),
        .BREADY(s_axi_ctrl_BREADY),
        .BRESP(s_axi_ctrl_BRESP),
        .ACLK(config_clk),
        .ARESET(config_rst_n_inv),
        .ACLK_EN(1'b1),
        .amplitude(amplitude),
        .samples_per_symbol(samples_per_symbol),
        .mod_type_V(mod_type),
        .start_V(start)
    );

    wire [IorQ_BW-1:0] i_out_TDATA;
    wire [IorQ_BW-1:0] q_out_TDATA;
    wire i_out_TVALID, q_out_TVALID;
    
    Modulators #(
        .IQ_BW(IorQ_BW)
    ) modulators (
        .ap_clk(samp_clk),
        .ap_rst(samp_rst_n_inv),
        .amplitude(amplitude_rr),
        .samples_per_symbol(samples_per_symbol_rr),
        .mod_type(mod_type_rr),
        .start(start_rr),

        .i_out_TVALID(i_out_TVALID),
        .i_out_TREADY(iq_out_TREADY),
        .i_out_TDATA(i_out_TDATA),

        .q_out_TVALID(q_out_TVALID),
        .q_out_TREADY(iq_out_TREADY),
        .q_out_TDATA(q_out_TDATA)
    );

    assign iq_out_TDATA = (i_out_TVALID & q_out_TVALID) ? {i_out_TDATA,q_out_TDATA} : 0;
    assign iq_out_TVALID = (i_out_TVALID & q_out_TVALID);

    // clock-domain crossing for axilite to axi-stream domain
    always @ (posedge samp_clk) begin
        if (samp_rst_n_inv == 1'b1) begin

            amplitude_r <= 32'd1024;
            amplitude_rr <= 32'd1024;
            samples_per_symbol_r <= 32'd4;
            samples_per_symbol_rr <= 32'd4;
            mod_type_r <= 3'b000;
            mod_type_rr <= 3'b000;
            start_r <= 1'b0;
            start_rr <= 1'b0;

        end else begin

            // override defaults
            if (amplitude == 0) begin
                amplitude_r <= 32'd1024;
            end else begin
                amplitude_r <= amplitude;
            end
            if (samples_per_symbol == 0) begin
                samples_per_symbol_r <= 32'd4;
            end else begin
                samples_per_symbol_r <= samples_per_symbol;
            end

            // propagate axi-lite settings through CDC registers
            amplitude_rr <= amplitude_r;
            samples_per_symbol_rr <= samples_per_symbol_r;
            mod_type_r <= mod_type;
            mod_type_rr <= mod_type_r;
            start_r <= start;
            start_rr <= start_r;

        end
    end

    // power-on initialization
    initial begin
        #0 amplitude_r = 32'd1024;
        #0 amplitude_rr = 32'd1024;
        #0 samples_per_symbol_r = 32'd4;
        #0 samples_per_symbol_rr = 32'd4;
        #0 mod_type_r = 3'b000;
        #0 mod_type_rr = 3'b000;
        #0 start_r = 1'b0;
        #0 start_rr = 1'b0;
    end

    always @ (*) begin
        config_rst_n_inv = ~config_rst_n;
        samp_rst_n_inv = ~samp_rst_n;
    end

endmodule //Top
