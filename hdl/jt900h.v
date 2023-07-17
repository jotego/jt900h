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
    Date: 29-11-2021 */

module jt900h(
    input             rst,
    input             clk,
    input             cen,

    output     [23:0] addr,
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
    output            buserror,
    input      [ 7:0] dmp_addr,     // dump
    output     [ 7:0] dmp_dout
);

parameter PC_RSTVAL=0; // Use FF1800 for NeoGeo Pocket

wire [15:0] sr;

// Register bank
wire [ 1:0] rfp;          // register file pointer, rfp[2] always zero
wire        inc_rfp, dec_rfp;
wire [31:0] src_out, dst_out, aux_out, acc, idx_out,
            xde, xhl;
wire        bc_unity, dec_bc, dec_xhl,
            ld_high,  ex_we;

// Indexed memory addresser
wire [ 7:0] idx_rdreg_sel;
wire [ 1:0] reg_step;
wire        reg_inc, reg_dec,
            dec_xde, dec_xix,
            inc_xde, inc_xix;

wire        idx_en, idx_last, ldar;
wire        idx_ok, idx_wr, ldd_write;
wire [ 1:0] ram_dsel;

// PC control
wire [31:0] pc;
wire        pc_we, pc_rel;
// offset register
wire [ 7:0] idx_rdreg_aux;
wire [15:0] op,inc_xsp, dec_xsp;
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
wire        alu_smux, alu_imux;
wire        alu_wait, alu_busy;
wire        flag_we, djnz, flag_only, nx_v, nx_z;

// Memory controller
wire        ldram_en;
wire        cur_op;
wire [31:0] buf_dout, xsp;
wire        buf_rdy, rda_imm, wra_imm, rda_irq, rda_swi;
wire        sel_xsp, sel_op8, sel_op16,
            sel_xde, sel_xhl;

// DMA
wire [31:0] dma_reg;
wire [ 2:0] dma_regwe;
wire [ 5:0] dma_regsel;
wire        int_inc, int_dec, dma_src;

jt900h_ctrl u_ctrl(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),

    .buserror       ( buserror          ),
    // interrupt processing
    .intlvl         ( intrq             ),
    .irq            ( irq               ),
    .irq_ack        ( irq_ack           ),
    .rda_irq        ( rda_irq           ),
    .rda_swi        ( rda_swi           ),

    .rfp            ( rfp               ),
    .inc_rfp        ( inc_rfp           ),
    .dec_rfp        ( dec_rfp           ),
    .rfp_we         ( rfp_we            ),
    .inc_xsp        ( inc_xsp           ),
    .dec_xsp        ( dec_xsp           ),
    .sel_xsp        ( sel_xsp           ),
    .sel_op8        ( sel_op8           ),
    .sel_op16       ( sel_op16          ),
    .sel_xde        ( sel_xde           ),
    .sel_xhl        ( sel_xhl           ),

    .dec_bc         ( dec_bc            ),
    .dec_xhl        ( dec_xhl           ),

    .fetched        ( ctl_fetch         ),
    .pc_we          ( pc_we             ),
    .pc_rel         ( pc_rel            ),

    .ram_ren        ( ldram_en          ),
    .ram_wen        ( idx_wr            ),
    .rda_imm        ( rda_imm           ),
    .wra_imm        ( wra_imm           ),
    .idx_en         ( idx_en            ),
    .idx_last       ( idx_last          ),
    .idx_ok         ( idx_ok            ),
    .ldar           ( ldar              ),
    .wr_len         ( wr_len            ),
    .idx_addr       ( idx_addr          ),
    // LDD
    .dec_xde        ( dec_xde           ),
    .dec_xix        ( dec_xix           ),
    .inc_xde        ( inc_xde           ),
    .inc_xix        ( inc_xix           ),
    .ldd_write      ( ldd_write         ),
    // DMA
    .dma_we         ( dma_regwe         ),
    .dma_rsel       ( dma_regsel        ),
    .dma_src        ( dma_src           ),
    .int_inc        ( int_inc           ),
    .int_dec        ( int_dec           ),

    .ld_high        ( ld_high           ),

    .ram_dsel       ( ram_dsel          ),
    .data_latch     ( data_latch        ),

    .alu_imm        ( alu_imm           ),
    .alu_op         ( alu_op            ),
    .alu_smux       ( alu_smux          ),
    .alu_imux       ( alu_imux          ),
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
    .regs_src       ( regs_src          ),
    .ex_we          ( ex_we             )
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
    .ex_we          ( ex_we             ),

    // BC
    .bc_unity       ( bc_unity          ),
    .dec_bc         ( dec_bc            ),

    // Stack
    .xsp            ( xsp               ),
    .inc_xsp        ( inc_xsp           ),
    .dec_xsp        ( dec_xsp           ),

    .alu_dout       ( alu_dout          ),
    .ram_dout       ( data_latch        ),

    // MULA support
    .xde            ( xde               ),
    .xhl            ( xhl               ),
    .dec_xhl        ( dec_xhl           ),
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
    // DMA
    .dma_reg        ( dma_reg           ),
    .dma_sel        ( dma_src           ),
    // Accumulator
    .acc            ( acc               ),
    .ld_high        ( ld_high           ),
    // offset register
    .idx_en         ( idx_en            ),
    .idx_rdreg_aux  ( idx_rdreg_aux     ),
    .src_out        ( src_out           ),
    .aux_out        ( aux_out           ),
    .idx_out        ( idx_out           ),

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
    .dmp_dout       ( dmp_dout          )
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
    .idx_rdaux      ( idx_out[15:0]     ),

    .idx_ok         ( idx_ok            ),
    .ldar           ( ldar              ),
    .idx_addr       ( idx_addr          )
);

