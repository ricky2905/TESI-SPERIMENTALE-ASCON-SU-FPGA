
`timescale 1ns / 1ps
module puf_controller (
    input wire clk,
    input wire rst_n,
    input wire puf_enable,
    input wire [7:0] puf_challenge,
    output reg puf_ready,
    output reg [127:0] puf_response,
    output wire [127:0] key_out
);

    reg [127:0] puf_key;
    reg [2:0] state;
    reg [3:0] ready_delay;

    localparam S_IDLE     = 3'd0;
    localparam S_GENERATE = 3'd1;
    localparam S_READY    = 3'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            puf_ready    <= 1'b0;
            puf_response <= 128'd0;
            puf_key      <= 128'd0;
            ready_delay  <= 4'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    puf_ready <= 1'b0;
                    ready_delay <= 4'd0;
                    if (puf_enable) begin
                        state <= S_GENERATE;
                        puf_response <= {16{puf_challenge}}; 
                    end
                end

                S_GENERATE: begin
                    if (ready_delay < 4'd3) begin
                        ready_delay <= ready_delay + 1;
                        state <= S_GENERATE;
                    end else begin
                        puf_key  <= puf_response;
                        state    <= S_READY;
                        puf_ready <= 1'b1;
                    end
                end

                S_READY: begin
                    if (!puf_enable) begin
                        state     <= S_IDLE;
                        puf_ready <= 1'b0;
                    end
                end
            endcase
        end
    end

    assign key_out = puf_key;

endmodule