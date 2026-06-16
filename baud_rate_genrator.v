`timescale 1ns / 1ps

// CLOCK GENERATION LOGIC FOR ACHIEVING A BAUD RATE OF 9600
// FIX: Use localparam with explicit pre-computed constants instead of
//      parameter arithmetic division, which is unreliable in Yosys/ASIC flows.
module baud_rate_genrator(input clock, reset, output reg enb_tx, enb_rx);

    // Pre-computed constants (100 MHz / 9600 = 10416, 100 MHz / (16*9600) = 651)
    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 9600;
    localparam [13:0] DIVISOR_TX = CLK_FREQ / BAUD_RATE;         // 10416
    localparam [9:0]  DIVISOR_RX = CLK_FREQ / (16 * BAUD_RATE);  // 651

    reg [13:0] counter_tx;
    reg [9:0]  counter_rx;

    // SENDER BAUD ENABLE (one pulse per bit period)
    always @(posedge clock) begin
        if (reset) begin
            counter_tx <= 14'd0;
            enb_tx     <= 1'b0;
        end else if (counter_tx == DIVISOR_TX - 14'd1) begin
            counter_tx <= 14'd0;
            enb_tx     <= 1'b1;
        end else begin
            counter_tx <= counter_tx + 14'd1;
            enb_tx     <= 1'b0;
        end
    end

    // RECEIVER BAUD ENABLE (16x oversampling)
    always @(posedge clock) begin
        if (reset) begin
            counter_rx <= 10'd0;
            enb_rx     <= 1'b0;
        end else if (counter_rx == DIVISOR_RX - 10'd1) begin
            counter_rx <= 10'd0;
            enb_rx     <= 1'b1;
        end else begin
            counter_rx <= counter_rx + 10'd1;
            enb_rx     <= 1'b0;
        end
    end

endmodule
