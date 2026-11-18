// =============================================================
//  clk_divider.v
//  Divides a fast system clock down to a 1 Hz pulse.
//  Change CLK_FREQ to match your FPGA/board clock (Hz).
//  For simulation, set CLK_FREQ to a small value like 10.
// =============================================================

module clk_divider #(
    parameter CLK_FREQ = 50_000_000   // 50 MHz default (change as needed)
)(
    input  wire clk,      // System clock input
    input  wire rst,      // Active-high synchronous reset
    output reg  clk_1hz   // 1 Hz tick output (1 cycle wide pulse)
);

    // Counter needs to count from 0 to (CLK_FREQ - 1)
    // Width: ceil(log2(CLK_FREQ))
    localparam COUNT_MAX = CLK_FREQ - 1;
    localparam WIDTH     = $clog2(CLK_FREQ);

    reg [WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter  <= 0;
            clk_1hz  <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                counter  <= 0;
                clk_1hz  <= 1;   // single-cycle pulse every 1 second
            end else begin
                counter  <= counter + 1;
                clk_1hz  <= 0;
            end
        end
    end

endmodule
