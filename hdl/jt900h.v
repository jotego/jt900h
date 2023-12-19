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
    Date: 17-12-2023 */

module jt900h(
    input             rst,
    input             clk,
    input             cen,

    output     [23:1] addr,
    input      [15:0] din,
    output     [15:0] dout,
    output     [ 1:0] we,
    input             busy,

    // interrupt processing
    input             irq,
    output            irq_ack,
    input      [ 2:0] intrq,      // interrupt request

    // set to zero to use the regular interrupt vectors at FFFF00
    // or set to one and pass the interrupt vector lower 8 bits
    input             inta_en,    // the external device sets the vector address
    input      [ 7:0] int_addr,
    // Register dump
    // output            buserror,
    // input      [ 7:0] dmp_addr,     // dump
    // output     [ 7:0] dmp_dout,
    // Debug
    // input      [ 7:0] st_addr,
    // output     [ 7:0] st_dout,
    // output            op_start      // high when OP's 1st byte is decoded
);

wire        bs, ws, qs, cc, mul, shex;
// from ucode
wire        cr_rd, da2ea, div, exff, full, inc_pc,
            mulcheck, mulsel, sex, swpss, wr, zex;
wire [ 1:0] ea_sel;
wire [ 1:0] opnd_sel;
wire [ 2:0] carry_sel;
wire [ 2:0] fetch_sel;
wire [ 2:0] ral_sel;
wire [ 3:0] ld_sel;
wire [ 4:0] alu_sel;
wire [ 4:0] cc_sel;
wire [ 4:0] rmux_sel;
// memory unit
wire [23:0] ea, da, pc;
wire [31:0] mdata;
wire        mem_busy;
// ALU
wire [31:0] op0, op1, op2, rslt;
wire        div_busy;
// "Control Registers" (MCU MMR)
wire [ 7:0] cra;
wire [31:0] crin;
wire [31:0] cr;
wire        cr_we;    // cr_rd goes directly from control unit

// Flags
wire zu,hu,vu,nu,ci,pu;
wire n,h,c,z;

jt900h_ctrl u_ctrl(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    .md         ( md        ),
    .flags      ( flags     ),
    .div_busy   ( div_busy  ),
    .mem_busy   ( mem_busy  ),
    .bs         ( bs        ),
    .ws         ( ws        ),
    .qs         ( qs        ),
    .cc         ( cc        ),       // condition code
    // signals from ucode
    .cr_rd      ( cr_rd     ),
    .da2ea      ( da2ea     ),
    .div        ( div       ),
    .exff       ( exff      ),
    .full       ( full      ),
    .inc_pc     ( inc_pc    ),
    .mulcheck   ( mulcheck  ),
    .mulsel     ( mulsel    ),
    .sex        ( sex       ),
    .swpss      ( swpss     ),
    .wr         ( wr        ),
    .zex        ( zex       ),
    .ea_sel     ( ea_sel    ),
    .opnd_sel   ( opnd_sel  ),
    .carry_sel  ( carry_sel ),
    .fetch_sel  ( fetch_sel ),
    .ral_sel    ( ral_sel   ),
    .ld_sel     ( ld_sel    ),
    .alu_sel    ( alu_sel   ),
    .cc_sel     ( cc_sel    ),
    .rmux_sel   ( rmux_sel  )
);

jt900h_regs u_regs(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    // memory unit
    .ea         ( ea        ),
    .din        ( mdata     ),
    // ALU
    .rslt       ( rslt      ),
    .zi         ( zu        ),
    .hi         ( hu        ),
    .vi         ( vu        ),
    .ni         ( nu        ),
    .ci         ( cu        ),
    .pi         ( pu        ),
    .n          ( n         ),
    .h          ( h         ),
    .c          ( c         ),
    .z          ( z         ),
    // control (from module logic)
    .cc         ( cc        ),
    // control (from ucode)
    .bs         ( bs        ),
    .exff       ( exff      ),
    .full       ( full      ),
    .mul        ( mul       ),
    .mulcheck   ( mulcheck  ),
    .qs         ( qs        ),
    .sex        ( sex       ),
    .shex       ( shex      ),
    .ws         ( ws        ),
    .zex        ( zex       ),
    .opnd_sel   ( opnd_sel  ),
    .fetch_sel  ( fetch_sel ),
    .ral_sel    ( ral_sel   ),
    .ld_sel     ( ld_sel    ),
    .cc_sel     ( cc_sel    ),
    .rmux_sel   ( rmux_sel  ),
    // "Control Registers" (MCU MMR)
    .cra        ( cra       ),
    .crin       ( crin      ),
    .cr         ( cr        ),
    .cr_we      ( cr_we     ),    // cr_rd goes directly from control unit
    // register outputs
    .pc         ( pc        ),
    .da         ( da        ),  // direct memory address from OP, like #8 in LD<W> (#8),#
    .op0        ( op0       ),
    .op1        ( op1       ),
    .op2        ( op2       )
);

jt900h_alu u_alu(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),


    .op0        ( op0       ),
    .op1        ( op1       ),
    .op2        ( op2       ),
    .bs         ( bs        ),
    .ws         ( ws        ),

    // control
    .div        ( div       ),
    .div_busy   ( div_busy  ),
    .alu_sel    ( alu_sel   ),
    .carry_sel  ( carry_sel ),

    // input flags
    .nin        ( n         ),
    .hin        ( h         ),
    .cin        ( c         ),
    .zin        ( z         ),
    // output flags
    .z          ( zu        ),
    .h          ( hu        ),
    .v          ( vu        ),
    .n          ( nu        ),
    .c          ( cu        ),
    .p          ( pu        ),
    .rslt       ( rslt      )
);

endmodule