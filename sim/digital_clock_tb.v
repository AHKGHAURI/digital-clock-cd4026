// =============================================================
//  digital_clock_tb.v  —  TESTBENCH
//  Simulates the digital clock at high speed.
//  Set CLK_FREQ=10 so 10 clock ticks = 1 simulated second.
//
//  Run with:  iverilog -o clock_tb digital_clock_tb.v && vvp clock_tb
//  Or in ModelSim / Vivado / Quartus simulator.
// =============================================================

`timescale 1ns/1ps

module digital_clock_tb;

    // ---- Parameters ----
    localparam CLK_FREQ  = 10;        // 10 ticks = 1 simulated second
    localparam CLK_HALF  = 5;         // 5 ns half-period → 100 MHz sim clock
    localparam SIM_SECS  = 90;        // simulate 90 seconds  (tests MM rollover)

    // ---- DUT signals ----
    reg        clk = 0;
    reg        rst = 1;
    wire [6:0] seg_su, seg_st, seg_mu, seg_mt, seg_hu, seg_ht;

    // ---- Instantiate DUT ----
    digital_clock #(.CLK_FREQ(CLK_FREQ)) dut (
        .clk   (clk),
        .rst   (rst),
        .seg_su(seg_su), .seg_st(seg_st),
        .seg_mu(seg_mu), .seg_mt(seg_mt),
        .seg_hu(seg_hu), .seg_ht(seg_ht)
    );

    // ---- Clock generation ----
    always #(CLK_HALF) clk = ~clk;

    // ---- Internal count wires for readable display ----
    wire [3:0] su = dut.su_cnt, st = dut.st_cnt;
    wire [3:0] mu = dut.mu_cnt, mt = dut.mt_cnt;
    wire [3:0] hu = dut.hu_cnt, ht = dut.ht_cnt;

    integer prev_su = -1;

    // ---- Monitor: print time whenever seconds units changes ----
    always @(posedge clk) begin
        if (su !== prev_su) begin
            $display("Time: %0d%0d:%0d%0d:%0d%0d  | seg_ht=%b seg_hu=%b seg_mt=%b seg_mu=%b seg_st=%b seg_su=%b",
                ht, hu, mt, mu, st, su,
                seg_ht, seg_hu, seg_mt, seg_mu, seg_st, seg_su);
            prev_su = su;
        end
    end

    // ---- Test sequence ----
    initial begin
        $dumpfile("clock_tb.vcd");
        $dumpvars(0, digital_clock_tb);

        // Hold reset for 3 clock cycles
        repeat(3) @(posedge clk);
        rst = 0;

        // Let the clock run for SIM_SECS simulated seconds
        // Each simulated second = CLK_FREQ clock ticks
        repeat(SIM_SECS * CLK_FREQ) @(posedge clk);

        $display("\n--- Simulation complete ---");
        $display("Final time: %0d%0d:%0d%0d:%0d%0d", ht, hu, mt, mu, st, su);
        $finish;
    end

    // ---- Assertions: check rollover ----
    always @(posedge clk) begin
        // Seconds tens should never exceed 5
        if (st > 5)
            $error("FAIL: seconds tens = %0d (should be 0-5)", st);

        // Minutes tens should never exceed 5
        if (mt > 5)
            $error("FAIL: minutes tens = %0d (should be 0-5)", mt);

        // Hours should never reach 24
        if (ht == 2 && hu >= 4)
            $error("FAIL: hours = %0d%0d (should reset at 24)", ht, hu);
    end

endmodule
