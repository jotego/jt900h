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
    input             mem_busy,
    output reg        bs,
    output reg        ws,
    output reg        qs,
    output reg        cc,       // condition code
    // signals from ucode
    output            cr_rd,
    output            da2ea,
    output            div,
    output            exff,
    output            full,
    output            inc_pc,
    output            jb5,
    output            mulcheck,
    output            mulsel,
    output            sex,
    output            wr,
    output            zex,
    output      [1:0] ea_sel,
    output      [1:0] opnd_sel,
    output      [2:0] carry_sel,
    output      [2:0] fetch_sel,
    output      [2:0] ral_sel,
    output      [3:0] ld_sel,
    output      [4:0] alu_sel,
    output      [4:0] cc_sel,
    output      [4:0] rmux_sel
);

`include "900h_param.vh"
`include "900h.vh"

localparam FS=7, FZ=6, FH=4, FV=2, FN=1, FC=0; // Flag bits
localparam IVRD   = 14'h0000,       // to be udpated
           INTSRV = 14'h0c70;

wire [4:0] jsr_sel;
reg  [2:0] iv_sel;
reg  [2:0] altss;
wire       halt, swi, still;
reg        nmi_l;
wire [3:0] nx_ualo = uaddr[3:0] + 1'd1;
reg        stack_bsy, cc;
wire       still;

// signals from ucode
wire  [1:0] nxgr_sel,
      [2:0] setw_sel,
      [4:0] jsr_sel;
wire        ni, r32jmp, halt, jb5, retb, retw,
            swpss, widen, waitmem;

assign still = div_busy | (waitmem & mem_busy);

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
        alts       <= 0;
    end else if(cen) begin
        if(  widen ) {qs,ws} <= {ws,bs};
        if(  swpss ) {altss,qs,ws,bs}<={qs,ws,bs,altss};
        case( setw_sel )
            B_SETW: {qs,ws,bs}<=3'b001;
            W_SETW: {qs,ws,bs}<=3'b010;
            Q_SETW: {qs,ws,bs}<=3'b100;
            default:;
        endcase
        if( !still ) uaddr[3:0] <= nx_ualo;
        if( ni ) begin
            uaddr <= { nxgr_sel, md[7:0], 4'd0 };
            stack_bsy  <= 0;
            {bs,ws,qs} <= 0;
        end
        if( jb5 ) uaddr[4:0] <=  uaddr[4:0]-4'd5;
        if((retb&bs) | (retw&ws)) uaddr <= jsr_ret;
        if( jsr_en && (jsr_sel!=NCC_JSR || !cc) ) begin
            jsr_ret      <= uaddr;
            jsr_ret[3:0] <= nx_ualo;
            uaddr        <= jsr_ua;
        end
        if( r32jmp ) begin
            case( md[1:0] )
                0: uaddr = R32_00_SEQA;
                1: uaddr = R32_01_SEQA;
                3: case(md[7:2])
                    0: uaddr = R32_8_SEQA;
                    1: uaddr = R32_16_SEQA;
                endcase
                default:;   // to do: signal a decode error
            endcase
        end
    end
end

endmodule