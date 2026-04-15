`timescale 1ns / 1ps
module ascon_core (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,      
    input  wire        enc_mode,   // 1 = encrypt, 0 = decrypt

    // Key / Nonce
    input  wire [127:0] key_in,
    input  wire [127:0] nonce_in,

    // AD FIFO
    input  wire         ad_wr,
    input  wire [63:0]  ad_wdata,
    input  wire         ad_wlast,
    input  wire  [2:0]  ad_wlast_bytes,

    // MSG FIFO
    input  wire         msg_wr,
    input  wire [63:0]  msg_wdata,
    input  wire         msg_wlast,
    input  wire  [2:0] msg_wlast_bytes,

    // Data OUT FIFO
    input  wire         out_rd,
    output reg  [63:0]  out_rdata,
    output reg          out_rvalid,
    output reg          out_rlast,
    output reg  [2:0]   out_rlast_bytes,

    // Tag out
    output reg  [127:0] tag_out,
    output reg          tag_valid,

    // status
    output reg          busy,
    output reg          done,

    // handshake ack from controller
    input  wire         tag_ack
);

    localparam FIFO_AW = 4;
    localparam DEPTH   = (1 << FIFO_AW);

    reg [63:0] ad_mem [0:DEPTH-1];
    reg [2:0]  ad_last_bytes_mem [0:DEPTH-1];
    reg        ad_last_mem [0:DEPTH-1];
    reg [FIFO_AW-1:0] ad_wptr, ad_rptr;
    reg [FIFO_AW:0]   ad_count;

    reg [63:0] msg_mem [0:DEPTH-1];
    reg [2:0]  msg_last_bytes_mem [0:DEPTH-1];
    reg        msg_last_mem [0:DEPTH-1];
    reg [FIFO_AW-1:0] msg_wptr, msg_rptr;
    reg [FIFO_AW:0]   msg_count;

    reg [63:0] out_mem [0:DEPTH-1];
    reg [2:0]  out_last_bytes_mem [0:DEPTH-1];
    reg        out_last_mem [0:DEPTH-1];
    reg [FIFO_AW-1:0] out_wptr, out_rptr;
    reg [FIFO_AW:0]   out_count;

    reg [63:0] k0, k1, n0, n1;
    reg [63:0] x0, x1, x2, x3, x4;

    reg         perm_start;
    reg  [3:0]  perm_rounds;
    wire        perm_busy;
    wire        perm_done;
    wire [63:0] perm_x0_out, perm_x1_out, perm_x2_out, perm_x3_out, perm_x4_out;

    ascon_perm perm_inst (
        .clk(clk), .rst_n(rst_n),
        .start(perm_start),
        .rounds(perm_rounds),
        .in_x0(x0), .in_x1(x1), .in_x2(x2), .in_x3(x3), .in_x4(x4),
        .out_x0(perm_x0_out), .out_x1(perm_x1_out), .out_x2(perm_x2_out),
        .out_x3(perm_x3_out), .out_x4(perm_x4_out),
        .busy(perm_busy), .done(perm_done)
    );

    localparam S_IDLE           = 4'd0;
    localparam S_WAIT_INIT_PERM = 4'd1;
    localparam S_AD_ABSORB      = 4'd2;
    localparam S_DO_DOMAIN      = 4'd3;
    localparam S_MSG_PROC       = 4'd4;
    localparam S_FINALIZE       = 4'd5;
    localparam S_WAIT_FINAL_PERM= 4'd6;
    localparam S_OUTPUT_TAG     = 4'd7;

    reg [3:0] state;

    reg ad_pop_req;
    reg msg_pop_req;

    reg [63:0] ad_pop_data;
    reg [2:0]  ad_pop_last_bytes;
    reg        ad_pop_last;

    reg [63:0] msg_pop_data;
    reg [2:0]  msg_pop_last_bytes;
    reg        msg_pop_last;

    reg pending_ad, pending_msg, pending_msg_stage2;
    reg last_msg_seen;
    reg [2:0] last_msg_bytes_local;
    reg last_ad_seen;
    reg [2:0] last_ad_bytes_local;

    reg [63:0] tmp_block;
    reg [63:0] prev_x0;
    integer i;

    function [63:0] pad_block;
        input [63:0] data;
        input [2:0]  last_bytes;
        reg [63:0] mask;
        reg [63:0] pad;
        integer valid_bytes;
        begin
            if (last_bytes == 3'd0) begin
                pad_block = data;
            end else begin
                valid_bytes = last_bytes;
                mask = (64'hFFFFFFFFFFFFFFFF >> (8*(8 - valid_bytes)));
                pad = 64'h80 << (8*valid_bytes);
                pad_block = (data & mask) | pad;
            end
        end
    endfunction


    task out_push;
        input [63:0] wdata;
        input [2:0]  last_bytes;
        input        last_flag;
        begin
            if (out_count != DEPTH) begin
                out_mem[out_wptr] <= wdata;
                out_last_bytes_mem[out_wptr] <= last_bytes;
                out_last_mem[out_wptr] <= last_flag;
                out_wptr <= out_wptr + 1;
                out_count <= out_count + 1;
            end
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ad_wptr <= 0; ad_rptr <= 0; ad_count <= 0;
            msg_wptr <= 0; msg_rptr <= 0; msg_count <= 0;
            out_wptr <= 0; out_rptr <= 0; out_count <= 0;

            out_rdata <= 0; out_rvalid <= 0; out_rlast <= 0; out_rlast_bytes <= 0;

            state <= S_IDLE;
            busy <= 0;
            done <= 0;
            tag_out <= 0;
            tag_valid <= 0;

            perm_start <= 0;
            perm_rounds <= 0;

            k0 <= 0; k1 <= 0; n0 <= 0; n1 <= 0;
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;

            ad_pop_req <= 1'b0; msg_pop_req <= 1'b0;
            ad_pop_data <= 64'd0; ad_pop_last_bytes <= 3'd0; ad_pop_last <= 1'b0;
            msg_pop_data <= 64'd0; msg_pop_last_bytes <= 3'd0; msg_pop_last <= 1'b0;

            pending_ad <= 0; pending_msg <= 0; pending_msg_stage2 <= 0;
            last_msg_seen <= 0;

            for (i = 0; i < DEPTH; i = i + 1) begin
                ad_mem[i] <= 64'd0;
                ad_last_bytes_mem[i] <= 3'd0;
                ad_last_mem[i] <= 1'b0;
                msg_mem[i] <= 64'd0;
                msg_last_bytes_mem[i] <= 3'd0;
                msg_last_mem[i] <= 1'b0;
                out_mem[i] <= 64'd0;
                out_last_bytes_mem[i] <= 3'd0;
                out_last_mem[i] <= 1'b0;
            end
        end else begin

            if (ad_wr && ad_count != DEPTH) begin
                ad_mem[ad_wptr] <= ad_wdata;
                ad_last_bytes_mem[ad_wptr] <= ad_wlast_bytes;
                ad_last_mem[ad_wptr] <= ad_wlast;
                ad_wptr <= ad_wptr + 1;
                ad_count <= ad_count + 1;
            end

            if (msg_wr && msg_count != DEPTH) begin
                msg_mem[msg_wptr] <= msg_wdata;
                msg_last_bytes_mem[msg_wptr] <= msg_wlast_bytes;
                msg_last_mem[msg_wptr] <= msg_wlast;
                msg_wptr <= msg_wptr + 1;
                msg_count <= msg_count + 1;
            end

            if (ad_pop_req && ad_count != 0) begin
                ad_pop_data <= ad_mem[ad_rptr];
                ad_pop_last_bytes <= ad_last_bytes_mem[ad_rptr];
                ad_pop_last <= ad_last_mem[ad_rptr];
                ad_rptr <= ad_rptr + 1;
                ad_count <= ad_count - 1;
                ad_pop_req <= 1'b0;
                pending_ad <= 1'b1;
            end

            if (msg_pop_req && msg_count != 0) begin
                msg_pop_data <= msg_mem[msg_rptr];
                msg_pop_last_bytes <= msg_last_bytes_mem[msg_rptr];
                msg_pop_last <= msg_last_mem[msg_rptr];
                msg_rptr <= msg_rptr + 1;
                msg_count <= msg_count - 1;
                msg_pop_req <= 1'b0;
                pending_msg <= 1'b1;
            end
            if (out_count != 0) begin
                out_rdata <= out_mem[out_rptr];
                out_rlast <= out_last_mem[out_rptr];
                out_rlast_bytes <= out_last_bytes_mem[out_rptr];
            end
            if (out_rd && out_count != 0) begin
                out_rptr <= out_rptr + 1;
                out_count <= out_count - 1;
            end
            out_rvalid <= (out_count != 0);

            perm_start <= 1'b0;

            if (tag_ack) begin
                tag_valid <= 1'b0;
                done <= 1'b0;
                k0 <= 64'd0;
                k1 <= 64'd0;
                n0 <= 64'd0;
                n1 <= 64'd0;
            end

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    ad_pop_req <= 1'b0;
                    msg_pop_req <= 1'b0;

                    if (start) begin
                        k0 <= key_in[63:0]; k1 <= key_in[127:64];
                        n0 <= nonce_in[63:0]; n1 <= nonce_in[127:64];
                        x0 <= 64'h80400c0600000000;
                        x1 <= key_in[63:0];
                        x2 <= key_in[127:64];
                        x3 <= nonce_in[63:0];
                        x4 <= nonce_in[127:64];

                        // internal flags
                        last_msg_seen <= 1'b0;
                        last_ad_seen <= 1'b0;
                        pending_ad <= 1'b0;
                        pending_msg <= 1'b0;
                        pending_msg_stage2 <= 1'b0;

                        // start initial perm
                        perm_rounds <= 12;
                        perm_start <= 1'b1;
                        busy <= 1'b1;
                        state <= S_WAIT_INIT_PERM;
                    end
                end

                S_WAIT_INIT_PERM: begin
                    if (perm_done) begin
                        x0 <= perm_x0_out;
                        x1 <= perm_x1_out;
                        x2 <= perm_x2_out;
                        x3 <= perm_x3_out ^ k0;
                        x4 <= perm_x4_out ^ k1;
                        state <= S_AD_ABSORB;
                    end
                end

                S_AD_ABSORB: begin
                    if (!pending_ad && !perm_busy && ad_count != 0 && !ad_pop_req) begin
                        ad_pop_req <= 1'b1;
                    end

                    if (pending_ad) begin
                        tmp_block <= pad_block(ad_pop_data, ad_pop_last_bytes);
                        x0 <= x0 ^ pad_block(ad_pop_data, ad_pop_last_bytes);
                        perm_rounds <= 6;
                        perm_start <= 1'b1;
                        pending_ad <= 1'b0;
                    end else begin
                        state <= S_DO_DOMAIN;
                    end
                end

                S_DO_DOMAIN: begin
                    x4 <= x4 ^ 1;
                    state <= S_MSG_PROC;
                end

                S_MSG_PROC: begin
                    if (!pending_msg && !perm_busy && !pending_msg_stage2 && msg_count != 0 && !msg_pop_req) begin
                        msg_pop_req <= 1'b1;
                    end

                    if (pending_msg) begin
                        tmp_block <= pad_block(msg_pop_data, msg_pop_last_bytes);
                        prev_x0 <= x0;
                        pending_msg_stage2 <= 1'b1;
                        pending_msg <= 1'b0;
                    end

                    if (pending_msg_stage2) begin
                        if (enc_mode) begin
                            x0 <= prev_x0 ^ tmp_block;
                            out_push(prev_x0 ^ tmp_block, msg_pop_last_bytes, msg_pop_last);
                        end else begin
                            out_push(prev_x0 ^ tmp_block, msg_pop_last_bytes, msg_pop_last);
                            x0 <= tmp_block;
                        end
                        perm_rounds <= 6;
                        perm_start <= 1'b1;
                        pending_msg_stage2 <= 1'b0;
                        if (msg_pop_last) last_msg_seen <= 1'b1;
                    end

                    if (msg_count == 0 && last_msg_seen && !pending_msg_stage2 && !perm_busy && !pending_msg) begin
                        state <= S_FINALIZE;
                    end
                end

                S_FINALIZE: begin
                    x1 <= x1 ^ k0;
                    x2 <= x2 ^ k1;
                    perm_rounds <= 12;
                    perm_start <= 1'b1;
                    state <= S_WAIT_FINAL_PERM;
                end

                S_WAIT_FINAL_PERM: begin
                    if (perm_done) begin
                        tag_out <= {perm_x3_out ^ k0, perm_x4_out ^ k1};
                        tag_valid <= 1'b1;
                        done <= 1'b1;
                        busy <= 1'b0;
                        $display("[%0t] ASCON Core: Tag produced = %032h", $time, {perm_x3_out ^ k0, perm_x4_out ^ k1});
                        state <= S_OUTPUT_TAG;
                    end
                end

                S_OUTPUT_TAG: begin
                    if (tag_ack) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase

            if (perm_done && state != S_WAIT_INIT_PERM && state != S_WAIT_FINAL_PERM) begin
                x0 <= perm_x0_out;
                x1 <= perm_x1_out;
                x2 <= perm_x2_out;
                x3 <= perm_x3_out;
                x4 <= perm_x4_out;
            end
        end
    end

endmodule