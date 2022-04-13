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
    input      [15:0] ram_dout,
    output     [15:0] ram_din,
    output     [ 1:0] ram_we,
    // Register dump
    input      [7:0] dmp_addr,
    output     [7:0] dmp_din
);

wire [15:0] sr;

// Register bank
wire [ 1:0] rfp;          // register file pointer, rfp[2] always zero
wire        inc_rfp, dec_rfp;
wire [31:0] src_out, dst_out, aux_out, acc;
wire        bc_unity, dec_bc,
            ld_high;

// Indexed memory addresser
wire [ 7:0] idx_rdreg_sel;
wire [ 1:0] reg_step;
wire        reg_inc, reg_dec,
            dec_xde, dec_xix,
            inc_xde, inc_xix;

wire        idx_en, idx_last;
wire        idx_ok, idx_wr, ldd_write;
wire [ 1:0] ram_dsel;

// PC control
wire [31:0] pc;
wire        pc_we, pc_rel;
// offset register
wire [ 7:0] idx_rdreg_aux;
wire [15:0] op, inc_xsp, dec_xsp;
wire [ 2:0] ctl_fetch, idx_fetch;
wire [23:0] idx_addr;
wire        rfp_we;

wire [ 2:0] regs_we, wr_len;
wire [ 7:0] regs_src, regs_dst;
wire [31:0] data_latch;

// ALU control
wire [31:0] alu_imm, alu_dout;
wire [ 6:0] alu_op;
wire [ 7:0] flags;
wire [ 2:0] alu_we;
wire        alu_smux;
wire        alu_wait, alu_busy;
wire        flag_we, djnz, flag_only, nx_v, nx_z;

// Memory controller
wire        ldram_en;
wire        cur_op;
wire [31:0] buf_dout, xsp;
wire        buf_rdy;
wire        sel_xsp, sel_op8, sel_op16;

jt900h_ctrl u_ctrl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .rfp            ( rfp               ),
    .inc_rfp        ( inc_rfp           ),
    .dec_rfp        ( dec_rfp           ),
    .rfp_we         ( rfp_we            ),
    .inc_xsp        ( inc_xsp           ),
    .dec_xsp        ( dec_xsp           ),
    .sel_xsp        ( sel_xsp           ),
    .sel_op8        ( sel_op8           ),
    .sel_op16       ( sel_op16          ),

    .dec_bc         ( dec_bc            ),

    .fetched        ( ctl_fetch         ),
    .pc_we          ( pc_we             ),
    .pc_rel         ( pc_rel            ),

    .ram_ren        ( ldram_en          ),
    .ram_wen        ( idx_wr            ),
    .idx_en         ( idx_en            ),
    .idx_last       ( idx_last          ),
    .idx_ok         ( idx_ok            ),
    .wr_len         ( wr_len            ),
    .idx_addr       ( idx_addr          ),
    // LDD
    .dec_xde        ( dec_xde           ),
    .dec_xix        ( dec_xix           ),
    .inc_xde        ( inc_xde           ),
    .inc_xix        ( inc_xix           ),
    .ldd_write      ( ldd_write         ),

    .ld_high        ( ld_high           ),

    .ram_dsel       ( ram_dsel          ),
    .data_latch     ( data_latch        ),

    .alu_imm        ( alu_imm           ),
    .alu_op         ( alu_op            ),
    .alu_smux       ( alu_smux          ),
    .alu_wait       ( alu_wait          ),
    .alu_busy       ( alu_busy          ),
    .flags          ( flags             ),
    .nx_v           ( nx_v              ),
    .nx_z           ( nx_z              ),
    .sr             ( sr                ),
    .flag_we        ( flag_we           ),
    .djnz           ( djnz              ),

    .op             ( buf_dout          ),
    .op_ok          ( buf_rdy           ),

    .regs_we        ( regs_we           ),
    .regs_dst       ( regs_dst          ),
    .regs_src       ( regs_src          )
);

