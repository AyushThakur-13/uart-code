`timescale 1ns / 1ps

module uart_top_tb;

    reg        clk, rst;
    reg  [7:0] data_in;
    reg        wr_en;
    reg        rdy_clr;

    wire       rdy;
    wire [7:0] dout;
    wire       busy;

    reg [7:0] tx_data_log;
    reg [7:0] rx_data_log;
    integer   tx_count;
    integer   rx_count;

    uart_top dut (
        .rst     (rst),
        .data_in (data_in),
        .wr_en   (wr_en),
        .clk     (clk),
        .rdy_clr (rdy_clr),
        .rdy     (rdy),
        .busy    (busy),
        .data_out(dout)
    );

    // FIX: Initialize integer counters in initial block, not at declaration
    //      (declaration-time initialization of integers is not universally supported)
    initial begin
        clk         = 0;
        rst         = 0;
        data_in     = 0;
        wr_en       = 0;
        rdy_clr     = 0;
        tx_data_log = 0;
        rx_data_log = 0;
        tx_count    = 0;
        rx_count    = 0;
    end

    always #5 clk = ~clk;  // 100 MHz clock

    // FIX: Corrected $display — format had 4 specifiers but 5 data args.
    //      Removed the duplicate 'data_in' that was causing the misalignment.
    always @(posedge clk) begin
        if (wr_en) begin
            tx_data_log = data_in;
            tx_count    = tx_count + 1;
            $display(" TX #%0d  ->  Sent     : 0x%02H  (%0d)  '%s'",
                     tx_count, data_in, data_in, data_in);
        end
    end

    always @(posedge rdy) begin
        rx_data_log = dout;
        rx_count    = rx_count + 1;
        $display(" RX #%0d  ->  Received : 0x%02H  (%0d)  '%s'",
                 rx_count, dout, dout, dout);

        if (tx_data_log === dout)
            $display("            [PASS] TX == RX  (0x%02H)", dout);
        else
            $display("            [FAIL] TX=0x%02H  RX=0x%02H  MISMATCH!", tx_data_log, dout);
    end

    task send_byte(input [7:0] din);
    begin
        @(negedge clk);
        data_in = din;
        wr_en   = 1'b1;
        @(negedge clk);
        wr_en   = 1'b0;
    end
    endtask

    task clear_ready;
    begin
        @(negedge clk);
        rdy_clr = 1'b1;
        @(negedge clk);
        rdy_clr = 1'b0;
    end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, uart_top_tb);

        @(negedge clk);
        rst = 1'b1;
        @(negedge clk);
        rst = 1'b0;

        send_byte(8'h41);   // 'A'
        wait (!busy);
        wait (rdy);
        clear_ready;

        send_byte(8'h55);   // 'U'
        wait (!busy);
        wait (rdy);
        clear_ready;

        send_byte(8'hA5);
        wait (!busy);
        wait (rdy);
        clear_ready;

        send_byte(8'hFF);
        wait (!busy);
        wait (rdy);
        clear_ready;

        $display("  Total TX: %0d   Total RX: %0d", tx_count, rx_count);

        #400 $finish;
    end

endmodule
