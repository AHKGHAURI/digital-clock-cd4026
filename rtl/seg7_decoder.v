// =============================================================
//  seg7_decoder.v
//  Converts a 4-bit BCD digit (0–9) into 7-segment signals.
//  Replaces the built-in decoder inside the CD4026.
//
//  Segment encoding (active HIGH, common cathode):
//
//       aaa
//      f   b
//      f   b
//       ggg
//      e   c
//      e   c
//       ddd
//
//  seg[6:0] = { a, b, c, d, e, f, g }
//
//  For common-anode displays, invert the output: ~seg
// =============================================================

module seg7_decoder (
    input  wire [3:0] bcd,   // BCD digit input (0–9)
    output reg  [6:0] seg    // segment outputs {a,b,c,d,e,f,g}
);

    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b111_1110;  // 0
            4'd1: seg = 7'b011_0000;  // 1
            4'd2: seg = 7'b110_1101;  // 2
            4'd3: seg = 7'b111_1001;  // 3
            4'd4: seg = 7'b011_0011;  // 4  (corrected)
            4'd5: seg = 7'b101_1011;  // 5
            4'd6: seg = 7'b101_1111;  // 6
            4'd7: seg = 7'b111_0000;  // 7
            4'd8: seg = 7'b111_1111;  // 8
            4'd9: seg = 7'b111_1011;  // 9
            default: seg = 7'b000_0000; // blank for invalid input
        endcase
    end

endmodule
