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
    output            rd,
    input             busy,

    // interrupt processing
    input             irq,
    output            irq_ack,
    input      [ 2:0] int_lvl,      // interrupt level
    input      [ 7:0] int_addr,     // the external device sets the vector address except for SWI
    // Register dump
    output            dec_err,
    input      [ 7:0] dmp_addr,     // dump
    output     [ 7:0] dmp_dout
    // Debug
    // input      [ 7:0] st_addr,
    // output     [ 7:0] st_dout,
    // output            op_start      // high when OP's 1st byte is decoded
);

wire        bs, ws, qs, cc, mul, shex;
// Register unit
wire [31:0] md, xsp;
wire [ 7:0] flags;
wire        n,h,c,z;
wire [ 2:0] riff;
// from ucode
wire        cr_rd, da2ea, div, exff, alt, inc_pc,
            mulcheck, sex, wr, zex;
wire [ 1:0] ea_sel;
wire [ 1:0] opnd_sel;
wire [ 2:0] cx_sel;
wire [ 1:0] fetch_sel;
wire [ 2:0] ral_sel;
wire [ 3:0] ld_sel;
wire [ 4:0] alu_sel;
wire [ 4:0] cc_sel;
wire [ 3:0] rmux_sel;
// memory unit
wire [23:0] ea, da, pc;
wire [31:0] mdata;
wire        mem_busy, nc;
// ALU
wire [31:0] op0, op1, op2, rslt;
wire        div_busy;
wire        zu,hu,vu,nu,cu,pu;
// "Control Registers" (MCU MMR)
wire [ 7:0] cra;
wire [31:0] crin;
wire [31:0] cr;
wire        cr_we;    // cr_rd goes directly from control unit

// To do
assign cr = 0;

jt900h_ctrl u_ctrl(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),
    .md         ( md[7:0]   ),
    .flags      ( flags     ),
    .zu         ( zu        ),
    .div_busy   ( div_busy  ),
    .mem_busy   ( mem_busy  ),
    .bs         ( bs        ),
    .ws         ( ws        ),
    .qs         ( qs        ),
    .cc         ( cc        ),       // condition code
    .dec_err    ( dec_err   ),
    // interrupt controller
    .irq        ( irq       ),
    .irq_ack    ( irq_ack   ),
    .int_lvl    ( int_lvl   ),
    .riff       ( riff      ),
    // signals from ucode
    .cr_rd      ( cr_rd     ),
    .da2ea      ( da2ea     ),
    .div        ( div       ),
    .exff       ( exff      ),
    .alt        ( alt       ),
    .inc_pc     ( inc_pc    ),
    .mulcheck   ( mulcheck  ),
    .mulsel     ( mul       ),
    .sex        ( sex       ),
    .wr         ( wr        ),
    .zex        ( zex       ),
    .ea_sel     ( ea_sel    ),
    .opnd_sel   ( opnd_sel  ),
    .cx_sel     ( cx_sel    ),
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
    .xsp        ( xsp       ),
    .md         ( md        ),
    // ALU
    .rslt       ( rslt      ),
    .zi         ( zu        ),
    .hi         ( hu        ),
    .vi         ( vu        ),
    .ni         ( nu        ),
    .ci         ( cu        ),
    .pi         ( pu        ),
    .no         ( n         ),
    .ho         ( h         ),
    .co         ( c         ),
    .zo         ( z         ),
    // control (from module logic)
    .cc         ( cc        ),
    .flags      ( flags     ),
    .riff       ( riff      ),
    .int_lvl    ( int_lvl   ),
    .int_addr   ( int_addr  ),
    // control (from ucode)
    .bs         ( bs        ),
    .exff       ( exff      ),
    .alt        ( alt       ),
    .inc_pc     ( inc_pc    ),
    .mul        ( mul       ),
    .mulcheck   ( mulcheck  ),
    .qs         ( qs        ),
    .sex        ( sex       ),
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
    .op2        ( op2       ),
    // Register dump
    .dmp_addr   ( dmp_addr  ),
    .dmp_dout   ( dmp_dout  )
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
    .qs         ( qs        ),

    // control
    .alt        ( alt       ),
    .div        ( div       ),
    .div_busy   ( div_busy  ),
    .alu_sel    ( alu_sel   ),
    .cx_sel     ( cx_sel    ),

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

jt900h_mem u_mem(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),

    .bus_addr   ( {addr,nc} ),
    .bus_dout   ( din       ),
    .bus_din    ( dout      ),
    .bus_we     ( we        ),
    .bus_rd     ( rd        ),
    .bus_busy   ( busy      ),
    // from ucode
    .fetch_sel  ( fetch_sel ),
    .ea_sel     ( ea_sel    ),
    .da2ea      ( da2ea     ),
    .wr         ( wr        ),
    .inc_pc     ( inc_pc    ),
    // from control unit
    .bs         ( bs        ),
    .ws         ( ws        ),
    .qs         ( qs        ),
    // from register unit
    .da         ( da        ),
    .pc         ( pc        ),
    .xsp        ( xsp       ),
    .md         ( md        ),
    // outputs
    .ea         ( ea        ),
    .mdata      ( mdata     ),
    .busy       ( mem_busy  )
);

endmodule