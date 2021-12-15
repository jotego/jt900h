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

wire [ 1:0] rfp;          // register file pointer, rfp[2] always zero
wire        inc_rfp, dec_rfp;
wire [31:0] src_out, dst_out;

// Indexed memory addresser
wire [ 7:0] idx_rdreg_sel;
wire [ 1:0] reg_step;
wire        reg_inc;
wire        reg_dec;

wire        idx_en;
wire        idx_ok, idx_wr, data_sel;

// PC control
wire        pc_we;

// Register bank
wire [31:0] pc;
// offset register
wire [ 7:0] idx_rdreg_aux;
wire [15:0] op;
wire [ 1:0] ctl_fetch;
wire [ 2:0] idx_fetch;
wire [23:0] idx_addr;
wire        rfp_we;

wire [ 2:0] regs_we, idx_len;
wire [ 7:0] regs_src, regs_dst;
wire [31:0] data_latch;

// ALU control
wire [31:0] alu_imm, alu_dout;
wire [ 5:0] alu_op;
wire [ 7:0] flags;
wire [ 2:0] alu_we;
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
    .inc_rfp        ( inc_rfp           ),
    .dec_rfp        ( dec_rfp           ),
    .rfp_we         ( rfp_we            ),
    .imm            ( alu_imm[1:0]      ),  // used for LDF only


    .alu_dout       ( alu_dout          ),
    .ram_dout       ( data_latch        ),
    // From indexed memory addresser
    .idx_rdreg_sel  ( idx_rdreg_sel     ),
    .data_sel       ( data_sel          ),
    .reg_step       ( reg_step          ),
    .reg_inc        ( reg_inc           ),
    .reg_dec        ( reg_dec           ),
    // offset register
    .idx_en         ( idx_en            ),
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .src_out        ( src_out           ),

    // source register
    .src            ( regs_src          ),
    // destination register
    .dst            ( regs_dst          ),
    .ram_we         ( regs_we           ),
    .alu_we         ( alu_we            ),
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
    .op             ( buf_dout          ),
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

    .idx_ok         ( idx_ok            ),
    .idx_addr       ( idx_addr          )
);

jt900h_alu u_alu(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),
    .op0            ( dst_out           ),
    .op1            ( src_out           ),
    .imm            ( alu_imm           ),
    .sel_imm        ( alu_smux          ),
    .w              ( regs_we           ),      // operation width
    .alu_we         ( alu_we            ),      // delayed version of regs_we
    .sel            ( alu_op            ),      // operation selection
    .flags          ( flags             ),
    .dout           ( alu_dout          )
);

jt900h_ctrl u_ctrl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .inc_rfp        ( inc_rfp           ),
    .dec_rfp        ( dec_rfp           ),
    .rfp_we         ( rfp_we            ),

    .fetched        ( ctl_fetch         ),
    .pc_we          ( pc_we             ),

    .ldram_en       ( ldram_en          ),
    .stram_en       ( idx_wr            ),
    .idx_en         ( idx_en            ),
    .idx_ok         ( idx_ok            ),
    .idx_len        ( idx_len           ),
    .idx_addr       ( idx_addr          ),
    .data_sel       ( data_sel          ),
    .data_latch     ( data_latch        ),

    .alu_imm        ( alu_imm           ),
    .alu_op         ( alu_op            ),
    .alu_smux       ( alu_smux          ),
    .alu_wait       ( alu_wait          ),
    .flags          ( flags             ),

    .op             ( buf_dout          ),
    .op_ok          ( buf_rdy           ),

    .regs_we        ( regs_we           ),
    .regs_dst       ( regs_dst          ),
    .regs_src       ( regs_src          )
);

jt900h_ramctl u_ramctl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .pc             ( pc[23:0]          ),

    .ldram_en       ( ldram_en          ),
    .idx_addr       ( idx_addr          ),
    .reg_dout       ( src_out           ),
    .idx_wr         ( idx_wr            ),
    .len            ( idx_len           ),
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

    .imm            ( alu_imm[23:0]     ),
    .we             ( pc_we             ),

    .pc             ( pc                )
);

endmodule 