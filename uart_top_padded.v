`timescale 1ns / 1ps

// Padded top-level: wraps uart_top's core logic with generic I/O pad
// cells (ipad for inputs, opad for outputs) for chip-level integration.
//
// NOTE: ipad/opad here are GENERIC placeholder pad cells. Swap these
// for your actual PDK's pad library cells (e.g. PDDW*, IOPAD*, etc.)
// and update the port names below (PAD/C/I) to match that library's
// interface before this is used in a real tapeout flow.
//
//   ipad : chip-pin -> core signal   (input pad)
//     .PAD(chip_pin)  - bond pad / chip pin
//     .C  (core_sig)  - buffered signal into the core
//
//   opad : core signal -> chip-pin   (output pad)
//     .PAD(chip_pin)  - bond pad / chip pin
//     .I  (core_sig)  - signal driven from the core

module uart_top_padded(
    input            pad_rst,
    input      [7:0] pad_data_in,
    input            pad_wr_en,
    input            pad_clk,
    input            pad_rdy_clr,
    output           pad_rdy,
    output           pad_busy,
    output     [7:0] pad_data_out
);

    // Core-side signals (post-pad, pre-core)
    wire            rst_core;
    wire [7:0]      data_in_core;
    wire            wr_en_core;
    wire            clk_core;
    wire            rdy_clr_core;
    wire            rdy_core;
    wire            busy_core;
    wire [7:0]      data_out_core;

    // ---------------- Input pads ----------------
    ipad ipad_rst      (.PAD(pad_rst),     .C(rst_core));
    ipad ipad_wr_en    (.PAD(pad_wr_en),   .C(wr_en_core));
    ipad ipad_clk      (.PAD(pad_clk),     .C(clk_core));
    ipad ipad_rdy_clr  (.PAD(pad_rdy_clr), .C(rdy_clr_core));

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_data_in_pads
            ipad ipad_data_in (.PAD(pad_data_in[i]), .C(data_in_core[i]));
        end
    endgenerate

    // ---------------- Output pads ----------------
    opad opad_rdy   (.PAD(pad_rdy),  .I(rdy_core));
    opad opad_busy  (.PAD(pad_busy), .I(busy_core));

    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_data_out_pads
            opad opad_data_out (.PAD(pad_data_out[i]), .I(data_out_core[i]));
        end
    endgenerate

    // ---------------- Core logic ----------------
    uart_top core (
        .rst      (rst_core),
        .data_in  (data_in_core),
        .wr_en    (wr_en_core),
        .clk      (clk_core),
        .rdy_clr  (rdy_clr_core),
        .rdy      (rdy_core),
        .busy     (busy_core),
        .data_out (data_out_core)
    );

endmodule
