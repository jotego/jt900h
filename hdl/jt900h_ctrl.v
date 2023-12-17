/*  This file is part of JT900H.
    JT900H program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT900H program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT900H.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. https://patreon.com/jotego
    Version: 1.0
    Date: 15-12-2023 */

module jt900h_ctrl(
    input             rst,
    input             clk,
    input             cen,
    input       [7:0] md,
    input       [7:0] flags
);

`include "900h_param.vh"
`include "900h.vh"

localparam FS=7, FZ=6, FH=4, FV=2, FN=1, FC=0; // Flag bits
localparam IVRD   = 14'h0000,       // to be udpated
           INTSRV = 14'h0c70;

wire [4:0] jsr_sel;
reg  [2:0] iv_sel;
wire       halt, swi, ni, still;
reg        nmi_l;
wire [3:0] nx_ualo = uaddr[3:0] + 1'd1;
reg        stack_bsy, jp_ok;

always @* begin
    case( md[3:0] )             // 4-bit cc conditions
        0:  jp_ok = 0;          // false
        1:  jp_ok = flags[FS]^flags[FV];               // signed <
        2:  jp_ok = flags[FZ] | (flags[FS]^flags[FV]); // signed <=
        3:  jp_ok = flags[FZ] | flags[FC];             // <=
        4:  jp_ok = flags[FV];  // overflow
        5:  jp_ok = flags[FS];  // minux
        6:  jp_ok = flags[FZ];  // =
        7:  jp_ok = flags[FC];  // carry
        8:  jp_ok = 1;          // true
        9:  jp_ok = ~(flags[FS]^flags[FV]); // >=
        10: jp_ok = ~(flags[FZ]|(flags[FS]^flags[FV])); // signed >
        11: jp_ok = ~(flags[FZ]|flags[FC]); // >
        12: jp_ok = ~flags[FV];
        13: jp_ok = ~flags[FS];
        14: jp_ok = ~flags[FZ];
        15: jp_ok = ~flags[FC];
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        uaddr   <= IVRD;
        jsr_ret <= 0;
        iv      <= 4'o17; // reset vector
        ba      <= 0;
        stack_bsy <= 1;
    end else if(cen) begin
        uaddr[3:0] <= nx_ualo;
        if( ni ) begin
            uaddr <= { 2'd0, md[7:0], 4'd0 };
            stack_bsy <= 0;
        end
        if( jsr_en && (jsr_sel!=NCC_JSR || !jp_ok) ) begin
            jsr_ret      <= uaddr;
            jsr_ret[3:0] <= nx_ualo;
            uaddr        <= jsr_ua;
        end
    end
end

endmodule