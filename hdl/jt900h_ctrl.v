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
    input       [7:0] flags,
    input             div_busy,
    output reg        bs,
    output reg        ws,
    output reg        qs,
    output reg        cc,       // condition code
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
reg        stack_bsy, cc;
wire       still;

assign still = div_busy;

always @* begin
    case( md[3:0] )             // 4-bit cc conditions
        0:  cc = 0;          // false
        1:  cc = flags[FS]^flags[FV];               // signed <
        2:  cc = flags[FZ] | (flags[FS]^flags[FV]); // signed <=
        3:  cc = flags[FZ] | flags[FC];             // <=
        4:  cc = flags[FV];  // overflow
        5:  cc = flags[FS];  // minux
        6:  cc = flags[FZ];  // =
        7:  cc = flags[FC];  // carry
        8:  cc = 1;          // true
        9:  cc = ~(flags[FS]^flags[FV]); // >=
        10: cc = ~(flags[FZ]|(flags[FS]^flags[FV])); // signed >
        11: cc = ~(flags[FZ]|flags[FC]); // >
        12: cc = ~flags[FV];
        13: cc = ~flags[FS];
        14: cc = ~flags[FZ];
        15: cc = ~flags[FC];
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        uaddr      <= IVRD;
        jsr_ret    <= 0;
        iv         <= 4'o17; // reset vector
        ba         <= 0;
        stack_bsy  <= 1;
        {bs,ws,qs} <= 0;
    end else if(cen) begin
        if(  widen ) {qs,ws} <= {ws,bs};
        if( !still ) uaddr[3:0] <= nx_ualo;
        if( ni ) begin
            uaddr <= { 2'd0, md[7:0], 4'd0 };
            stack_bsy  <= 0;
            {bs,ws,qs} <= 0;
        end
        if( jsr_en && (jsr_sel!=NCC_JSR || !cc) ) begin
            jsr_ret      <= uaddr;
            jsr_ret[3:0] <= nx_ualo;
            uaddr        <= jsr_ua;
        end
    end
end

endmodule