jt900h_regs u_regs(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .sr             ( sr                ),
    .rfp            ( rfp               ),          // register file pointer
    .inc_rfp        ( inc_rfp           ),
    .dec_rfp        ( dec_rfp           ),
    .rfp_we         ( rfp_we            ),
    .imm            ( alu_imm[9:8]      ),  // used for LDF only

    // BC
    .bc_unity       ( bc_unity          ),
    .dec_bc         ( dec_bc            ),

    // Stack
    .xsp            ( xsp               ),
    .inc_xsp        ( inc_xsp           ),
    .dec_xsp        ( dec_xsp           ),

    .alu_dout       ( alu_dout          ),
    .ram_dout       ( data_latch        ),
    // From indexed memory addresser
    .idx_rdreg_sel  ( idx_rdreg_sel     ),
    .data_sel       ( ram_dsel[0]       ),
    // LDD
    .dec_xde        ( dec_xde           ),
    .dec_xix        ( dec_xix           ),
    .inc_xde        ( inc_xde           ),
    .inc_xix        ( inc_xix           ),
    .reg_step       ( reg_step          ),
    .reg_inc        ( reg_inc           ),
    .reg_dec        ( reg_dec           ),
    // Accumulator
    .acc            ( acc               ),
    .ld_high        ( ld_high           ),
    // offset register
    .idx_en         ( idx_en            ),
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .src_out        ( src_out           ),
    .aux_out        ( aux_out           ),

    // source register
    .src            ( regs_src          ),
    // destination register
    .dst            ( regs_dst          ),
    .ram_we         ( regs_we           ),
    .alu_we         ( alu_we            ),
    .flag_only      ( flag_only         ), // alu_we ignored if flag_we
    .dst_out        ( dst_out           ),
    // Register dump
    .dmp_addr       ( dmp_addr          ),
    .dmp_din        ( dmp_din           )
);

jt900h_idxaddr u_idxaddr(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .idx_en         ( idx_en            ),
    .use_last       ( idx_last          ),
    .op             ( buf_dout          ),
    .fetched        ( idx_fetch         ),
    // To register bank
    // index register
    .idx_rdreg_sel  ( idx_rdreg_sel     ),
    .reg_step       ( reg_step          ),
    .reg_inc        ( reg_inc           ),
    .reg_dec        ( reg_dec           ),
    .idx_rdreg      ( src_out           ),
    .idx_auxreg     ( aux_out           ),
    .ldd_write      ( ldd_write         ),
    // offset register
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .idx_rdaux      ( dst_out[15:0]     ),

    .idx_ok         ( idx_ok            ),
    .idx_addr       ( idx_addr          )
);

jt900h_alu u_alu(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),
    .acc            ( acc               ),
    .op0            ( dst_out           ),
    .op1            ( src_out           ),
    .imm            ( alu_imm           ),
    .sel_imm        ( alu_smux          ),
    .busy           ( alu_busy          ),
    .flag_we        ( flag_we           ),
    .w              ( regs_we           ),      // operation width
    .alu_we         ( alu_we            ),      // delayed version of regs_we
    .flag_only      ( flag_only         ),
    .sel            ( alu_op            ),      // operation selection
    .bc_unity       ( bc_unity          ),
    .flags          ( flags             ),
    .nx_v           ( nx_v              ),
    .nx_z           ( nx_z              ),
    .djnz           ( djnz              ),
    .dout           ( alu_dout          )
);

jt900h_ramctl u_ramctl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .pc             ( pc[23:0]          ),
    .xsp            ( xsp[23:0]         ),
    .sr             ( sr                ),
    .op16           ( buf_dout[23:8]    ),
    .sel_xsp        ( sel_xsp           ),
    .sel_op16       ( sel_op16          ),
    .sel_op8        ( sel_op8           ),
    .data_sel       ( ram_dsel          ),

    .ldram_en       ( ldram_en          ),
    .idx_addr       ( idx_addr          ),
    .alu_dout       ( alu_dout          ),
    .idx_wr         ( idx_wr            ),
    .len            ( wr_len            ),
    // RAM interface
    .ram_addr       ( ram_addr          ),
    .ram_dout       ( ram_dout          ),
    .ram_din        ( ram_din           ),
    .ram_we         ( ram_we            ),

    .dout           ( buf_dout          ),
    .ram_rdy        ( buf_rdy           )
);

jt900h_pc u_pc(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .op_ok          ( buf_rdy           ),
    .idx_en         ( idx_en            ),
    .idx_fetched    ( idx_fetch         ),
    .ctl_fetched    ( ctl_fetch         ),

    .imm            ( alu_imm           ),
    .we             ( pc_we             ),
    .rel            ( pc_rel            ),

    .pc             ( pc                )
);

endmodule 