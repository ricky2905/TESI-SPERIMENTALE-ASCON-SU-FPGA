`timescale 1ns / 1ps

module ascon_perm (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire  [3:0]  rounds,
    input  wire [63:0]  in_x0,
    input  wire [63:0]  in_x1,
    input  wire [63:0]  in_x2,
    input  wire [63:0]  in_x3,
    input  wire [63:0]  in_x4,
    output reg  [63:0]  out_x0,
    output reg  [63:0]  out_x1,
    output reg  [63:0]  out_x2,
    output reg  [63:0]  out_x3,
    output reg  [63:0]  out_x4,
    output reg          busy,
    output reg          done
);

    reg [63:0] sx0, sx1, sx2, sx3, sx4; // current state
    reg [63:0] s0, s1, s2, s3, s4;      // registered S-box
    reg [3:0]  round_ctr;
    reg [3:0]  rounds_latched;
    reg        running;
    reg        phase; // 0 = Sbox stage next, 1 = Linear stage next


    function [7:0] rc_byte;
        input [3:0] idx;
        begin
            case (idx)
                4'd0 : rc_byte = 8'hf0;
                4'd1 : rc_byte = 8'he1;
                4'd2 : rc_byte = 8'hd2;
                4'd3 : rc_byte = 8'hc3;
                4'd4 : rc_byte = 8'hb4;
                4'd5 : rc_byte = 8'ha5;
                4'd6 : rc_byte = 8'h96;
                4'd7 : rc_byte = 8'h87;
                4'd8 : rc_byte = 8'h78;
                4'd9 : rc_byte = 8'h69;
                4'd10: rc_byte = 8'h5a;
                4'd11: rc_byte = 8'h4b;
                default: rc_byte = 8'h00;
            endcase
        end
    endfunction

    function [63:0] ror64;
        input [63:0] x;
        input integer n;
        begin
            ror64 = (x >> n) | (x << (64 - n));
        end
    endfunction

    wire [63:0] x2rc_w;
    wire [63:0] s0_w, s1_w, s2_w, s3_w, s4_w;
    wire [63:0] t0_w, t1_w, t2_w, t3_w, t4_w;
    wire [63:0] b0_w_pre, b1_w_pre, b2_w_pre, b3_w_pre, b4_w_pre;
    wire [63:0] b0_w, b1_w, b2_w, b3_w, b4_w;

    assign x2rc_w = sx2 ^ {56'h0, rc_byte(round_ctr)};

    assign s0_w = sx0 ^ sx4;
    assign s1_w = sx1;
    assign s2_w = x2rc_w ^ sx1;
    assign s3_w = sx3;
    assign s4_w = sx4 ^ sx3;

    assign t0_w = ~s0_w & s1_w;
    assign t1_w = ~s1_w & s2_w;
    assign t2_w = ~s2_w & s3_w;
    assign t3_w = ~s3_w & s4_w;
    assign t4_w = ~s4_w & s0_w;

    assign b0_w_pre = s0_w ^ t1_w;
    assign b1_w_pre = s1_w ^ t2_w;
    assign b2_w_pre = s2_w ^ t3_w;
    assign b3_w_pre = s3_w ^ t4_w;
    assign b4_w_pre = s4_w ^ t0_w;

    // post-processing
    assign b1_w = b1_w_pre ^ b0_w_pre;
    assign b0_w = b0_w_pre ^ b4_w_pre;
    assign b3_w = b3_w_pre ^ b2_w_pre;
    assign b2_w = ~b2_w_pre;
    assign b4_w = b4_w_pre;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sx0 <= 64'd0; sx1 <= 64'd0; sx2 <= 64'd0; sx3 <= 64'd0; sx4 <= 64'd0;
            s0  <= 64'd0; s1  <= 64'd0; s2  <= 64'd0; s3  <= 64'd0; s4  <= 64'd0;
            out_x0 <= 64'd0; out_x1 <= 64'd0; out_x2 <= 64'd0; out_x3 <= 64'd0; out_x4 <= 64'd0;
            round_ctr <= 4'd0; rounds_latched <= 4'd0; running <= 1'b0;
            busy <= 1'b0; done <= 1'b0;
            phase <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !running) begin
                sx0 <= in_x0; sx1 <= in_x1; sx2 <= in_x2; sx3 <= in_x3; sx4 <= in_x4;
                rounds_latched <= rounds;
                round_ctr <= (rounds != 0) ? rounds - 1 : 4'd0;
                running <= 1'b1;
                busy <= 1'b1;
                phase <= 1'b0;
            end else if (running) begin
                if (phase == 1'b0) begin
                    s0 <= b0_w;
                    s1 <= b1_w;
                    s2 <= b2_w;
                    s3 <= b3_w;
                    s4 <= b4_w;
                    phase <= 1'b1;
                end else begin
                    sx0 <= s0 ^ ror64(s0,19) ^ ror64(s0,28);
                    sx1 <= s1 ^ ror64(s1,61) ^ ror64(s1,39);
                    sx2 <= s2 ^ ror64(s2,1)  ^ ror64(s2,6);
                    sx3 <= s3 ^ ror64(s3,10) ^ ror64(s3,17);
                    sx4 <= s4 ^ ror64(s4,7)  ^ ror64(s4,41);

                    if (round_ctr == 4'd0) begin
                        running <= 1'b0;
                        busy <= 1'b0;
                        done <= 1'b1;
                        out_x0 <= s0 ^ ror64(s0,19) ^ ror64(s0,28);
                        out_x1 <= s1 ^ ror64(s1,61) ^ ror64(s1,39);
                        out_x2 <= s2 ^ ror64(s2,1)  ^ ror64(s2,6);
                        out_x3 <= s3 ^ ror64(s3,10) ^ ror64(s3,17);
                        out_x4 <= s4 ^ ror64(s4,7)  ^ ror64(s4,41);
                    end else begin
                        round_ctr <= round_ctr - 1;
                        phase <= 1'b0;
                    end
                end
            end else begin
                // idle
                busy <= 1'b0;
            end
        end
    end

endmodule