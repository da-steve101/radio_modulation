module scheduler
#(
    parameter CLASSES = 4
)(
    input wire clk,
    input wire rstn,

    // axis from rf data converter
    input wire [31:0] i_in_TDATA,
    input wire i_in_TVALID,
    output wire i_in_TREADY,

    input wire [31:0] q_in_TDATA,
    input wire q_in_TVALID,
    output wire q_in_TREADY,

    // data into twn
    output wire twn_vld_in,
    output wire [3:0][15:0] twn_data_in,

    // data out from twn
    input wire twn_vld_out,
    input wire [CLASSES-1:0][15:0] twn_data_out,

    // data back to host
    output wire [511:0] predictions_TDATA,
    output wire predictions_TVALID,
    output wire predictions_TLAST,
    input wire predictions_TREADY
);

    // always ready to accept new data
    assign i_in_TREADY = rstn ? 1'b1 : 1'b0;
    assign q_in_TREADY = rstn ? 1'b1 : 1'b0;

    reg [CLASSES-1:0][15:0] pred_buf;
    reg pred_buf_vld;
    reg pred_buf_tlast;

    reg [31:0] i_buf;
    reg i_buf_vld;
    reg [31:0] q_buf;
    reg q_buf_vld;

    // assign outputs
    assign twn_vld_in = (i_buf_vld & q_buf_vld);
    assign twn_data_in[0] = q_buf[31:16]; 
    assign twn_data_in[1] = i_buf[31:16]; 
    assign twn_data_in[2] = q_buf[15:0]; 
    assign twn_data_in[3] = i_buf[15:0];

    always @ (posedge clk) begin
        if (!rstn) begin
            pred_buf <= 0;
            pred_buf_vld <= 0;
            pred_buf_tlast <= 0;
            i_buf_vld <= 0;
            q_buf_vld <= 0;
            i_buf <= 0;
            q_buf <= 0;
        end else begin
            // process inputs

            // defaults: will get overwritten if rf data converter sends new
            // data every cycle
            i_buf <= 0;
            q_buf <= 0;
            i_buf_vld <= 0;
            q_buf_vld <= 0;
            if (i_in_TVALID & q_in_TVALID) begin
                i_buf <= i_in_TDATA;
                q_buf <= q_in_TDATA;
                i_buf_vld <= 1;
                q_buf_vld <= 1;
            end

            // process outputs
            if (twn_vld_out) begin
                pred_buf <= twn_data_out;
                pred_buf_vld <= 1;
                pred_buf_tlast <= 1; // fixed to one prediction per call
            end

            if (predictions_TREADY && pred_buf_vld) begin
                pred_buf_vld <= 0;
                pred_buf <= 0;
                pred_buf_tlast <= 0; // fixed to one prediction per call
            end
        end
    end

    assign predictions_TVALID = pred_buf_vld;
    assign predictions_TLAST = pred_buf_tlast;
    genvar i;
    generate for (i = 0; i < CLASSES; i = i + 1) begin
        assign predictions_TDATA[ ((i+1)*16)-1 : (i*16) ] = pred_buf[i];
    end endgenerate
    assign predictions_TDATA[511:16*CLASSES] = 0;

endmodule

