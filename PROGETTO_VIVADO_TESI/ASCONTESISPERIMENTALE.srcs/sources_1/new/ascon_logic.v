`timescale 1ns / 1ps
module ascon_logic (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        USE_PUF,

    input  wire [127:0] puf_key,
    input  wire [127:0] ext_key_ctrl,
    input  wire         ext_key_valid,
    input  wire         ext_key_locked,

    input  wire         busy,
    input  wire         done,

 
    output wire         sync_rst_n,
    output wire [127:0] selected_key,
    output wire         LED_BUSY,
    output wire         LED_DONE,
    output wire         LED_ERROR
);


    localparam [127:0] EXT_KEY_DEFAULT = 128'h000102030405060708090A0B0C0D0E0F;

    // Reset sincronizzato
    reg [2:0] reset_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_sync <= 3'b000;
        end else begin
            reset_sync <= {reset_sync[1:0], 1'b1};
        end
    end
    assign sync_rst_n = reset_sync[2];

    // Latch chiave esterna (scritta dal controller)
    reg  [127:0]  latched_ext_key;
    reg           latched_ext_valid;

    always @(posedge clk or negedge sync_rst_n) begin
        if (!sync_rst_n) begin
            latched_ext_key   <= 128'd0;
            latched_ext_valid <= 1'b0;
        end else begin
            if (ext_key_valid && !ext_key_locked) begin
                latched_ext_key <= ext_key_ctrl;
                latched_ext_valid <= 1'b1;
            end
            if (ext_key_locked) begin
                latched_ext_valid <= 1'b1;
            end
        end
    end

    assign selected_key = (USE_PUF) ? puf_key
                          : ((latched_ext_valid && !ext_key_locked) ? latched_ext_key : EXT_KEY_DEFAULT);


    assign LED_BUSY  = busy;
    assign LED_DONE  = done;
    assign LED_ERROR = 1'b0; 

endmodule
