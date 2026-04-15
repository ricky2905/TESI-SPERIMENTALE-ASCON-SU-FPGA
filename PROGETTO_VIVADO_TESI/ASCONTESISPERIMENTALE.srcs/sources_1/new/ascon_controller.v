`timescale 1ns/1ps
module ascon_controller (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [135:0]  spi_received,
    input  wire          spi_rxed,
    input  wire          spi_txed,
    output reg  [135:0]  spi_to_send,

    //  ASCON core
    output reg         start,
    output reg         enc_mode,
    input  wire [127:0] key_in,
    output reg [127:0] nonce_in,

    // AD / MSG FIFO output
    output reg         ad_wr,
    output reg [63:0]  ad_wdata,
    output reg         ad_wlast,
    output reg  [2:0]  ad_wlast_bytes,

    output reg         msg_wr,
    output reg [63:0]  msg_wdata,
    output reg         msg_wlast,
    output reg  [2:0]  msg_wlast_bytes,

    // core
    input  wire        busy,
    input  wire        done,

    //core
    input  wire [127:0] tag_out,

    // handshake per core
    output reg         tag_ack,

    // provisioning outputs (EXT_KEY)
    output reg  [127:0] ext_key_out,  
    output reg          ext_key_valid,
    output reg          ext_key_locked
);

    localparam ST_IDLE        = 4'd0;
    localparam ST_LEN_AD_H    = 4'd1;
    localparam ST_LEN_AD_L    = 4'd2;
    localparam ST_LEN_MSG_H   = 4'd3;
    localparam ST_LEN_MSG_L   = 4'd4;
    localparam ST_READ_NONCE  = 4'd5;
    localparam ST_PROCESS_MSG = 4'd6;
    localparam ST_WAIT_DONE   = 4'd7;
    localparam ST_TAG_SEND    = 4'd8;
    localparam ST_KEY_WRITE   = 4'd9;

    reg [3:0] state;
    reg [15:0] len_ad;
    reg [15:0] len_msg;
    reg [15:0] msg_bytes_remaining;

    reg [63:0] data_buffer;
    reg [2:0] buffer_pos;
    reg [3:0] nonce_count;

    reg [4:0] key_write_count;
    reg [127:0] key_write_shift;

    reg tag_send_mode;

    reg [31:0] timeout_counter;
    reg done_seen;

    integer i;

    reg [135:0] frame_buffer;
    reg         frame_avail;
    reg [4:0]   frame_byte_idx; 
    reg [7:0]   spi_byte_data;
    reg         spi_byte_rxed;   
    reg         spi_byte_rxed_r;

    reg spi_rxed_r;
    wire spi_rxed_posedge = spi_rxed && !spi_rxed_r;

    reg spi_txed_r;
    wire spi_txed_posedge = spi_txed && !spi_txed_r;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_buffer <= {136{1'b0}};
            frame_avail <= 1'b0;
            frame_byte_idx <= 5'd0;
            spi_byte_rxed <= 1'b0;
            spi_byte_data <= 8'd0;
            spi_rxed_r <= 1'b0;
            spi_txed_r <= 1'b0;
        end else begin
            spi_rxed_r <= spi_rxed;
            spi_txed_r <= spi_txed;
            spi_byte_rxed <= 1'b0;

            if (spi_rxed_posedge) begin
                frame_buffer <= spi_received;
                frame_avail <= 1'b1;
                frame_byte_idx <= 5'd0;
                spi_byte_data <= spi_received[135 -: 8];
                spi_byte_rxed <= 1'b1;
                if (16 == 0) frame_avail <= 1'b0; 
                else frame_byte_idx <= 5'd1;
            end else if (frame_avail) begin
                spi_byte_data <= frame_buffer[135 - 8*frame_byte_idx -: 8];
                spi_byte_rxed <= 1'b1;
                if (frame_byte_idx == 5'd16) begin
                    frame_avail <= 1'b0;
                    frame_byte_idx <= 5'd0;
                end else begin
                    frame_byte_idx <= frame_byte_idx + 1'b1;
                end
            end
        end
    end

    wire spi_byte_rxed_posedge = spi_byte_rxed && !spi_byte_rxed_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_byte_rxed_r <= 1'b0;
        end else begin
            spi_byte_rxed_r <= spi_byte_rxed;
        end
    end

    reg [7:0] read_cmd_byte;

    task load_tag_bytes;
        input [127:0] tag_in;
        integer j;
        begin

        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            len_ad <= 16'd0;
            len_msg <= 16'd0;
            msg_bytes_remaining <= 16'd0;
            nonce_in <= 128'd0;
            start <= 1'b0;
            enc_mode <= 1'b1;
            ad_wr <= 1'b0;
            ad_wdata <= 64'd0;
            ad_wlast <= 1'b0;
            ad_wlast_bytes <= 3'd0;
            msg_wr <= 1'b0;
            msg_wdata <= 64'd0;
            msg_wlast <= 1'b0;
            msg_wlast_bytes <= 3'd0;
            spi_to_send <= {136{1'b0}};
            spi_rxed_r <= 1'b0;
            spi_txed_r <= 1'b0;
            tag_send_mode <= 1'b0;
            data_buffer <= 64'd0;
            buffer_pos <= 3'd0;
            nonce_count <= 4'd0;
            timeout_counter <= 32'd0;
            done_seen <= 1'b0;
            tag_ack <= 1'b0;

            ext_key_out <= 128'd0;
            ext_key_valid <= 1'b0;
            ext_key_locked <= 1'b0;
            key_write_count <= 5'd0;
            key_write_shift <= 128'd0;

        end else begin
            spi_rxed_r <= spi_rxed;
            spi_txed_r <= spi_txed;
            start <= 1'b0;
            ad_wr <= 1'b0;
            msg_wr <= 1'b0;
            tag_ack <= 1'b0;
            ext_key_valid <= 1'b0;

            done_seen <= done_seen | done;

            if (state != ST_IDLE) begin
                timeout_counter <= timeout_counter + 1;
            end else begin
                timeout_counter <= 32'd0;
            end

            if (timeout_counter > 32'd100000) begin
                $display("[%0t] Controller: Timeout in state %d, resetting to IDLE", $time, state);
                state <= ST_IDLE;
                timeout_counter <= 32'd0;
            end


            if (spi_txed_posedge && tag_send_mode) begin
                tag_send_mode <= 1'b0;
                tag_ack <= 1'b1;
                done_seen <= 1'b0;
                spi_to_send <= {136{1'b0}};
                state <= ST_IDLE;
                $display("[%0t] Controller: Tag frame transmitted, asserting tag_ack", $time);
            end

            case (state)
                ST_IDLE: begin
                    if (spi_byte_rxed_posedge) begin
                        $display("[%0t] Controller: SPI RXED byte = 0x%02x (done_seen=%b, done=%b)", $time, spi_byte_data, done_seen, done);
                        read_cmd_byte = spi_byte_data;
                        case (read_cmd_byte)
                            8'h81: begin
                                state <= ST_LEN_AD_H;
                                $display("[%0t] Controller: Received CMD 0x81 (start op)", $time);
                            end
                            8'h40: begin
                                $display("[%0t] Controller: RD TAG cmd received, done_seen=%b, done=%b", $time, done_seen, done);
                                if (done_seen || done) begin
                                    $display("[%0t] Controller: Preparing tag frame to send, tag_out=%032h", $time, tag_out);
                                    spi_to_send <= {tag_out, 8'h00};
                                    tag_send_mode <= 1'b1;
                                    state <= ST_TAG_SEND;
                                end else begin
                                    $display("[%0t] Controller: RD TAG requested but tag not ready (done_seen=0, done=0)", $time);
                                end
                            end
                            8'hA0: begin
                                if (!ext_key_locked) begin
                                    key_write_count <= 5'd0;
                                    key_write_shift <= 128'd0;
                                    state <= ST_KEY_WRITE;
                                    $display("[%0t] Controller: Entering EXT KEY WRITE mode (expect 16 bytes)", $time);
                                end else begin
                                    $display("[%0t] Controller: EXT KEY WRITE requested but key is locked", $time);
                                end
                            end
                            8'hA1: begin
                                ext_key_locked <= 1'b1;
                                $display("[%0t] Controller: EXT KEY LOCK command received -> key locked", $time);
                            end
                            default: begin

                            end
                        endcase
                    end
                end

                ST_LEN_AD_H: begin
                    if (spi_byte_rxed_posedge) begin
                        len_ad[15:8] <= spi_byte_data;
                        state <= ST_LEN_AD_L;
                    end
                end

                ST_LEN_AD_L: begin
                    if (spi_byte_rxed_posedge) begin
                        len_ad[7:0] <= spi_byte_data;
                        state <= ST_LEN_MSG_H;
                    end
                end

                ST_LEN_MSG_H: begin
                    if (spi_byte_rxed_posedge) begin
                        len_msg[15:8] <= spi_byte_data;
                        state <= ST_LEN_MSG_L;
                    end
                end

                ST_LEN_MSG_L: begin
                    if (spi_byte_rxed_posedge) begin
                        len_msg[7:0] <= spi_byte_data;
                        msg_bytes_remaining <= {len_msg[15:8], spi_byte_data};
                        nonce_count <= 4'd0;
                        nonce_in <= 128'd0;
                        state <= ST_READ_NONCE;
                        $display("[%0t] Controller: Message length = %d bytes", $time, {len_msg[15:8], spi_byte_data});
                    end
                end

                ST_READ_NONCE: begin
                    if (spi_byte_rxed_posedge) begin
                        nonce_in <= {nonce_in[119:0], spi_byte_data};
                        if (nonce_count == 4'd15) begin
                            start <= 1'b1;
                            buffer_pos <= 3'd0;
                            state <= ST_PROCESS_MSG;
                            $display("[%0t] Controller: Nonce loaded, starting processing", $time);
                        end
                        nonce_count <= nonce_count + 1;
                    end
                end

                ST_PROCESS_MSG: begin
                    if (spi_byte_rxed_posedge && msg_bytes_remaining > 0) begin
                        data_buffer <= {data_buffer[55:0], spi_byte_data};

                        if ((buffer_pos == 3'd7) || (msg_bytes_remaining <= 16'd8)) begin
                            msg_wdata <= {data_buffer[55:0], spi_byte_data};
                            if (msg_bytes_remaining <= 16'd8) begin
                                msg_wlast <= 1'b1;
                                msg_wlast_bytes <= (msg_bytes_remaining == 16'd8) ? 3'd0 : msg_bytes_remaining[2:0];
                            end else begin
                                msg_wlast <= 1'b0;
                                msg_wlast_bytes <= 3'd0;
                            end

                            msg_wr <= 1'b1;
                            buffer_pos <= 3'd0;
                        end else begin
                            buffer_pos <= buffer_pos + 1;
                        end

                        if (msg_bytes_remaining == 16'd1) begin
                            state <= ST_WAIT_DONE;
                            $display("[%0t] Controller: All message data sent", $time);
                        end

                        msg_bytes_remaining <= msg_bytes_remaining - 1;
                    end
                end

                ST_WAIT_DONE: begin
                    if (done) begin
                        done_seen <= 1'b1;
                        state <= ST_IDLE;
                        $display("[%0t] Controller: Processing done", $time);
                    end
                end

                ST_TAG_SEND: begin

                end

                ST_KEY_WRITE: begin
                    if (spi_byte_rxed_posedge) begin
                        key_write_shift <= {key_write_shift[119:0], spi_byte_data};
                        key_write_count <= key_write_count + 1;
                        $display("[%0t] Controller: KEY WRITE byte %0d = 0x%02x", $time, key_write_count+1, spi_byte_data);
                        if (key_write_count == 5'd15) begin
                            ext_key_out <= {key_write_shift[119:0], spi_byte_data};
                            ext_key_valid <= 1'b1;
                            $display("[%0t] Controller: EXT KEY written = %032h (ext_key_valid pulse)", $time, {key_write_shift[119:0], spi_byte_data});
                            state <= ST_IDLE;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
