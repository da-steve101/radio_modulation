module Modulators #(
    parameter IQ_BW = 16
) (
    ap_clk,
    ap_rst,
    amplitude,
    samples_per_symbol,
    mod_type,
    start,

    i_out_TVALID,
    i_out_TREADY,
    i_out_TDATA,

    q_out_TVALID,
    q_out_TREADY,
    q_out_TDATA
);

    /* declare inputs / outputs */
    input ap_clk;
    input ap_rst;

    // axi-lite signals
    input [31:0] amplitude;
    input [31:0] samples_per_symbol;
    input start;
    input [2:0] mod_type;

    // outputs to RF-DAC
    output reg i_out_TVALID;
    input i_out_TREADY;
    output reg [IQ_BW-1:0] i_out_TDATA;

    output reg q_out_TVALID;
    input q_out_TREADY;
    output reg [IQ_BW-1:0] q_out_TDATA;
    /* ------------------------ */

    // instantiate different modulation memories

    // qpsk
    reg [15:0] qpsk_rd_addr;
    wire [7:0] qpsk_symbol_i, qpsk_symbol_q;

    qpsk_mem qpsk_mem_inst (
        .clk(ap_clk),
        .rst(ap_rst),
        .rd_addr(qpsk_rd_addr),
        .i(qpsk_symbol_i),
        .q(qpsk_symbol_q)
    );

    // bpsk
    reg [15:0] bpsk_rd_addr;
    wire [7:0] bpsk_symbol_i, bpsk_symbol_q;

    bpsk_mem bpsk_mem_inst (
        .clk(ap_clk),
        .rst(ap_rst),
        .rd_addr(bpsk_rd_addr),
        .i(bpsk_symbol_i),
        .q(bpsk_symbol_q)
    );

    // M8psk
    reg [15:0] M8psk_rd_addr;
    wire [7:0] M8psk_symbol_i, M8psk_symbol_q;

    M8psk_mem M8psk_mem_inst (
        .clk(ap_clk),
        .rst(ap_rst),
        .rd_addr(M8psk_rd_addr),
        .i(M8psk_symbol_i),
        .q(M8psk_symbol_q)
    );

    // QAM16
    reg [15:0] qam16_rd_addr;
    wire [7:0] qam16_symbol_i, qam16_symbol_q;

    qam16_mem qam16_mem_inst (
        .clk(ap_clk),
        .rst(ap_rst),
        .rd_addr(qam16_rd_addr),
        .i(qam16_symbol_i),
        .q(qam16_symbol_q)
    );

    /* ------------------------ */

    // testbench-related signals/hooks that will (should) get optimized away
    // by Vivado
    reg force_start = 0;
    reg use_mod_type_hook = 0;
    reg [2:0] mod_type_hook = 3'b000;
    wire [2:0] mod_type_v = use_mod_type_hook ? mod_type_hook : mod_type;

    // samples_per_symbol counters
    reg [2:0] mod_type_last;
    wire reset_sps = (mod_type_last != mod_type_v);
    wire [31:0] qpsk_nps = reset_sps ? 0 : (qpsk_sps+1);
    wire [31:0] bpsk_nps = reset_sps ? 0 : (bpsk_sps+1);
    wire [31:0] M8psk_nps = reset_sps ? 0 : (M8psk_sps+1);
    wire [31:0] qam16_nps = reset_sps ? 0 : (qam16_sps+1);
    reg [31:0] qpsk_sps, bpsk_sps, M8psk_sps, qam16_sps;

    // transmit logic
    always @ (posedge ap_clk) begin
        if (ap_rst) begin
            i_out_TDATA <= 0; i_out_TVALID <= 0;
            q_out_TDATA <= 0; q_out_TVALID <= 0;
            qpsk_rd_addr <= 0;
            bpsk_rd_addr <= 0;
            M8psk_rd_addr <= 0;
            qam16_rd_addr <= 0;
            qpsk_sps <= 0; bpsk_sps <= 0; M8psk_sps <= 0; qam16_sps <= 0;
            mod_type_last <= mod_type_v;
        end else begin
            if (start | force_start) begin
                mod_type_last <= mod_type_v;

                if (mod_type_last != mod_type_v) begin // reset samples_per_symbol for each class
                    qpsk_sps <= 0; bpsk_sps <= 0; M8psk_sps <= 0; qam16_sps <= 0;
                end

                i_out_TVALID <= 1; q_out_TVALID <= 1;
                if (mod_type_v == 3'b000) begin // QPSK
                    i_out_TDATA <= $signed( $signed(qpsk_symbol_i) * amplitude );
                    q_out_TDATA <= $signed( $signed(qpsk_symbol_q) * amplitude );
                    if (i_out_TREADY && q_out_TREADY) begin
                        if (qpsk_nps == samples_per_symbol) begin
                            qpsk_rd_addr <= qpsk_rd_addr + 1;
                            qpsk_sps <= 0;
                        end else begin
                            qpsk_sps <= qpsk_sps + 1;
                        end
                    end
                end else if (mod_type_v == 3'b001) begin // BPSK
                    i_out_TDATA <= $signed( $signed(bpsk_symbol_i) * amplitude );
                    q_out_TDATA <= $signed( $signed(bpsk_symbol_q) * amplitude );
                    if (i_out_TREADY && q_out_TREADY) begin
                        if (bpsk_nps == samples_per_symbol) begin
                            bpsk_rd_addr <= bpsk_rd_addr + 1;
                            bpsk_sps <= 0;
                        end else begin
                            bpsk_sps <= bpsk_sps + 1;
                        end
                    end
                end else if (mod_type_v == 3'b010) begin // QAM16
                    i_out_TDATA <= $signed( $signed(qam16_symbol_i) * amplitude );
                    q_out_TDATA <= $signed( $signed(qam16_symbol_q) * amplitude );
                    if (i_out_TREADY && q_out_TREADY) begin
                        if (qam16_nps == samples_per_symbol) begin
                            qam16_rd_addr <= qam16_rd_addr + 1;
                            qam16_sps <= 0;
                        end else begin
                            qam16_sps <= qam16_sps + 1;
                        end
                    end
                end else begin // M8PSK (default to)
                    i_out_TDATA <= $signed( $signed(M8psk_symbol_i) * amplitude );
                    q_out_TDATA <= $signed( $signed(M8psk_symbol_q) * amplitude );
                    if (i_out_TREADY && q_out_TREADY) begin
                        if (M8psk_nps == samples_per_symbol) begin
                            M8psk_rd_addr <= M8psk_rd_addr + 1;
                            M8psk_sps <= 0;
                        end else begin
                            M8psk_sps <= M8psk_sps + 1;
                        end
                    end
                end
            end else begin // reset addresses and samples-per-symbol counters
                qpsk_rd_addr <= 0; bpsk_rd_addr <= 0; M8psk_rd_addr <= 0; qam16_rd_addr <= 0;
                qpsk_sps <= 0; bpsk_sps <= 0; M8psk_sps <= 0; qam16_sps <= 0;
            end
        end
    end

endmodule

