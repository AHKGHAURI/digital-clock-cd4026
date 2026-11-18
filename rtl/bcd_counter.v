// =============================================================
//  bcd_counter.v
//  General-purpose BCD (0–MAX) decade counter.
//  Equivalent to the CD4026 chain in the hardware circuit.
//
//  Parameters
//    MAX  — the count at which the counter resets to 0
//           (e.g. 9 for units, 5 for tens-of-minutes/hours)
//
//  Ports
//    clk      — system clock
//    rst      — active-high synchronous reset (resets to 0)
//    en       — enable: only counts when HIGH (replaces INH)
//    tick     — 1-Hz (or carry) pulse input
//    count    — current BCD count output (4 bits)
//    carry    — goes HIGH for one cycle when count rolls over
//               (replaces CO on CD4026 — clocks next digit)
// =============================================================

module bcd_counter #(
    parameter MAX = 9    // counts 0 → MAX, then wraps to 0
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       tick,
    output reg  [3:0] count,
    output reg        carry
);

    always @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            carry <= 1'b0;
        end else if (en && tick) begin
            if (count == MAX) begin
                count <= 4'd0;
                carry <= 1'b1;   // carry pulse for one cycle
            end else begin
                count <= count + 1;
                carry <= 1'b0;
            end
        end else begin
            carry <= 1'b0;       // carry is always single-cycle
        end
    end
endmodule
