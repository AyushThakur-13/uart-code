`timescale 1ns / 1ps

// FIX 1: Removed inline register initializers (= value) — not synthesizable in ASIC/PDK flows.
//         All state is now driven purely by the synchronous reset.
// FIX 2: bitpos is now reset to 0 inside the reset block AND when entering STATE_START,
//         so every transmission starts from bit 0, not from a stale value.
module uart_sender(
    input            clk,
    input            wr_en,
    input            enb,
    input            rst,
    input      [7:0] data_in,
    output reg       tx,
    output           tx_busy
);

    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    // FIX: No inline initialization — synthesis-safe
    reg [7:0] data;
    reg [2:0] bitpos;
    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            tx     <= 1'b1;
            state  <= STATE_IDLE;
            bitpos <= 3'h0;
            data   <= 8'h00;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx <= 1'b1;
                    if (wr_en) begin
                        state  <= STATE_START;
                        data   <= data_in;
                        bitpos <= 3'h0;  // FIX: reset bitpos here, before each new transmission
                    end
                end

                STATE_START: begin
                    if (enb) begin
                        tx    <= 1'b0;   // start bit
                        state <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    if (enb) begin
                        tx <= data[bitpos];
                        if (bitpos == 3'h7) begin
                            state  <= STATE_STOP;
                            // FIX: reset bitpos so it doesn't carry stale value to next frame
                            bitpos <= 3'h0;
                        end else begin
                            bitpos <= bitpos + 3'h1;
                        end
                    end
                end

                STATE_STOP: begin
                    if (enb) begin
                        tx    <= 1'b1;   // stop bit
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    tx    <= 1'b1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    assign tx_busy = (state != STATE_IDLE);

endmodule
