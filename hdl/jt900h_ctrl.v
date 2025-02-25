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
    input             zu,       // z from ALU
    input             div_busy,
    input             mem_busy,
    output reg        bs,
    output reg        ws,
    output reg        qs,
    output reg        cc,       // condition code
    output reg        dec_err,  // decode error, will halt forever
    output            halt,
    // interrupts
    input             irq,
    output reg        irq_ack,
    output reg        nstdec,
    input       [2:0] int_lvl,      // interrupt level
    input       [2:0] riff,
    input       [4:0] mode,
    input             dmaen,
    // signals from ucode
    output            da2ea,
    output            div,
    output            exff,
    output            alt,
    output            inc_pc,
    output            mulcheck,
    output            mulsel,
    output            sex,
    output            wr,
    output            zex,
    output      [2:0] cra_sel,
    output      [2:0] ea_sel,
    output      [1:0] opnd_sel,
    output      [2:0] cx_sel,
    output      [1:0] fetch_sel,
    output      [2:0] ral_sel,
    output      [3:0] ld_sel,
    output      [4:0] alu_sel,
    output      [4:0] cc_sel,
    output      [3:0] rmux_sel
);

`include "900h_param.vh"
`include "900h.vh"

localparam FS=7, FZ=6, FH=4, FV=2, FN=1, FC=0; // Flag bits

wire [ 4:0] jsr_sel;
reg  [ 2:0] iv_sel;
reg  [ 2:0] altss;
wire        swi, still;
reg         nmi_l;
wire [ 3:0] nx_ualo;
reg         stack_bsy;
wire        dis_jsr, irq_en;
wire [13:0] newa;
// signals from ucode
wire  [1:0] nxgr_sel, loop_sel;
wire  [2:0] setw_sel;
wire        ni, r32jmp, udmajmp, rets,
            waitmem;

assign still   = div_busy | (waitmem & mem_busy) | halt | dec_err;
assign nx_ualo = uaddr[3:0] + 4'd1;
assign dis_jsr = (jsr_sel==NCC_JSR && cc) || (jsr_sel==ZNI_JSR && !zu);
assign newa    = irq_en ? (dmaen ? UDMABASE_SEQA : INTPSH_SEQA) : {nxgr_sel, md[7:0], 4'd0};
assign irq_en  = irq && int_lvl>=riff && nxgr_sel==0; // it looks like the manual, which points to a > comparison, is wrong

always @* begin
    case( md[3:0] )                                 // 4-bit cc conditions
        0:  cc = 0;                                 // false
        1:  cc = flags[FS]^flags[FV];               // signed <
        2:  cc = flags[FZ] | (flags[FS]^flags[FV]); // signed <=
        3:  cc = flags[FZ] | flags[FC];             // <=
        4:  cc = flags[FV];                         // overflow
        5:  cc = flags[FS];                         // minux
        6:  cc = flags[FZ];                         // =
        7:  cc = flags[FC];                         // carry
        8:  cc = 1;                                 // true
        9:  cc = ~(flags[FS]^flags[FV]);            // >=
        10: cc = ~(flags[FZ]|(flags[FS]^flags[FV]));// signed >
        11: cc = ~(flags[FZ]|flags[FC]);            // >
        12: cc = ~flags[FV];
        13: cc = ~flags[FS];
        14: cc = ~flags[FZ];
        15: cc = ~flags[FC];
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        uaddr      <= INTEXEC_SEQA;
        irq_ack    <= 0;
        jsr_ret    <= 0;
        stack_bsy  <= 1;
        {bs,ws,qs} <= 0;
        altss      <= 0;
        dec_err    <= 0;
        nstdec     <= 0;
    end else if(cen) begin
        if( halt && alt ) dec_err <= 1;
        case( setw_sel )
            // can modify altss
            B_SETW:     begin {qs,ws,bs} <= 3'b001; if(alt) altss <= 3'b001; end
            W_SETW:     begin {qs,ws,bs} <= 3'b010; if(alt) altss <= 3'b010; end
            Q_SETW:     begin {qs,ws,bs} <= 3'b100; if(alt) altss <= 3'b100; end
            S_SETW:     {altss,qs,ws,bs} <= {2{alt ? 3'b001 << md[1:0] : md[4] ? 3'b100 : 3'b010}};
            // only modify working ss
            WIDEN_SETW: {qs,ws,bs} <= alt ? 3'b001 << mode[1:0] : {qs,ws,bs}<<1;
            SHRTN_SETW: {qs,ws,bs} <= {qs,ws,bs}>>1;
            RLD_SETW:   {qs,ws,bs} <= altss;
            default:;
        endcase
        if( !still ) uaddr[3:0] <= nx_ualo;
        if( loop_sel==SET_LOOP ) jsr_ret[3:0] <= uaddr[3:0];
        if( (loop_sel==NZ_LOOP && !zu) ||
            (loop_sel== V_LOOP && (flags[FV] && (!alt || !flags[FZ]))) ) begin
            uaddr[3:0] <= jsr_ret[3:0];
        end else if(ni|(halt&irq_en)) begin
            irq_ack   <= dmaen ? irq_en : stack_bsy; // delay irq_ack until IFF has been loaded
            stack_bsy <= ~dmaen & irq_en;
            uaddr     <= newa; // relies on nxgr specific values (!)
            jsr_ret   <= newa;
            nstdec    <= newa == 14'h0070; // RETI ucode address
            // $display("uA = %X",newa>>4);
            if( nxgr_sel==0 ) {bs,ws,qs} <= 0;
        end
        if( rets&(alt?ws:bs) ) uaddr <= jsr_ret;
        if( jsr_en && !dis_jsr ) begin
            jsr_ret      <= uaddr;
            jsr_ret[3:0] <= nx_ualo;
            uaddr        <= jsr_ua;
        end
        if( r32jmp ) begin
            case( md[1:0] )
                0: uaddr <= alt ? R32_00_NORD_SEQA : R32_00_SEQA;
                1: uaddr <= alt ? R32_01_NORD_SEQA : R32_01_SEQA;
                3: case(md[7:2])
                    0: uaddr <= alt ? R32_8_NORD_SEQA  : R32_8_SEQA;
                    1: uaddr <= alt ? R32_16_NORD_SEQA : R32_16_SEQA;
                    4: uaddr <= R32_LDAR_SEQA;
                endcase
                default: dec_err <= 1;
            endcase
        end
        if( udmajmp ) begin
            jsr_ret      <= uaddr;
            jsr_ret[3:0] <= nx_ualo;
            case( mode[4:2] )   // DMA mode register must be selected
                0: uaddr <= UDMA00_SEQA;
                1: uaddr <= UDMA01_SEQA;
                2: uaddr <= UDMA10_SEQA;
                3: uaddr <= UDMA11_SEQA;
                4: uaddr <= UDMAFIX_SEQA;
                5: uaddr <= UDMACNT_SEQA;
                default: dec_err <= 1;
            endcase
        end
    end
end

endmodule