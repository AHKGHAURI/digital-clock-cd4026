// =============================================================
//  digital_clock.v  —  TOP LEVEL
//  HH:MM:SS digital clock — Verilog equivalent of the
//  CD4026 + NE555 circuit in the schematic.
//
//  Structure mirrors the hardware exactly:
//
//    NE555 astable  →  clk_divider  (1 Hz tick)
//
//    Seconds units  →  bcd_counter MAX=9   (0-9)
//    Seconds tens   →  bcd_counter MAX=5   (0-5)  ← AND gate reset at 6
//    Minutes units  →  bcd_counter MAX=9
//    Minutes tens   →  bcd_counter MAX=5   ← AND gate reset at 6
//    Hours units    →  bcd_counter MAX=9
//    Hours tens     →  bcd_counter MAX=2   ← AND gate resets both at 24
//
//  Each bcd_counter's carry output clocks the next stage,
//  exactly as CO on the CD4026 clocks the next IC's CLK pin.
//
//  Outputs
//    seg_su[6:0]  — seconds units   7-segment
//    seg_st[6:0]  — seconds tens    7-segment
//    seg_mu[6:0]  — minutes units   7-segment
//    seg_mt[6:0]  — minutes tens    7-segment
//    seg_hu[6:0]  — hours units     7-segment
//    seg_ht[6:0]  — hours tens      7-segment
// =============================================================

module digital_clock #(
    parameter CLK_FREQ = 50_000_000   // match your board clock
)(
    input  wire        clk,           // system clock
    input  wire        rst,           // active-high reset → sets 00:00:00

    // 7-segment outputs (active HIGH, common cathode)
    output wire [6:0]  seg_su,        // seconds units
    output wire [6:0]  seg_st,        // seconds tens
    output wire [6:0]  seg_mu,        // minutes units
    output wire [6:0]  seg_mt,        // minutes tens
    output wire [6:0]  seg_hu,        // hours units
    output wire [6:0]  seg_ht         // hours tens
);

    // ----------------------------------------------------------------
    // 1 Hz tick from clock divider  (replaces NE555 + R1/R2/C1)
    // ----------------------------------------------------------------
    wire tick_1hz;

    clk_divider #(.CLK_FREQ(CLK_FREQ)) u_div (
        .clk    (clk),
        .rst    (rst),
        .clk_1hz(tick_1hz)
    );

    // ----------------------------------------------------------------
    // BCD count wires
    // ----------------------------------------------------------------
    wire [3:0] su_cnt, st_cnt;   // seconds units / tens
    wire [3:0] mu_cnt, mt_cnt;   // minutes units / tens
    wire [3:0] hu_cnt, ht_cnt;   // hours units   / tens

    // Carry wires  (CO equivalent)
    wire su_co, st_co;
    wire mu_co, mt_co;
    wire hu_co, ht_co;

    // ----------------------------------------------------------------
    // Hours reset logic
    //   Reset both hour digits when hours == 23 AND next carry arrives
    //   Equivalent to the AND gate (U8:A/B) detecting "24" on segments
    // ----------------------------------------------------------------
    wire hour_rst_cond = (ht_cnt == 4'd2 && hu_cnt == 4'd3);
    wire hour_rst      = rst | (hour_rst_cond && mt_co);
    // mt_co is the carry that would increment hours — we intercept it

    // ----------------------------------------------------------------
    // Seconds
    // ----------------------------------------------------------------
    bcd_counter #(.MAX(9)) u_su (
        .clk  (clk), .rst(rst), .en(1'b1),
        .tick (tick_1hz),
        .count(su_cnt), .carry(su_co)
    );

    bcd_counter #(.MAX(5)) u_st (
        .clk  (clk), .rst(rst), .en(1'b1),
        .tick (su_co),           // clocked by seconds-units carry
        .count(st_cnt), .carry(st_co)
    );

    // ----------------------------------------------------------------
    // Minutes
    // ----------------------------------------------------------------
    bcd_counter #(.MAX(9)) u_mu (
        .clk  (clk), .rst(rst), .en(1'b1),
        .tick (st_co),           // clocked by seconds-tens carry
        .count(mu_cnt), .carry(mu_co)
    );

    bcd_counter #(.MAX(5)) u_mt (
        .clk  (clk), .rst(rst), .en(1'b1),
        .tick (mu_co),
        .count(mt_cnt), .carry(mt_co)
    );

    // ----------------------------------------------------------------
    // Hours  (reset at 24 instead of 99)
    // ----------------------------------------------------------------
    bcd_counter #(.MAX(9)) u_hu (
        .clk  (clk), .rst(hour_rst), .en(1'b1),
        .tick (mt_co),           // clocked by minutes-tens carry
        .count(hu_cnt), .carry(hu_co)
    );

    bcd_counter #(.MAX(2)) u_ht (
        .clk  (clk), .rst(hour_rst), .en(1'b1),
        .tick (hu_co),
        .count(ht_cnt), .carry(ht_co)
    );

    // ----------------------------------------------------------------
    // 7-segment decoders  (one per digit, replaces CD4026 built-in decoder)
    // ----------------------------------------------------------------
    seg7_decoder dec_su (.bcd(su_cnt), .seg(seg_su));
    seg7_decoder dec_st (.bcd(st_cnt), .seg(seg_st));
    seg7_decoder dec_mu (.bcd(mu_cnt), .seg(seg_mu));
    seg7_decoder dec_mt (.bcd(mt_cnt), .seg(seg_mt));
    seg7_decoder dec_hu (.bcd(hu_cnt), .seg(seg_hu));
    seg7_decoder dec_ht (.bcd(ht_cnt), .seg(seg_ht));

endmodule