jt900h_alu u_alu(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),
    .acc            ( acc               ),
    .op0            ( dst_out           ),
    .op1            ( src_out           ),
    .pc             ( pc                ),
    .imm            ( alu_imm           ),
    .sel_imm        ( alu_smux          ),
    .sel_dual       ( alu_imux          ),
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
    .pc_bad         ( pc_rel | pc_we    ),
    .xsp            ( xsp[23:0]         ),
    .sr             ( sr                ),
    .op16           ( buf_dout[23:8]    ),
    .sel_xsp        ( sel_xsp           ),
    .sel_op16       ( sel_op16          ),
    .sel_op8        ( sel_op8           ),
    .data_sel       ( ram_dsel          ),


    // Support for the external device setting the interrupt address
    .int_addr       ( int_addr          ),
    .inta_en        ( inta_en           ),
    .rda_swi        ( rda_swi           ),
    .irq_ack        ( irq_ack           ),
    // MULA support
    .xde            ( xde[23:0]         ),
    .xhl            ( xhl[23:0]         ),
    .sel_xde        ( sel_xde           ),
    .sel_xhl        ( sel_xhl           ),

    .ldram_en       ( ldram_en          ),
    .idx_addr       ( idx_addr          ),
    .alu_dout       ( alu_dout          ),
    .idx_wr         ( idx_wr            ),
    .len            ( wr_len            ),

    // Immediate value
    .imm            ( alu_imm           ),
    .sel_imm        ( alu_smux          ),
    .rda_imm        ( rda_imm           ),
    .wra_imm        ( wra_imm           ),
    .rda_irq        ( rda_irq           ),

    // EX support
    .src_out        ( src_out           ),
    .regs_we        ( regs_we[1:0]      ),

    // bus interface
    .ram_addr       ( addr              ),
    .ram_dout       ( din               ),
    .ram_din        ( dout              ),
    .ram_we         ( we                ),
    .ram_busy       ( busy              ),

    .dout           ( buf_dout          ),
    .ram_rdy        ( buf_rdy           )
);

jt900h_udma u_dma(
    .rst            ( rst               ),
    .clk            ( clk               ),
    .cen            ( cen               ),
    // Register access
    .regin          ( src_out           ),
    .regsel         ( dma_regsel        ),
    .regwe          ( dma_regwe         ),
    .int_inc        ( int_inc           ),
    .int_dec        ( int_dec           ),
    .regout         ( dma_reg           )
);

jt900h_pc #(.PC_RSTVAL(PC_RSTVAL)) u_pc(
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