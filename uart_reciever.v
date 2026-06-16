`timescale 1ns / 1ps

// FIX: Removed inline register initializers (= value) — not synthesizable in ASIC/PDK flows.
//      All state is now driven purely by the synchronous reset.
module uart_reciever(
    input            clk,
    input            rst,
    input            rx,
    input            rdy_clr,
    input            clken,
    output reg       rdy,
    output reg [7:0] data_out
);

    localparam RX_STATE_START = 2'b00;
    localparam RX_STATE_DATA  = 2'b01;
    localparam RX_STATE_STOP  = 2'b10;

    // FIX: No inline initialization — synthesis-safe
    reg [1:0] state;
    reg [3:0] sample;
    reg [3:0] index;
    reg [7:0] scratch;

    // Ready-clear and reset logic
    always @(posedge clk) begin
        if (rst) begin
            rdy      <= 1'b0;
            data_out <= 8'd0;
        end else if (rdy_clr) begin
            rdy <= 1'b0;
        end
    end

    // Main receiver FSM
    always @(posedge clk) begin
        if (rst) begin
            state   <= RX_STATE_START;
            sample  <= 4'd0;
            index   <= 4'd0;
            scratch <= 8'd0;
        end else if (clken) begin
            case (state)
                RX_STATE_START: begin
                    // Count until mid-point of start bit (sample 15)
                    if (!rx || sample != 4'd0)
                        sample <= sample + 4'd1;

                    if (sample == 4'd15) begin
                        state   <= RX_STATE_DATA;
                        index   <= 4'd0;
                        sample  <= 4'd0;
                        scratch <= 8'd0;
                    end
                end

                RX_STATE_DATA: begin
                    sample <= sample + 4'd1;
                    // Sample each data bit at midpoint (sample == 8)
                    if (sample == 4'h8) begin
                        scratch[index] <= rx;
                        index <= index + 4'd1;
                    end
                    if (index == 4'd8 && sample == 4'd15)
                        state <= RX_STATE_STOP;
                end

                RX_STATE_STOP: begin
                    if (sample == 4'd15) begin
                        state    <= RX_STATE_START;
                        data_out <= scratch;   // latch received byte
                        rdy      <= 1'b1;
                        sample   <= 4'd0;
                    end else begin
                        sample <= sample + 4'd1;
                    end
                end

                default: state <= RX_STATE_START;
            endcase
        end
    end

endmodule
