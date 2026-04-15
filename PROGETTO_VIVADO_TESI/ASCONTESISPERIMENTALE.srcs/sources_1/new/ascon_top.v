`timescale 1ns / 1ps
module ascon_top (
    input  wire        clk,         
    input  wire        rst_n,

    input  wire        SPI_MOSI,
    input  wire        SPI_SCK,
    input  wire        SPI_SSEL,
    output wire        SPI_MISO,

    input  wire        PUF_ENABLE,
    output wire        PUF_READY,

    input  wire        USE_PUF,

    output wire        LED_BUSY,
    output wire        LED_DONE,
    output wire        LED_ERROR
);


    wire          ext_key_valid;
    wire          ext_key_locked;
    wire [127:0] selected_key;
    wire [135:0] spi_received;
    wire         spi_rxed;
    wire [135:0] spi_to_send;
    wire         spi_txed;
    wire        start, enc_mode;
    wire [127:0] nonce_in;
    wire        ad_wr, msg_wr;
    wire [63:0] ad_wdata, msg_wdata;
    wire        ad_wlast, msg_wlast;
    wire [2:0]  ad_wlast_bytes, msg_wlast_bytes;
    wire        busy, done;
    wire [127:0] tag_out;
    wire        tag_valid;
    wire        tag_ack_wire;
    (*DONT_TOUCH="TRUE"*)
    wire pll_locked;
    (*DONT_TOUCH="TRUE"*)
    wire clk_out;
    (*DONT_TOUCH="TRUE"*)
    wire clk_locked=pll_locked & clk_out;    
    PLL pll_inst (
        .clk_in1 (clk),
        .clk_out1(clk_out),
        .resetn  (rst_n),
        .locked  (pll_locked)
    );

    ascon_logic logic_blk (
        .clk(clk_locked),
        .rst_n(rst_n),
        .USE_PUF(USE_PUF),
        .puf_key(128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA),
        .ext_key_ctrl(ext_key_ctrl),
        .ext_key_valid(ext_key_valid),
        .ext_key_locked(ext_key_locked),
        .busy(busy),
        .done(done),
        .sync_rst_n(sync_rst_n),
        .selected_key(selected_key),
        .LED_BUSY(LED_BUSY),
        .LED_DONE(LED_DONE),
        .LED_ERROR(LED_ERROR)
    );



    ascon_controller controller (
        .clk(clk_locked),
        .rst_n(sync_rst_n),
        .spi_received(spi_received),
        .spi_rxed(spi_rxed),
        .spi_txed(spi_txed),
        .spi_to_send(spi_to_send),
        .start(start),
        .enc_mode(enc_mode),
        .key_in(selected_key),
        .nonce_in(nonce_in),
        .ad_wr(ad_wr),
        .ad_wdata(ad_wdata),
        .ad_wlast(ad_wlast),
        .ad_wlast_bytes(ad_wlast_bytes),
        .msg_wr(msg_wr),
        .msg_wdata(msg_wdata),
        .msg_wlast(msg_wlast),
        .msg_wlast_bytes(msg_wlast_bytes),
        .busy(busy),
        .done(done),
        .tag_out(tag_out),
        .tag_ack(tag_ack_wire),
        .ext_key_out(ext_key_ctrl),
        .ext_key_valid(ext_key_valid),
        .ext_key_locked(ext_key_locked)
    );


    SPI #(.LENGTH(136), .RCOND(1)) spi_interface (
        .MOSI(SPI_MOSI),
        .SCK(SPI_SCK),
        .CLK(clk_locked),         
        .SSEL(SPI_SSEL),
        .RESET(~sync_rst_n),
        .TO_SEND(spi_to_send),
        .RECEIVED(spi_received),
        .RXED(spi_rxed),
        .TXED(spi_txed),
        .MISO(SPI_MISO)
    );


    ascon_core ascon_core_inst (
        .clk(clk_locked),
        .rst_n(sync_rst_n),
        .start(start),
        .enc_mode(enc_mode),
        .key_in(selected_key),
        .nonce_in(nonce_in),
        .ad_wr(ad_wr),
        .ad_wdata(ad_wdata),
        .ad_wlast(ad_wlast),
        .ad_wlast_bytes(ad_wlast_bytes),
        .msg_wr(msg_wr),
        .msg_wdata(msg_wdata),
        .msg_wlast(msg_wlast),
        .msg_wlast_bytes(msg_wlast_bytes),
        .out_rd(1'b0),
        .out_rdata(),
        .out_rvalid(),
        .out_rlast(),
        .out_rlast_bytes(),
        .tag_out(tag_out),
        .tag_valid(tag_valid),
        .busy(busy),
        .done(done),
        .tag_ack(tag_ack_wire)
    );

endmodule
