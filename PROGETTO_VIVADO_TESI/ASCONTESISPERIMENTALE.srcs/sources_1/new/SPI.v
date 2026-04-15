`timescale 1ns / 1ps
//(*KEEP_HIERARCHY="YES"*)
module SPI
#(
    parameter LENGTH = 136,
    parameter RCOND = 0
)
(
    input MOSI,
    input SCK,
    input CLK,
    input SSEL,
    input RESET,
    input [LENGTH-1:0] TO_SEND,
    output reg [LENGTH-1:0] RECEIVED,
    output reg RXED,
    output reg TXED,
    output reg MISO
);

    (*ASYNC_REG="TRUE"*) reg [1:0] B_MOSI;
    (*ASYNC_REG="TRUE"*) reg [1:0] B_SSEL;
    (*ASYNC_REG="TRUE"*) reg [1:0] B_SCK;

    reg [1:0] PRS, NES; // present and next state of the machine
    reg [LENGTH-1:0] B_RECEIVED; // shift register to store MOSI data
    reg [8:0] CNT; // counter of the machine

    localparam [1:0] // states of FSM
        ZERO = 2'b00,
        ONE  = 2'b01,
        TWO  = 2'b10;

    wire PE_SCK, NE_SCK, PE_SSEL, NE_SSEL;

    assign PE_SCK = (B_SCK === (2'b01)); // capture the rising edge
    assign NE_SCK = (B_SCK === (2'b10)); // capture the falling edge

    // interface to ft232h CDC
    always @(posedge CLK) begin
        if (RESET == RCOND) begin
            B_SCK  <= 2'b00;
            B_SSEL <= 2'b00;
            B_MOSI <= 2'b00;
        end else begin
            B_SCK  <= {B_SCK[0], SCK};
            B_SSEL <= {B_SSEL[0], SSEL};
            B_MOSI <= {B_MOSI[0], MOSI};
        end
    end

    always @(posedge CLK) begin
        if (RESET == RCOND)
            PRS <= ZERO;
        else
            PRS <= NES;
    end

    always @(*) begin
        NES <= ZERO;
        begin
            case (PRS)
                ZERO: begin
                    if (!B_SSEL[1])
                        NES <= ONE;
                    else
                        NES <= ZERO;
                end
                ONE: begin
                    if (CNT == LENGTH)
                        NES <= TWO;
                    else
                        NES <= ONE;
                end
                TWO: begin
                    if (B_SSEL[1])
                        NES <= ZERO;
                    else
                        NES <= TWO;
                end
                default:
                    NES <= ZERO;
            endcase
        end
    end

    // OUTPUT LOGIC
    always @(posedge CLK) begin
        if (RESET == RCOND) begin
            RXED       <= 0;
            TXED       <= 0;
            RECEIVED   <= {LENGTH{1'b0}};
            B_RECEIVED <= {LENGTH{1'b0}};
            MISO       <= 1'bZ;
            CNT        <= 0;
        end else begin
            case (PRS)
                ZERO: begin
                    CNT        <= 0;
                    RXED       <= 0;
                    TXED       <= 0;
                    B_RECEIVED <= {LENGTH{1'b0}};
                    MISO       <= 1'bZ;
                end
                ONE: begin
                    if (CNT < LENGTH) begin
                        MISO <= TO_SEND[LENGTH - 1 - CNT];
                        if (PE_SCK) begin
                            B_RECEIVED <= {B_RECEIVED[LENGTH - 1 - 1:0], B_MOSI[1]};
                        end else if (NE_SCK) begin
                            CNT <= CNT + 1'b1;
                            if (CNT + 1 < LENGTH)
                                MISO <= TO_SEND[LENGTH - 2 - CNT];
                            else
                                MISO <= TO_SEND[0];
                        end
                    end else
                        MISO <= TO_SEND[0];
                end
                TWO: begin
                    MISO       <= TO_SEND[0];
                    CNT        <= 0;
                    RXED       <= 1;
                    TXED       <= 1;
                    RECEIVED   <= B_RECEIVED;
                end
                default: begin
                    MISO       <= 1'bZ;
                    CNT        <= 0;
                    RXED       <= 0;
                    TXED       <= 0;
                    B_RECEIVED <= {LENGTH{1'b0}};
                    RECEIVED   <= {LENGTH{1'b0}};
                end
            endcase
        end
    end

endmodule