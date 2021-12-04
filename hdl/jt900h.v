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

    Author: Jose Tejada Gomez. https://patreon.com/topapate
    Version: 1.0
    Date: 29-11-2021 */

module jt900h(
    input             rst,
    input             clk,
    input             cen,

    output     [23:0] ram_addr,
    input      [15:0] ram_dout
);

wire [ 1:0] rfp;          // register file pointer
wire [31:0] src_out, dst_out;

// Indexed memory addresser
wire [ 7:0] idx_rdreg_sel;
wire [ 1:0] reg_step;
wire        reg_inc;
wire        reg_dec;

wire        idx_en;
wire        idx_ok;

// Register bank
wire [31:0] pc;
// offset register
wire [ 7:0] idx_rdreg_aux;
wire [15:0] op;
wire [ 1:0] idx_fetch, ctl_fetch;
wire        addr_ok;
wire [23:0] idx_addr;

wire [ 2:0] regs_we;
wire [ 7:0] regs_dst;

// ALU control
wire [31:0] alu_imm;
wire [ 5:0] alu_op;
wire        alu_smux;
wire        alu_wait;

// Memory controller
wire        ldram_en;
wire        cur_op;
wire [31:0] buf_dout;
wire        buf_rdy;

jt900h_regs u_regs(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .rfp            ( rfp               ),          // register file pointer
    .mem_dout       ( buf_dout          ),
    // From indexed memory addresser
    .idx_rdreg_sel  ( idx_rdreg_sel     ),
    .reg_step       ( reg_step          ),
    .reg_inc        ( reg_inc           ),
    .reg_dec        ( reg_dec           ),
    // offset register
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .src_out        ( src_out           ),

    // destination register
    .dst            ( regs_dst          ),
    .we             ( regs_we           ),
    .dst_out        ( dst_out           )
);

jt900h_idxaddr u_idxaddr(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .idx_en         ( idx_en            ),
    .op             ( buf_dout[15:0]    ),
    .fetched        ( idx_fetch         ),
    // To register bank
    // index register
    .idx_rdreg_sel  ( idx_rdreg_sel     ),
    .reg_step       ( reg_step          ),
    .reg_inc        ( reg_inc           ),
    .reg_dec        ( reg_dec           ),
    .idx_rdreg      ( src_out           ),
    // offset register
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .idx_rdaux      ( dst_out[15:0]     ),

    .addr_ok        ( addr_ok           ),
    .idx_addr       ( idx_addr          )
);

jt900h_ctrl u_ctrl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .fetched        ( ctl_fetch         ),

    .ldram_en       ( ldram_en          ),
    .idx_en         ( idx_en            ),
    .idx_ok         ( idx_ok            ),

    .alu_imm        ( alu_imm           ),
    .alu_op         ( alu_op            ),
    .alu_smux       ( alu_smux          ),
    .alu_wait       ( alu_wait          ),

    .op             ( buf_dout          ),
    .op_ok          ( buf_rdy           ),

    .regs_we        ( regs_we           ),
    .regs_dst       ( regs_dst          )
);

jt900h_ramctl u_ramctl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    //input      [ 2:0] regs_we,
    .ldram_en       ( ldram_en          ),
    .pc             ( pc[23:0]          ),
    .idx_addr       ( idx_addr          ),

    .ram_addr       ( ram_addr          ),
    .ram_dout       ( ram_dout          ),
    .dout           ( buf_dout          ),
    .ram_rdy        ( buf_rdy           )
);

jt900h_pc u_pc(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .idx_en         ( idx_en            ),
    .idx_fetched    ( idx_fetch         ),
    .ctl_fetched    ( ctl_fetch         ),

    .pc             ( pc                )
);

endmodule 