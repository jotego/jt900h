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
    Date: 30-11-2021 */

module jt900h_ctrl(
    input             rst,
    input             clk,
    input             cen,

    input             irq,
    output            irq_ack,
    input      [ 2:0] intlvl,     // interrupt level
                                  // 0   ignored
                                  // 1-6 maskable
                                  // 7   NMI
    // PC
    output reg [ 2:0] fetched,    // number of bytes consumed
    output reg        pc_we,      // absolute value write
    output reg        pc_rel,     // relative value write

    output reg        ram_ren,    // read enable
    output reg        ram_wen,    // write enable
    output reg        buserror,
    output reg        idx_en,
    output reg        idx_last,
    input             idx_ok,
    input             ldar,
    input      [23:0] idx_addr,
    output reg [ 2:0] wr_len,
    output reg [ 1:0] ram_dsel,
    output reg        ldd_write,
    output reg        rda_imm,
    output reg        rda_irq,
    output            wra_imm,

    output reg        dec_bc,
    output reg        ld_high,  // acc will load the ALU high output byte

    // XSP
    output reg        sel_xsp,
    output reg        sel_op16,
    output reg        sel_op8,
    output reg [15:0] inc_xsp,
    output reg [15:0] dec_xsp,

    output reg        dec_xde,
    output reg        dec_xix,
    output reg        inc_xde,
    output reg        inc_xix,
    output reg [31:0] data_latch,

    output reg        sel_xde,
    output reg        sel_xhl,
    output reg        dec_xhl,
    // RFP
    input      [ 1:0] rfp,
    output reg        inc_rfp,
    output reg        dec_rfp,
    output reg        rfp_we,

    // ALU control
    output reg [31:0] alu_imm,
    output reg [ 6:0] alu_op,
    output reg        alu_smux,
    output reg        alu_imux,
    output reg        alu_wait,
    input      [ 7:0] flags,
    output reg        flag_we, // instructions that only affect the flags
    input             djnz,
    input             alu_busy,
    input             nx_v,
    input             nx_z,

    input      [31:0] op,
    input             op_ok,

    output     [15:0] sr,       // status register
    output reg [ 2:0] regs_we,
    output reg [ 7:0] regs_dst,
    output reg [ 7:0] regs_src,
    output reg        ex_we
);

localparam [4:0] FETCH    = 5'd0,
                 IDX      = 5'd1,
                 LD_RAM   = 5'd2,
                 EXEC     = 5'd3,
                 FILL_IMM = 5'd4,
                 ST_RAM   = 5'd5,
                 DUMMY    = 5'd6,
                 DJNZ     = 5'd7,
                 PUSH_PC  = 5'd8,
                 PUSH_R   = 5'd9,
                 PUSH_SR  = 5'd10,
                 WAIT_ALU = 5'd11,
                 POP_PC   = 5'd12,
                 CPDR     = 5'd13,
                 LINK     = 5'd14,
                 UNLK     = 5'd15,
                 LD_XHL   = 5'd16,
                 MULA     = 5'd17,
                 IRQ      = 5'd18,
                 IRQ_JP   = 5'd19,
                 PUSH_PC2 = 5'd20,
                 ILLEGAL  = 5'd31;
// Flag bits

localparam  FS=7,
            FZ=6,
            FH=4,
            FV=2,
            FN=1,
            FC=0;

`include "jt900h.inc"

reg  [4:0] op_phase, nx_phase;
//reg        illegal;
reg  [7:0] last_op;
reg  [7:0] nx_src, nx_dst;
reg  [2:0] nx_regs_we, nx_wr_len,
           nx_keep_we, keep_we;
reg        nx_alu_smux, nx_alu_imux, nx_alu_wait,
           nx_ram_ren, nx_ram_wen,
           nx_idx_en,
           // LDD/LDI:
           nx_dec_xde, nx_dec_xix,
           nx_inc_xde, nx_inc_xix,
           nx_keep_dec_xde, keep_dec_xde,
           nx_keep_dec_xix, keep_dec_xix,
           nx_keep_inc_xde, keep_inc_xde,
           nx_keep_inc_xix, keep_inc_xix,
           nx_ld_high,
           nx_ex_we, nx_keep_ex, keep_ex,
           keep_smux, nx_keep_smux,
           nx_imm2idx, imm2idx, nx_rda_irq,
           nx_buserror, nx_halted, halted;
reg  [1:0] nx_ram_dsel;
reg [31:0] nx_alu_imm, nx_data_latch;
reg  [6:0] nx_alu_op;
reg        nx_inc_rfp, nx_dec_rfp,
           nx_nodummy_fetch, nodummy_fetch,
           nx_goexec, goxec,
           nx_exec_imm, exec_imm,
           nx_pc_we, nx_pc_rel,
           nx_keep_pc_we, keep_pc_we,
           nx_rfp_we,
           nx_was_load, was_load,
           nx_flag_we,
           nx_sel_xsp, nx_dec_bc,
           nx_idx_last, nx_ldd_write,
           keep_lddwr, nx_keep_lddwr,
           link, nx_link,
           popf, nx_popf, popsr, nx_popsr,
           rep, nx_rep,
           reti, nx_reti,
           nx_selop16, keep_selop16, nx_keep_selop16,
           nx_selop8, nx_rda_imm,
           nx_popw, popw, ld2imm, nx_ld2imm,
           intproc, nx_intproc,
           nx_sel_xde, nx_sel_xhl, nx_dec_xhl;
reg  [2:0] nx_dly_fetch, dly_fetch; // fetch update to be run later
reg [15:0] nx_dec_xsp, nx_keep_dec_xsp, keep_dec_xsp;
reg [15:0] nx_inc_xsp, nx_keep_inc_xsp, keep_inc_xsp;
reg [ 7:0] nx_intnest, intnest;

reg  [1:0] op_zz, nx_op_zz;
reg        ram_wait, nx_ram_wait, latch_op, req_wait;
reg        bad_zz, jp_ok;
wire [3:0] inc_opnd;

// Interrupt masks
reg  [2:0] riff, nx_iff;

assign sr = { 1'b1, riff, 1'b1, 1'b0, rfp, flags };
assign wra_imm = ld2imm & ram_wen;
assign irq_ack = intproc;
assign inc_opnd = op[2:0]==0 ? 4'd8 : {1'd0,op[2:0]};

`ifdef SIMULATION
wire [31:0] op_rev = {op[7:0],op[15:8],op[23:16],op[31:24]};
`endif

function [2:0] expand_zz;
    input [1:0] zz;
    expand_zz = zz==0 ? 3'b001 : zz==1 ? 3'b010 : 3'b100;
endfunction

function [7:0] expand_reg;
    input [2:0] short_reg;
    input [1:0] zz;
    expand_reg = zz==0 ?       {4'he, short_reg[2:1], 1'b0, ~short_reg[0]} :
                short_reg[2] ? {4'hf, short_reg[1:0],2'd0 } :
                               {4'he, short_reg[1:0],2'd0 };
endfunction

always @* begin
    case( op[3:0] ) // conditions
        0: jp_ok = 0;    // false
        1: jp_ok = flags[FS]^flags[FV];               // signed <
        2: jp_ok = flags[FZ] | (flags[FS]^flags[FV]); // signed <=
        3: jp_ok = flags[FZ] | flags[FC];             // <=
        4: jp_ok = flags[FV];  // overflow
        5: jp_ok = flags[FS];  // minux
        6: jp_ok = flags[FZ];  // =
        7: jp_ok = flags[FC];  // carry
        8: jp_ok = 1;          // true
        9: jp_ok = ~(flags[FS]^flags[FV]); // >=
        10: jp_ok = ~(flags[FZ]|(flags[FS]^flags[FV])); // signed >
        11: jp_ok = ~(flags[FZ]|flags[FC]); // >
        12: jp_ok = ~flags[FV];
        13: jp_ok = ~flags[FS];
        14: jp_ok = ~flags[FZ];
        15: jp_ok = ~flags[FC];
    endcase
end

// Memory fetched requests
always @* begin
    fetched          = 0;
    nx_phase         = op_phase;
    nx_idx_en        = idx_en;
    nx_src           = regs_src;
    nx_dst           = regs_dst;
    nx_alu_op        = alu_op;
    nx_alu_imm       = alu_imm;
    nx_alu_smux      = alu_smux;
    nx_keep_smux     = 0;
    nx_alu_imux      = alu_imux;
    nx_alu_wait      = alu_wait;
    nx_ram_ren       = ram_ren;
    nx_ram_wen       = 0;
    nx_op_zz         = op_zz;
    nx_regs_we       = 0;
    nx_keep_we       = keep_we;
    latch_op         = 0;
    req_wait         = 0;
    nx_data_latch    = data_latch;
    nx_inc_rfp       = 0;
    nx_dec_rfp       = 0;
    nx_nodummy_fetch = nodummy_fetch;
    nx_goexec        = goxec;
    nx_exec_imm      = exec_imm;
    nx_pc_we         = op_phase==FETCH ? 1'd0 : pc_we;
    nx_pc_rel        = 0;
    nx_keep_pc_we    = keep_pc_we;
    nx_rfp_we        = 0;
    nx_was_load      = was_load;
    nx_flag_we       = flag_we;
    nx_ex_we         = keep_ex;
    nx_keep_ex       = 0;

    nx_wr_len        = wr_len;
    nx_ram_dsel      = ram_dsel;
    nx_dly_fetch     = dly_fetch;
    nx_inc_xsp       = 0;
    nx_dec_xsp       = 0;
    nx_sel_xsp       = sel_xsp;
    nx_selop16       = sel_op16;
    nx_selop8        = sel_op8;
    nx_keep_selop16  = keep_selop16;
    nx_rda_imm       = rda_imm;
    nx_rda_irq       = rda_irq;
    nx_sel_xde       = sel_xde;
    nx_sel_xhl       = sel_xhl;
    nx_dec_xhl       = 0;

    nx_imm2idx       = imm2idx;
    nx_ld2imm        = ld2imm;
    nx_popw          = popw;

    nx_iff           = riff;
    bad_zz           = op_zz == 2'b11;
    nx_dec_bc        = 0;
    nx_idx_last      = idx_last;
    nx_ld_high       = ld_high;
    nx_link          = 0;
    nx_popf          = popf;
    nx_popsr         = popsr;
    // LDD/LDI
    nx_dec_xde       = 0;
    nx_dec_xix       = 0;
    nx_inc_xde       = 0;
    nx_inc_xix       = 0;
    nx_keep_dec_xde  = keep_dec_xde;
    nx_keep_dec_xix  = keep_dec_xix;
    nx_keep_inc_xde  = keep_inc_xde;
    nx_keep_inc_xix  = keep_inc_xix;

    nx_keep_inc_xsp  = keep_inc_xsp;
    nx_keep_dec_xsp  = keep_dec_xsp;
    nx_ldd_write     = 0;
    nx_rep           = 0;
    nx_keep_lddwr    = keep_lddwr;

    nx_reti          = reti;
    nx_buserror      = buserror;
    nx_halted        = halted;

    // interrupts
    nx_intproc       = intproc;
    nx_intnest       = intnest;

    if(op_ok && !ram_wait) case( op_phase )
        FETCH: if(!pc_we) begin
            `ifdef SIMULATION
            //$display("Fetched %04X_%04X", {op[7:0],op[15:8]},{op[23:16],op[31:24]});
            `endif
            nx_alu_op   = ALU_NOP;
            nx_alu_smux = 0;
            nx_alu_imux = 0;
            nx_alu_wait = 0;
            nx_regs_we  = 0;
            nx_wr_len   = 0;
            nx_ram_dsel = DOUT_ALU;
            nx_keep_we  = 0;
            nx_exec_imm = 0;
            nx_pc_we    = 0;
            nx_keep_pc_we=0;
            nx_was_load = 0;
            nx_goexec   = 0;
            nx_dly_fetch= 0;
            nx_flag_we  = 0;
            nx_sel_xsp  = 0;
            nx_ld_high  = 0;
            nx_popf     = 0;
            nx_popsr    = 0;
            nx_reti     = 0;
            // RAM CTRL
            nx_selop8   = 0;
            nx_selop16  = 0;
            nx_keep_selop16=0;
            nx_imm2idx  = 0;
            nx_popw     = 0;
            nx_rda_imm  = 0;
            nx_sel_xde   = 0;
            nx_sel_xhl   = 0;
            nx_ld2imm    = 0;
            // LDD/LDI
            nx_keep_dec_xde = 0;
            nx_keep_dec_xix = 0;
            nx_keep_inc_xde = 0;
            nx_keep_inc_xix = 0;
            nx_keep_inc_xsp = 0;
            nx_keep_dec_xsp = 0;
            nx_keep_lddwr = 0;
            nx_idx_last  = 0;
            if( irq && intlvl >= riff && intlvl!=0 ) begin
                // Interrupt accepted
                // nx_irqack = 1;
                // nx_intnest = intnest + 16'd1;
                // 1st push SR
                nx_dec_xsp = 4;
                nx_phase   = PUSH_PC;
                // Set up the rest of the process
                nx_intproc = 1;
                nx_alu_imm[7:0] = { 3'd0, intlvl, 2'd0 }; // shares logic with SWI
                fetched   = 0;
                // get out of a possible halted state
                nx_halted = 0;
            end else if(!halted) begin
                casez( op[7:0] )
                    8'b0000_0000: begin // NOP
                        fetched = 1;
                    end
                    8'b0000_0101: begin // HALT
                        fetched   = 1;
                        nx_halted = 1;
                    end
                    8'b10??_????,
                    8'b11??_00??,
                    8'b11??_010?: begin
                        nx_op_zz = op[5:4];
                        if( op[7:0]==8'hb0 && op[15:12]==4'b1111 ) begin // RET cc
                            nx_phase = EXEC;
                            fetched  = 1;
                        end else begin // start indexed addressing
                            latch_op = 1;
                            nx_phase = IDX;
                            nx_idx_en= 1;
                            fetched  = 0; // let the indexation module take control
                        end
                    end
                    8'b1100_1???,
                    8'b1101_1???,
                    8'b1110_1???: begin // two register operand instruction, r part
                        nx_op_zz = op[5:4];
                        nx_dst   = expand_reg(op[2:0], nx_op_zz);
                        nx_src   = nx_dst;
                        nx_phase = EXEC;
                        fetched  = 1;
                    end
                    8'b1111_1???: begin // SWI
                        // 1st push SR
                        nx_dec_xsp = 4;
                        fetched    = 1;
                        nx_wr_len  = 2;
                        nx_phase   = PUSH_PC;
                        // Set up the rest of the process
                        nx_intproc = 1;
                        nx_alu_imm[7:0] = { 3'd0, op[2:0], 2'd0 };
                    end
                    8'b1100_0111,
                    8'b1101_0111,
                    8'b1110_0111: begin // two operand, r with arbitraty register
                        nx_op_zz = op[5:4];
                        nx_dst   = op[15:8];
                        nx_src   = nx_dst;
                        fetched  = 2;
                        nx_phase = EXEC;
                    end
                    8'b0001_0000, // RCF
                    8'b0001_0001, // SCF
                    8'b0001_0011: // ZCF
                    begin
                        nx_flag_we = 1;
                        case( op[1:0] )
                            0: nx_alu_op = ALU_RCF;
                            1: nx_alu_op = ALU_SCF;
                            3: nx_alu_op = ALU_ZCF;
                            default: nx_alu_op = ALU_NOP;
                        endcase
                        fetched    = 1;
                    end
                    8'b0001_0010: begin // CCF
                        nx_flag_we = 1;
                        nx_alu_op  = ALU_CCF;
                        fetched    = 1;
                    end
                    8'b0001_0110: begin // EX F,F'
                        nx_flag_we = 1;
                        nx_alu_op  = ALU_EXFF;
                        fetched    = 1;
                    end
                    8'b0001_0111: begin // LDF - LoaD register File pointer
                        nx_rfp_we  = 1;
                        nx_alu_imm = { 16'd0, op[15:0] };
                        fetched    = 2;
                    end
                    8'b0010_0???,   // byte
                    8'b0011_0???,   // word
                    8'b0100_0???:   // long word
                    begin // LD R,# 0zzz_0RRR, register and immediate value
                        nx_op_zz    = op[6:4]==2 ? 2'd0 : op[6:4]==3 ? 2'd1 : 2'd2;
                        nx_dst      = expand_reg(op[2:0], nx_op_zz);
                        nx_alu_imm  = { 24'd0, op[15:8] };
                        nx_alu_op   = ALU_MOVE;
                        nx_alu_smux = 1;
                        fetched     = 2;
                        if( nx_op_zz!=0 ) begin
                            nx_phase = FILL_IMM;
                            nx_alu_wait = 1;
                            nx_keep_we  = expand_zz( nx_op_zz );
                        end else begin
                            nx_regs_we  = expand_zz( nx_op_zz );
                            nx_phase = FETCH;
                        end
                    end
                    8'b0000_0110: begin // DI/EI num
                        nx_iff  = op[10:8];
                        fetched = 2;
                    end
                    8'b0000_10?1: begin // PUSH<W> #
                        nx_regs_we  = op[1] ? 3'b10 : 3'b1;
                        nx_dec_xsp  = {13'd0,nx_regs_we};
                        nx_wr_len   = nx_regs_we;
                        nx_alu_op   = ALU_MOVE;
                        nx_phase    = PUSH_R;
                        nx_flag_we  = 1;
                        nx_alu_smux = 1;
                        fetched     = op[1] ? 3'd2 : 3'd1;
                        nx_alu_imm[15:0] = op[23:8];
                    end
                    8'b0001_1000,       // PUSH F
                    8'b0000_0010: begin // PUSH SR
                        nx_wr_len  = op[1] ? 3'd2 : 3'd1;
                        nx_dec_xsp = {13'd0,op[1] ? 3'd2 : 3'd1};
                        nx_ram_dsel= DOUT_SR;
                        nx_phase   = PUSH_SR;
                    end
                    8'b0001_1001,  // POP F
                    8'b0000_0111,  // RETI
                    8'b0000_0011: begin // POP SR
                        nx_keep_inc_xsp = op[1] ? 16'd2 : 16'd1;
                        nx_wr_len       = op[1] ? 3'd1 : 3'd2;
                        nx_ram_ren      = 1;
                        nx_sel_xsp      = 1;
                        nx_phase        = LD_RAM;
                        nx_popf         = 1;
                        nx_popsr        = op[1];
                        nx_reti         = op[2];
                        if( nx_reti ) begin
                            nx_intnest = intnest - 1'd1;
                        end
                        fetched         = 0;
                    end
                    8'b0001_0101,       // POP A
                    8'b010?_1???: begin // POP R
                        nx_dst     = op[6] ?
                            expand_reg(op[2:0], op[4] ? 2'b10 : 2'b01 ) :
                            8'he0; // A
                        nx_keep_we = !op[6] ? 3'b001 : op[4] ? 3'b100 : 3'b010;
                        nx_keep_inc_xsp = {13'd0, nx_keep_we};
                        nx_wr_len  = nx_keep_we;
                        nx_ram_ren = 1;
                        nx_sel_xsp = 1;
                        nx_phase   = LD_RAM;
                        fetched = 0;
                    end
                    8'b0001_0100,       // PUSH A
                    8'b001?_1???: begin // PUSH R
                        nx_src     = op[5] ?
                            expand_reg(op[2:0], op[4] ? 2'b10 : 2'b01 ) :
                            8'he0; // A
                        nx_alu_op  = ALU_MOVE;
                        nx_regs_we = !op[5] ? 3'b001 : op[4] ? 3'b100 : 3'b010;
                        nx_dec_xsp = {13'd0,nx_regs_we};
                        nx_wr_len  = nx_regs_we;
                        nx_phase   = PUSH_R;
                        nx_flag_we = 1;
                        fetched = 0;
                    end
                    8'b0001_101?: begin // JP 16/24-bit immediate value
                        fetched       = 2;
                        nx_alu_imm    = { 24'd0, op[15:8] };
                        nx_op_zz      = !op[0] ? 2'd1: 2'd3; // 3 = special case to load 24 bits
                        nx_phase      = FILL_IMM;
                        nx_keep_pc_we = 1;
                    end
                    8'b0000_10?0: begin // LD<W> (#8),#
                        nx_selop8    = 1;
                        nx_dly_fetch = op[1] ? 3'd4 : 3'd3;
                        nx_alu_imm   = {16'd0,op[31:16]};
                        nx_regs_we   = op[1] ? 3'd2 : 3'd1;
                        nx_alu_op    = ALU_MOVE;
                        nx_flag_we   = 1;
                        nx_alu_smux  = 1;
                        nx_phase     = ST_RAM;
                    end
                    8'b0000_1100: begin
                        nx_inc_rfp = 1;
                        fetched    = 1;
                    end
                    8'b0000_1101: begin
                        nx_dec_rfp = 1;
                        fetched    = 1;
                    end
                    8'b0001_110?: begin // CALL
                        fetched = op[0] ? 3'd4 : 3'd3;
                        latch_op = 1;
                        nx_dec_xsp = 4;
                        nx_alu_imm = op[0] ? { 8'd0, op[31:8] } : { 16'd0, op[23:8] };
                        nx_phase = PUSH_PC;
                    end
                    8'b0001_1110: begin // CALLR
                        nx_alu_imm  = { {16{op[23]}}, op[23:8] };
                        fetched = 3;
                        latch_op = 1;
                        nx_dec_xsp = 4;
                        nx_phase = PUSH_PC;
                    end
                    8'b011?_????: begin // JR
                        if( op[4] ) begin
                            nx_alu_imm  = { {16{op[23]}}, op[23:8] };
                            fetched = 3;
                        end else begin
                            nx_alu_imm  = { {24{op[15]}}, op[15:8] };
                            fetched = 2;
                        end
                        nx_nodummy_fetch = 1;
                        nx_pc_rel   = jp_ok;
                        nx_phase    = DUMMY;
                    end
                    8'b0000_111?: begin // RET / RETD
                        nx_wr_len       = 2;
                        nx_ram_ren      = 1; // RAM load enable
                        nx_sel_xsp      = 1;
                        fetched         = 0;
                        nx_keep_inc_xsp = op[0] ? op[23:8] : 16'd0; // RETD or RET
                        nx_phase        = POP_PC;
                    end
                    default: begin
                        nx_buserror = 1; // this should trigger a SWI
                    end
                endcase
            end
        end
        PUSH_SR: begin // PUSH_F is done here too
            nx_sel_xsp  = 1;
            nx_ram_dsel = DOUT_SR; // Select SR as ram_din
            nx_ram_wen  = 1;
            if( intproc ) begin
                nx_phase = IRQ;
                nx_wr_len= 2;
            end else begin
                nx_wr_len   = dec_xsp[2:0]; // 1 or 2 bytes
                nx_phase    = DUMMY;
            end
        end
        PUSH_PC: begin
            // store the PC
            nx_sel_xsp  = 1;
            nx_ram_dsel = DOUT_PC;
            nx_ram_wen  = 1;
            nx_wr_len   = 4;
            // jump
            if( intproc ) begin
                nx_dec_xsp = 2;
                req_wait = 1;
                nx_phase = PUSH_SR;
            end else begin
                nx_phase = PUSH_PC2;
            end
        end
        PUSH_PC2: begin
            nx_phase = DUMMY;
            nx_nodummy_fetch = 1;
            if( last_op[3:0]==4'he )
                nx_pc_rel = 1;  // CALLR
            else
                nx_pc_we  = 1; // or CALL
        end
        IRQ: begin
            nx_ram_wen = 0;
            nx_ram_ren = 0;
            nx_rda_irq = 1;
            nx_sel_xsp = 0;
            // iff is changed for both SWI and hardware interrupts, but
            // maybe it should only be changed for HW ones
            nx_iff     = alu_imm[4:2]==3'd7 ? 3'd7 : alu_imm[4:2]+3'd1;
            nx_wr_len  = 4; // misnomer: it really is a read len, not a wr len...
            nx_phase   = IRQ_JP;
            nx_intnest = intnest + 1'd1;
`ifdef SIMULATION
            if( &intnest ) begin $display("JT900H: reached maximum level of nested interrupts"); $finish; end
`endif
            nx_intproc = 0; // interrupt processing stops here
        end
        IRQ_JP: begin
            nx_alu_imm[23:0] = op[23:0];
            nx_pc_we         = 1;
            nx_ram_ren       = 0;
            nx_rda_irq       = 0;
            nx_phase         = DUMMY;
        end
        POP_PC: begin
            // retrieve the PC
            nx_inc_xsp       = keep_inc_xsp + 16'd4;
            nx_pc_we         = 1; // return
            nx_alu_imm[23:0] = op[23:0];
            // set RAM controller back to normal operation
            nx_sel_xsp       = 0;
            nx_ram_ren       = 0;
            nx_reti          = 0;
            nx_phase         = DUMMY;
        end
        PUSH_R: begin
            nx_ram_wen = 1;
            nx_sel_xsp = 1;
            nx_phase   = link ? LINK : DUMMY;
            req_wait   = 1; // if xsp is at an odd address, it needs an extra cycle
                            // for now, it is always taking the worst case
        end
        LINK: begin
            nx_alu_op  = ALU_MOVE;
            nx_regs_we = 4;
            nx_src     = 8'hfc; // xsp
            nx_phase   = DUMMY;
        end
        UNLK: begin // like a POP r
            nx_dst          = regs_src;
            nx_ram_ren      = 1;
            nx_sel_xsp      = 1;
            nx_keep_we      = 4;
            nx_wr_len       = 4;
            nx_keep_inc_xsp = 4;
            nx_phase        = LD_RAM;
        end
        IDX: if( idx_ok ) begin
            nx_idx_en = 0;
            // leave the fetched update to the next state
            // either LD_RAM or ST_RAM
            casez( {op[7:0], op_zz==2'b11} )
                9'b0000_01?0_1: begin // POP<W> (mem)
                    nx_wr_len    = 3'b1 << op[1];
                    nx_ram_ren   = 1; // RAM load enable
                    nx_sel_xsp   = 1;
                    nx_keep_inc_xsp = 16'd1 << op[1];
                    nx_dly_fetch = 1;
                    nx_popw      = 1;
                    nx_phase     = LD_RAM;
                end
                9'b0010_0???_0,       // LD   R,(mem) 0010_0RRR
                9'b001?_0???_1: begin // LDA  R,mem   001s_0RRR, but first half had zz==11
                    if( op_zz==2'b11 ) begin // LDA
                        nx_regs_we  = op[4] ? 3'b100 : 3'b010;
                        nx_dst      = expand_reg(op[2:0],op[4] ? 2'b10 : 2'b01);
                        nx_alu_imm  = { 8'd0, idx_addr };
                        nx_alu_op   = ldar ? ALU_ADDPC : ALU_MOVE;
                        nx_alu_smux = 1;
                        nx_phase    = DUMMY;
                    end else begin // LD
                        nx_phase   = LD_RAM;
                        nx_dst     = expand_reg(op[2:0],op_zz);
                        nx_keep_we = expand_zz( op_zz );
                        nx_ram_ren = 1;
                    end
                end
                9'b0001_01?0_1: begin // LD<W> (mem),(#16)
                    nx_ram_ren        = 1;
                    nx_wr_len         = 3'b1 << op[1];
                    nx_imm2idx        = 1;
                    nx_dly_fetch      = 3;
                    // Read from the address in imm
                    nx_phase          = LD_RAM;
                    nx_rda_imm        = 1;
                    nx_alu_imm[31:16] = op[23:8];
                end
                9'b01??_0???_1: begin // LD (mem),R
                    nx_phase    = EXEC;
                    nx_was_load = 1;
                end
                9'b1110_????_1: begin // CALL [cc,]mem
                    nx_alu_imm  = { 8'd0, idx_addr };
                    nx_phase    = EXEC;
                    nx_was_load = 1;
                end
                9'b1101_????_1: begin // JP cc,mem
                    nx_alu_imm  = { 8'd0, idx_addr };
                    nx_pc_we    = jp_ok;
                    nx_phase    = DUMMY;
                end
                //8'b1100_0???, // CHG #3,(mem)
                9'b1100_1???_?: begin // BIT #3,(mem)
                    nx_phase   = LD_RAM;
                    nx_ram_ren = 1;
                    nx_goexec  = 1;
                end
                9'b0000_00?0_1: begin // LD<B/W> (mem),#
                    nx_regs_we   = op[1] ? 3'd2 : 3'd1;
                    nx_dly_fetch = op[1] ? 3'd3 : 3'd2;
                    nx_phase     = ST_RAM;
                    nx_alu_smux  = 1;
                    nx_flag_we   = 1;
                    nx_alu_op    = ALU_MOVE;
                    nx_alu_imm   = { 16'd0, op[23:8] };
                end
                default: begin // load operand from memory
                    nx_phase   = LD_RAM;
                    nx_keep_lddwr = op[7:2] == 6'h10>>2; // LDD/LDI (R)
                    nx_ram_ren = 1;
                    nx_goexec  = 1;
                    nx_dst     = expand_reg(op[2:0],op_zz);
                    nx_src     = nx_dst;
                end
            endcase
        end
        DUMMY: begin
            if( !nodummy_fetch ) fetched = 1;
            nx_nodummy_fetch = 0;
            nx_alu_op  = ALU_NOP;
            nx_regs_we = keep_we;
            if( keep_we!=0 ) nx_flag_we = flag_we;
            nx_dec_xsp = keep_dec_xsp;
            nx_phase   = reti ? POP_PC : FETCH;
        end
        LD_RAM: begin
            nx_ram_ren = 0;
            if( goxec ) begin
                nx_phase    = EXEC;
                nx_was_load = 1;
                nx_exec_imm = 1;
                nx_ldd_write = keep_lddwr;
                nx_idx_en   = 0;
                // no change to fetched because we will
                // reuse the last OP code byte
            end else if( imm2idx || popw ) begin
                nx_ram_wen  = 1;
                nx_alu_op   = ALU_MOVE;
                nx_phase    = ST_RAM;
                nx_rda_imm  = 0;
                nx_alu_smux = 1;
                nx_sel_xsp  = 0;
                // do not fetch before a ST_RAM to
                // prevent the RAM controller from caching data
            end else begin
                nx_phase    = FETCH;
                nx_ram_dsel = DOUT_PC; // copy the RAM output
                if( popf || popsr ) begin
                    nx_alu_op = ALU_POPF;
                    nx_flag_we = 1;
                end
                if( popsr ) begin
                    nx_rfp_we = 1;
                    nx_iff    = op[14:12];
                end
                if( reti ) begin
                    nx_wr_len       = 2;
                    nx_ram_ren      = 1; // RAM load enable
                    nx_sel_xsp      = 1;
                    fetched         = 0;
                    nx_nodummy_fetch= 1;
                    nx_keep_inc_xsp = 0;
                    nx_phase        = DUMMY;
                end
                else begin
                    fetched = 1;  // this will set the RAM wait flag too
                end
            end
            nx_regs_we = keep_we;
            nx_data_latch = op; // is it necessary to have it in data_latch
                                // and alu_imm?
            nx_alu_imm    = op; // make it available to the ALU too
            nx_inc_xsp = keep_inc_xsp;
        end
        CPDR: begin
            if( nx_v & ~nx_z) begin // repeat
                nx_idx_en   = 1;
                nx_idx_last = 1;
                nx_ram_ren  = 1;
                nx_phase    = LD_RAM;
                nx_rep      = 0;
                nx_goexec   = 1;
                fetched     = 0;
                req_wait    = 1;
                nx_alu_op   = ALU_NOP;
            end else begin
                nx_phase    = FETCH;
                fetched     = dly_fetch;
            end
        end
        ST_RAM: begin
            if( rep && nx_v ) begin // repeat
                nx_idx_en   = 1;
                nx_idx_last = 1;
                nx_ram_ren  = 1;
                nx_phase    = LD_RAM;
                nx_rep      = 0;
                nx_goexec   = 1;
                fetched     = 0;
                req_wait    = 1;
                nx_alu_op   = ALU_NOP;
            end else begin
                nx_phase   = FETCH;
                fetched    = dly_fetch;  // this will set the RAM wait flag too
            end
            if( !imm2idx && !popw ) begin
                nx_ram_wen = 1;
                nx_wr_len  = regs_we;
                nx_dec_xde = keep_dec_xde;
                nx_dec_xix = keep_dec_xix;
                nx_inc_xde = keep_inc_xde;
                nx_inc_xix = keep_inc_xix;
                nx_selop16 = keep_selop16;
                nx_alu_smux= keep_smux;
            end
            nx_dly_fetch = 0;
            nx_popw      = 0;
        end
        DJNZ: begin
            nx_alu_imm = { {24{op[7]}}, op[7:0] };
            nx_pc_rel  = !djnz;
            fetched    = 1;
            nx_phase   = DUMMY;
            nx_nodummy_fetch = 1;
        end
        EXEC: begin // second half of op-code decoding
            nx_phase = FETCH;
            casez( { op[7:0], was_load, bad_zz } )
                10'b0101_????_?0: begin // DIV RR,r   -- DIV RR,(mem)
                    nx_alu_op  = op[2] ? ALU_DIVS : ALU_DIV;
                    nx_dst     = expand_reg(op[2:0],op_zz);
                    if( was_load ) begin
                        nx_src      = nx_dst;
                        nx_alu_smux = 1;
                    end else begin
                        nx_src     = regs_dst; // swap R, r
                    end
                    nx_regs_we = expand_zz( op_zz );
                    nx_keep_we = nx_regs_we;
                    nx_phase   = WAIT_ALU;
                    fetched    = 1; // this also gives time to the ALU to set the busy bit
                end
                10'b0000_101?_00: begin // DIV rr,#
                    nx_alu_op  = op[0] ? ALU_DIVS : ALU_DIV;
                    nx_alu_imm[15:0] = op[23:8];
                    nx_alu_smux = 1;
                    nx_dst     = nx_src;
                    nx_regs_we = expand_zz( op_zz );
                    nx_keep_we = nx_regs_we;
                    nx_phase   = WAIT_ALU;
                    fetched    = op_zz[0] ? 3'd3 : 3'd2; // this also gives time to the ALU to set the busy bit
                end
                10'b0001_1001_00: begin // MULA
                    nx_sel_xde  = 1;
                    nx_ram_ren = 1;
                    nx_phase   = LD_XHL;
                end
                10'b0001_1001_10: begin // LD<W> (#16),(mem)
                    nx_alu_op         = ALU_NOP;
                    nx_alu_imm[31:16] = op[23:8];
                    nx_regs_we        = expand_zz( op_zz );
                    nx_keep_we        = nx_regs_we;
                    nx_flag_we        = 1;
                    nx_dly_fetch      = 3;
                    nx_keep_smux      = 1;
                    nx_ld2imm         = 1;
                    nx_phase          = ST_RAM;
                end
                10'b1100_1???_11,   // BIT #3,(mem), only byte length
                10'b1001_1???_11,   // LDCF #3,(mem)
                10'b1000_1???_11,   // ORCF #3,(mem)
                10'b1011_1???_11,   // SET #3,(mem)
                10'b1010_1???_11:   // TSET #3,(mem)
                begin // Arithmetic on memory (mem), R
                    nx_flag_we = 1;
                    fetched    = 1;
                    case( op[6:3] )
                        4'b0101,4'b0111: begin
                            nx_alu_op    = op[4] ? ALU_SETX : ALU_TSETX;
                            nx_regs_we   = 1;
                            fetched      = 0;
                            nx_dly_fetch = 1;
                            nx_phase     = ST_RAM;
                        end
                        4'b1001: nx_alu_op = ALU_BITX;
                        4'b0011: nx_alu_op = ALU_LDCFX;
                        4'b0001: nx_alu_op = ALU_ORCFX;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_alu_imm[10:8] = op[2:0];
                end
                10'b0011_0???_10: begin // EX (mem),r
                    nx_dst       = expand_reg(op[2:0],op_zz);
                    nx_src       = nx_dst;
                    nx_regs_we   = expand_zz( op_zz );
                    nx_alu_op    = ALU_MOVE;
                    fetched      = 0;
                    nx_dly_fetch = 1;
                    nx_ram_dsel  = DOUT_EX;
                    nx_phase     = ST_RAM;
                end
                10'b1100_0???_11: begin // CHG #3,(mem)
                    nx_flag_we       = 1;
                    nx_regs_we       = 1;
                    nx_alu_op        = ALU_CHGX;
                    fetched          = 0;
                    nx_dly_fetch     = 1;
                    nx_phase         = ST_RAM;
                    nx_alu_imm[10:8] = op[2:0];
                end
                10'b1011_1???_00: begin // EX R,r
                    nx_src     = regs_dst;
                    nx_dst     = expand_reg(op[2:0],op_zz);
                    nx_regs_we = expand_zz( op_zz );
                    nx_alu_op  = ALU_NOP;
                    nx_keep_ex = 1;
                    fetched    = 1;
                end
                10'b0001_01??_1?: begin // CPD/CPI
                    nx_alu_op  = ALU_CPD; // same for both CPD & CPI
                    nx_dst     = 8'he0;
                    nx_regs_we = expand_zz( op_zz );
                    nx_flag_we = 1;
                    nx_alu_smux= 1;
                    nx_dec_bc  = 1;
                    if( !op[0] ) begin
                        fetched = 1;
                    end else begin
                        nx_phase     = CPDR;
                        nx_rep       = 1;
                        fetched      = 0;
                        nx_dly_fetch = 1;
                    end
                end
                10'b0001_00??_1?: begin // LDD, LDDR, LDI, LDIR
                    nx_alu_op    = ALU_LDD;
                    nx_regs_we   = expand_zz( op_zz );
                    nx_keep_we   = nx_regs_we;
                    nx_flag_we   = 1;
                    nx_dec_bc    = 1;
                    nx_dly_fetch = 1;
                    nx_idx_en    = 0;
                    if( op[1] ) begin // LDD
                        nx_keep_dec_xde = last_op[1];
                        nx_keep_dec_xix = last_op[2];
                    end else begin // LDI
                        nx_keep_inc_xde = last_op[1];
                        nx_keep_inc_xix = last_op[2];
                    end
                    nx_rep       = op[0];
                    nx_phase     = ST_RAM;
                end
                10'b1011_0???_11: begin  // RES #3,(mem)
                    nx_alu_op       = ALU_RESX;
                    nx_regs_we      = 1;
                    nx_flag_we      = 1;
                    nx_alu_imm[10:8] = op[2:0];
                    nx_dly_fetch    = 1;
                    nx_phase        = ST_RAM;
                end
                10'b0111_1???_1?: begin // Shift operations on memory RL<W> (mem)
                    nx_regs_we   = expand_zz( op_zz );
                    nx_keep_we   = nx_regs_we;
                    nx_flag_we   = 1;
                    nx_dly_fetch = 1;
                    nx_phase     = ST_RAM;
                    case(op[2:0])
                        3'b000: nx_alu_op = ALU_RLCX;
                        3'b001: nx_alu_op = ALU_RRCX;
                        3'b010: nx_alu_op = ALU_RLX;
                        3'b011: nx_alu_op = ALU_RRX;
                        3'b100: nx_alu_op = ALU_SLAX;
                        3'b101: nx_alu_op = ALU_SRAX;
                        3'b110: nx_alu_op = ALU_SLLX;
                        3'b111: nx_alu_op = ALU_SRLX;
                    endcase
                end
                10'b1111_????_01: begin // RET cc
                    if( jp_ok ) begin
                        nx_wr_len       = 2;
                        nx_ram_ren      = 1; // RAM load enable
                        nx_sel_xsp      = 1;
                        fetched         = 0;
                        nx_phase        = POP_PC;
                    end else begin
                        fetched = 1;
                    end
                end
                10'b1111_1???_00: begin // Shift operations with accumulator
                    nx_regs_we = expand_zz( op_zz );
                    nx_src     = 8'hE0; // current A register
                    nx_keep_we = nx_regs_we;
                    //nx_multi   = 1;
                    fetched    = 1;
                    nx_phase   = WAIT_ALU;
                    case(op[2:0])
                        3'b000: nx_alu_op = ALU_RLC;
                        3'b001: nx_alu_op = ALU_RRC;
                        3'b010: nx_alu_op = ALU_RL;
                        3'b011: nx_alu_op = ALU_RR;
                        3'b100: nx_alu_op = ALU_SLA;
                        3'b101: nx_alu_op = ALU_SRA;
                        3'b110: nx_alu_op = ALU_SLL;
                        3'b111: nx_alu_op = ALU_SRL;
                    endcase
                end
                10'b1???_1???_10: begin // arithmetic to memory
                    nx_src       = regs_dst;
                    case( op[6:4] )
                        3'b110: nx_alu_op = ALU_OR;
                        3'b101: nx_alu_op = ALU_XOR;
                        3'b100: nx_alu_op = ALU_AND;
                        3'b011: nx_alu_op = ALU_SBC2; // substraction requires
                        3'b010: nx_alu_op = ALU_SUB2; // different operand order
                        3'b001: nx_alu_op = ALU_ADC;
                        3'b000: nx_alu_op = ALU_ADD;
                        3'b111:  nx_alu_op = ALU_CP2;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_regs_we   = expand_zz( op_zz );
                    nx_flag_we   = 1;
                    nx_alu_smux  = 1;
                    nx_dly_fetch = 1;
                    nx_phase     = op[6:4]!=3'b111 ? ST_RAM : DUMMY;
                end
                10'b0011_1???_10: begin // arithmetic with immediate, to memory
                    nx_src       = regs_dst;
                    case( op[2:0] )
                        3'b110: nx_alu_op = ALU_OR;
                        3'b101: nx_alu_op = ALU_XOR;
                        3'b100: nx_alu_op = ALU_AND;
                        3'b011: nx_alu_op = ALU_SBC;
                        3'b010: nx_alu_op = ALU_SUB;
                        3'b001: nx_alu_op = ALU_ADC;
                        3'b000: nx_alu_op = ALU_ADD;
                        3'b111:  nx_alu_op = ALU_CP;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_regs_we   = expand_zz( op_zz );
                    nx_flag_we   = 1;
                    nx_alu_smux  = 1;
                    nx_alu_imm[15: 0] = op[23:8];
                    nx_alu_imm[31:16] = alu_imm[15:0];
                    nx_alu_imux  = 1;
                    nx_phase     = op[2:0]!=3'b111 ? ST_RAM : DUMMY;
                    if( op[2:0] != 3'b111 ) begin // all but CP
                        nx_phase     = ST_RAM;
                        nx_dly_fetch = op_zz[0] ? 3'd3 : 3'd2;
                    end else begin // CP
                        nx_phase = DUMMY;
                        fetched  = op_zz[0] ? 3'd2 : 3'd1;
                    end
                end
                10'b1000_1???_0?: begin // LD R,r
                    nx_src     = regs_dst;
                    nx_dst     = expand_reg(op[2:0],op_zz);
                    nx_alu_op  = ALU_MOVE;
                    nx_regs_we = expand_zz( op_zz );
                    fetched    = 1;
                end
                10'b1001_1???_0?: begin // LD r,R
                    nx_src    = expand_reg(op[2:0],op_zz);
                    nx_alu_op = ALU_MOVE;
                    nx_regs_we = expand_zz( op_zz );
                    fetched   = 1;
                end
                10'b1101_1???_0?, // CP r,#3
                10'b1010_1???_0?: // LD r,#3
                begin
                    nx_alu_imm  = {29'd0,op[2:0]};
                    case( op[6:4] )
                        3'b101: begin
                            nx_alu_op  = ALU_CP;
                            nx_flag_we = 1;
                        end
                        3'b010: nx_alu_op  = ALU_MOVE;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_alu_smux = 1;
                    fetched     = 1;
                    nx_regs_we  = expand_zz( op_zz );
                    // nx_phase    = DUMMY;
                end
                10'b0000_011?_10: begin // RRD
                    nx_alu_op    = op[0] ? ALU_RRD : ALU_RLD;
                    nx_regs_we   = expand_zz( op_zz );
                    nx_dst       = 0;
                    nx_phase     = ST_RAM;
                    nx_ld_high   = 1;
                    nx_dly_fetch = 1;
                end
                10'b0000_0111_0?, // NEG dst
                10'b0000_0110_0?: begin // CPL dst
                    nx_regs_we = expand_zz( op_zz );
                    case( op[2:0] )
                        3'b110: nx_alu_op  = ALU_CPL;
                        3'b111: nx_alu_op  = ALU_NEG;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    fetched    = 1;
                end
                10'b0001_0110_00: begin // MIRR
                    nx_regs_we = 3'b010;
                    nx_alu_op  = ALU_MIRR;
                    fetched    = 1;
                end
                10'b0001_1100_??: begin // DJNZ
                    nx_alu_op = ALU_DJNZ;
                    nx_regs_we = expand_zz( op_zz );
                    fetched   = 1;
                    nx_phase  = DJNZ;
                end
                10'b0011_0100_0?,       // TSET #4, r
                10'b0011_0001_0?,       // SET #4, r
                10'b0011_0000_0?,       // RES #4, r
                10'b0011_0011_0?,       // BIT #4, r
                10'b0011_0010_0?: begin // CHG #4, dst
                    nx_alu_imm = { 28'd0,op[11:8] };
                    case( op[2:0] )
                        0: nx_alu_op = ALU_RES;
                        1: nx_alu_op = ALU_SET;
                        2: nx_alu_op = ALU_CHG;
                        3: begin nx_alu_op = ALU_BIT; nx_flag_we  = 1; end
                        4: nx_alu_op = ALU_TSET;
                        default:;
                    endcase
                    nx_regs_we  = expand_zz( op_zz );
                    nx_alu_smux = 1;
                    fetched     = 2;
                end
                10'b1110_????_11: begin // CALL [cc],mem
                    if( jp_ok ) begin
                        fetched = 1;
                        nx_dec_xsp = 4;
                        nx_phase = PUSH_PC;
                    end else begin
                        fetched = 1;
                    end
                end
                10'b1110_1???_0?: // RLC/RRC/RL/RR/SLA/SRA/SLL/SRL #4, r
                begin
                    nx_alu_imm  = { 28'd0,op[11:8] };
                    nx_alu_smux = 1;
                    fetched     = 2;
                    case(op[2:0])
                        3'b000: nx_alu_op = ALU_RLC;
                        3'b001: nx_alu_op = ALU_RRC;
                        3'b010: nx_alu_op = ALU_RL;
                        3'b011: nx_alu_op = ALU_RR;
                        3'b100: nx_alu_op = ALU_SLA;
                        3'b101: nx_alu_op = ALU_SRA;
                        3'b110: nx_alu_op = ALU_SLL;
                        3'b111: nx_alu_op = ALU_SRL;
                    endcase
                    nx_regs_we  = expand_zz( op_zz );
                    nx_keep_we  = nx_regs_we;
                    nx_phase    = WAIT_ALU;
                end
                10'b0010_?011_0?, // LDCF #4,r   - A,r
                10'b0010_?010_0?, // XORCF #4,r  - A,r
                10'b0010_?001_0?, // ORCF #4,r   - A,r
                10'b0010_?000_0?, // ANDCF #4,r  - A,r
                10'b0010_?100_0?: // STCF #4,r   - A,r
                begin
                    nx_alu_imm = { 28'd0,op[11:8] };
                    nx_src      = 8'he0;    // A
                    if( !op[3] ) begin
                        nx_alu_smux = 1;
                        fetched     = 2;
                    end else begin
                        fetched     = 1;
                    end
                    case( op[2:0] )
                        0: nx_alu_op = ALU_ANDCF;
                        1: nx_alu_op = ALU_ORCF;
                        2: nx_alu_op = ALU_XORCF;
                        3: nx_alu_op = ALU_LDCF;
                        4: nx_alu_op = ALU_STCF;
                        default:;
                    endcase
                    nx_flag_we = !op[2]; // only STCF alters registers
                    nx_regs_we = expand_zz( op_zz );
                end
                10'b0010_1000_1?, // ANDCF A,(mem)
                10'b0010_1001_1?, // ORCF A,(mem)
                10'b0010_1010_1?, // XORCF A,(mem)
                10'b0010_1011_1?, // LDCF A,(mem)
                10'b0010_1100_1?: // STCF A,(mem)
                begin
                    nx_src = 8'hE0;
                    case(op[2:0])
                        0: nx_alu_op = ALU_ANDCFA;
                        1: nx_alu_op = ALU_ORCFA;
                        2: nx_alu_op = ALU_XORCFA;
                        3: nx_alu_op = ALU_LDCFA;
                        4: nx_alu_op = ALU_STCFA;
                        default:;
                    endcase
                    if( op[2] ) begin
                        nx_dly_fetch = 1;
                        nx_phase     = ST_RAM;
                    end else begin
                        fetched    = 1;
                    end
                    nx_flag_we = 1;
                    nx_regs_we = 1;
                end
                10'b1000_0???_11, // ANDCF #3,(mem)
                10'b1001_0???_11, // XORCF #3,(mem)
                10'b1010_0???_11: // STCF  #3,(mem)
                begin
                    case( op[5:4] )
                        0: nx_alu_op = ALU_ANDCFX;
                        1: nx_alu_op = ALU_XORCFX;
                        2: nx_alu_op = ALU_STCFX;
                        default:;
                    endcase
                    nx_alu_imm[10:8] = op[2:0];
                    nx_regs_we       = 1; // expand_zz( op_zz );
                    nx_flag_we       = 1;
                    nx_alu_smux      = 1;
                    if( op[5] ) begin
                        nx_dly_fetch = 1;
                        nx_phase     = ST_RAM;
                    end else begin
                        fetched = 1;
                    end
                end
                10'b01??_0???_11: begin // LD (mem),R
                    nx_alu_op = ALU_MOVE;
                    nx_src    = expand_reg(op[2:0],op[5:4]);
                    nx_regs_we = expand_zz( op[5:4] );
                    nx_flag_we = 1;
                    nx_dly_fetch = 1;
                    nx_phase     = ST_RAM;
                end
                10'b0111_????_00: begin // SCC
                    nx_alu_imm[15:0] = { 15'd0, jp_ok };
                    nx_alu_smux = 1;
                    nx_alu_op   = ALU_MOVE;
                    nx_regs_we  = expand_zz( op_zz );
                    fetched     = 1;
                end
                10'b0110_0???_?0, // INC #3, dst
                10'b0110_1???_?0: // DEC #3, dst
                begin
                    nx_regs_we  = expand_zz( op_zz );
                    nx_alu_smux = 1;
                    if( was_load ) begin
                        nx_alu_imm[23:16] = { 4'd0, inc_opnd };
                        nx_alu_op   = op[3] ? ALU_DECX : ALU_INCX;
                        nx_dly_fetch = 1;
                        nx_flag_we   = 1;
                        nx_phase     = ST_RAM;
                    end else begin
                        nx_alu_imm = { 28'd0, inc_opnd };
                        nx_alu_op  = op[3] ? ALU_DEC : ALU_INC;
                        fetched    = 1;
                    end
                end
                10'b0000_0100_10: begin // PUSH<W> mem
                    nx_regs_we  = expand_zz( op_zz );
                    nx_dec_xsp  = {13'd0,nx_regs_we};
                    nx_wr_len   = nx_regs_we[2:0];
                    nx_alu_op   = ALU_MOVE;
                    nx_phase    = PUSH_R;
                    nx_flag_we  = 1;
                    nx_alu_smux = 1;
                end
                10'b0000_0100_00: begin // PUSH r
                    nx_alu_op  = ALU_MOVE;
                    nx_regs_we = expand_zz( op_zz );
                    nx_dec_xsp  = {13'd0,nx_regs_we};
                    nx_wr_len  = nx_dec_xsp[2:0];
                    nx_phase   = PUSH_R;
                    nx_flag_we = 1;
                    // the dummy state will do the fetching
                end
                10'b0000_1100_00: begin // LINK r, num PUSH r
                    nx_alu_op  = ALU_MOVE;
                    nx_regs_we = expand_zz( op_zz );
                    nx_dec_xsp = {13'd0,nx_regs_we};
                    nx_keep_dec_xsp = op[23:8];
                    nx_wr_len  = nx_dec_xsp[2:0];
                    nx_phase   = PUSH_R;
                    nx_link    = 1;
                    // the dummy state will do the fetching
                end
                10'b0000_1101_00: begin // UNLK dst
                    nx_alu_op  = ALU_MOVE;
                    nx_dst     = 8'hfc; // xsp
                    nx_regs_we = expand_zz( op_zz );
                    req_wait   = 1; // extra cycle for the MOVE to complete
                    nx_phase   = UNLK;
                end
                10'b0000_0101_00: begin // POP r
                    nx_ram_ren = 1;
                    nx_sel_xsp = 1;
                    nx_keep_we = expand_zz( op_zz );
                    nx_wr_len  = expand_zz( op_zz );
                    nx_dst     = regs_dst;
                    nx_phase   = LD_RAM;
                    nx_keep_inc_xsp = { 13'd0, expand_zz( op_zz ) };
                end
                10'b0000_111?_??: begin // BS1B, BS1F
                    nx_alu_op  = op[0] ? ALU_BS1B : ALU_BS1F;
                    nx_dst     = 8'hE0;
                    nx_regs_we = expand_zz( op_zz );
                    fetched    = 1;
                end
                10'b0001_001?_0?: begin // EXTS, EXTZ
                    nx_alu_op  = op[0] ? ALU_EXTS : ALU_EXTZ;
                    nx_regs_we = expand_zz( op_zz );
                    fetched    = 1;
                end
                10'b0001_0100_00: begin // PAA
                    nx_alu_op  = ALU_PAA;
                    nx_regs_we = expand_zz( op_zz );
                    fetched = 1;
                end
                10'b0011_1?00_0?, // MINC1/MDEC1
                10'b0011_1?01_0?, // MINC2/MDEC2
                10'b0011_1?10_0?, // MINC4/MDEC4
                10'b0000_0011_0?: // LD r,#
                begin
                    nx_alu_op   = op[7:0] == 8'b0000_0011 ? ALU_MOVE  :
                                  op[7:0] == 8'b0011_1100 ? ALU_MDEC1 :
                                  op[7:0] == 8'b0011_1101 ? ALU_MDEC2 :
                                  op[7:0] == 8'b0011_1110 ? ALU_MDEC4 :
                                  op[7:0] == 8'b0011_1000 ? ALU_MINC1 :
                                  op[7:0] == 8'b0011_1001 ? ALU_MINC2 :
                                  op[7:0] == 8'b0011_1010 ? ALU_MINC4 :
                                  ALU_NOP;
                    nx_alu_smux = 1;
                    fetched     = 2;
                    if( op_zz==0 ) begin
                        nx_alu_imm = {24'd0,op[15:8]};
                        nx_regs_we  = expand_zz( op_zz );
                        //nx_phase = DUMMY;
                    end else begin
                        nx_alu_imm[7:0] = op[15:8];
                        nx_alu_wait = 1;
                        nx_keep_we  = expand_zz( op_zz );
                        nx_phase = FILL_IMM;
                    end
                end
                10'b0100_0???_?0, // MUL  RR,r
                10'b0100_1???_?0: // MULS RR,r
                begin
                    if( was_load ) begin
                        nx_alu_smux = 1;
                    end else begin
                        nx_src = regs_dst; // swap R, r
                    end
                    nx_dst     = op_zz[0] ? // 16x16 -> 32
                        { 3'b111, op[2:0], 2'b0 } :
                        { 4'he, op[2:1], 2'b0 }; // 8x8 -> 16
                    nx_alu_op  = op[3] ? ALU_MULS : ALU_MUL;
                    nx_regs_we = op_zz[0] ? 3'b100 : 3'b010;
                    nx_keep_we = nx_regs_we;
                    nx_phase   = DUMMY;
                end
                10'b0000_1000_00, // MUL  rr,#
                10'b0000_1001_00: // MULS rr,#
                begin
                    nx_alu_imm[15:0] = op[23:8];
                    nx_alu_smux= 1;
                    nx_alu_op  = op[0] ? ALU_MULS : ALU_MUL;
                    nx_regs_we = op_zz[0] ? 3'b100 : 3'b010;
                    nx_keep_we = nx_regs_we;
                    nx_phase   = DUMMY;
                    fetched    = op_zz[0] ? 3'd2 : 3'd1;
                end
                10'b0001_0000_00: begin // DAA
                    nx_regs_we = expand_zz( op_zz );
                    nx_alu_op  = ALU_DAA;
                    fetched    = 1;
                end
                10'b1111_0???_?0, // CP  R,r
                10'b1110_0???_?0, // OR  R,r
                10'b1101_0???_??, // XOR R,r
                10'b1100_0???_?0, // AND R,r
                10'b1010_0???_?0, // SUB R,r
                10'b100?_0???_?0: // ADD R,r / ADC R,r
                begin
                    nx_src      = regs_dst; // swap R, r
                    nx_dst      = expand_reg(op[2:0],op_zz);
                    nx_alu_op   =
                        op[7:3] == 5'b1111_0 ? ALU_CP  :
                        op[7:3] == 5'b1110_0 ? ALU_OR  :
                        op[7:3] == 5'b1101_0 ? ALU_XOR :
                        op[7:3] == 5'b1100_0 ? ALU_AND :
                        op[7:3] == 5'b1010_0 ? ALU_SUB :
                        op[7:3] == 5'b1001_0 ? ALU_ADC :
                        op[7:3] == 5'b1000_0 ? ALU_ADD :
                        ALU_NOP;
                    nx_regs_we = expand_zz( op_zz );
                    if( op[7:3] == 5'b1111_0 ) begin
                        nx_flag_we = 1;
                    end
                    nx_keep_we  = nx_regs_we;
                    nx_phase    = DUMMY;
                    if( exec_imm )
                        nx_alu_smux = 1;
                end
                10'b1100_1111_0?, // CP  r,#imm
                10'b1100_101?_0?, // SUB r,# - SBC r,#
                10'b1100_100?_0?, // ADD r,# - ADC r,#
                10'b1100_1110_0?, // OR r,#
                10'b1100_1101_0?, // XOR r,#
                10'b1100_1100_0?: // AND r,#
                begin
                    nx_alu_op   =
                                  op[7:0]==8'b1100_1111 ? ALU_CP  :
                                  op[7:0]==8'b1100_1000 ? ALU_ADD :
                                  op[7:0]==8'b1100_1001 ? ALU_ADC :
                                  op[7:0]==8'b1100_1010 ? ALU_SUB :
                                  op[7:0]==8'b1100_1011 ? ALU_SBC :
                                  op[7:0]==8'b1100_1110 ? ALU_OR  :
                                  op[7:0]==8'b1100_1101 ? ALU_XOR :
                                  ALU_AND;
                    nx_alu_smux = 1;
                    fetched     = 2;
                    if( op_zz==0 ) begin
                        nx_alu_imm = {24'd0,op[15:8]};
                        nx_regs_we = expand_zz( op_zz );
                        nx_nodummy_fetch = 1;
                        nx_phase   = DUMMY;
                    end else begin
                        nx_alu_imm[7:0] = op[15:8];
                        nx_alu_wait = 1;
                        nx_keep_we  = expand_zz( op_zz );
                        nx_phase = FILL_IMM;
                    end
                    if( op[7:0] == 8'b1100_1111 ) begin // CP
                        nx_flag_we = 1;
                    end
                end
                default: nx_buserror = 1;
            endcase
        end
        LD_XHL: begin
            nx_alu_imm[15:0] = op[15:0];
            nx_sel_xhl       = 1;
            nx_sel_xde       = 0;
            nx_phase         = MULA;
        end
        MULA: begin
            nx_sel_xhl        = 0;
            nx_dec_xhl        = 1;
            nx_ram_ren        = 0;
            nx_alu_op         = ALU_MULA;
            nx_alu_imm[31:16] = op[15:0];
            nx_regs_we        = 3'b100; // long word
            nx_phase          = FETCH;
            fetched           = 1;
        end
        WAIT_ALU: begin
            if( alu_busy ) begin
                nx_regs_we = keep_we;
                nx_keep_we = keep_we;
                nx_phase   = WAIT_ALU;
            end else begin
                nx_keep_we = 0;
                nx_alu_op  = ALU_NOP;
                nx_phase   = FETCH;
            end
            nx_alu_op  = alu_op;
            nx_dst     = regs_dst;
        end
        FILL_IMM: begin
            nx_alu_wait = 0;
            nx_phase = FETCH;
            nx_regs_we = keep_we;
            nx_pc_we = keep_pc_we;
            case ( op_zz )
                1: begin
                    nx_alu_imm[31:16] = 0;
                    nx_alu_imm[15:8] = op[7:0];
                    fetched = 1;
                end
                2: begin
                    nx_alu_imm[31:8] = op[23:0];
                    fetched = 3;
                end
                3: begin // special case to signal 3 bytes, used for JP instruction
                    nx_alu_imm[23:8] = op[15:0];
                    fetched = 2;
                end
                default:;
            endcase
        end
        default: nx_phase=ILLEGAL;
    endcase
    // leave this at the bottom
    nx_ram_wait = fetched!=0 || req_wait;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        //illegal      <= 0;
        op_phase       <= FETCH;
        idx_en         <= 0;
        regs_src       <= 0;
        regs_dst       <= 0;
        alu_op         <= 0;
        alu_imm        <= 0;
        alu_smux       <= 0;
        keep_smux      <= 0;
        alu_imux       <= 0;
        alu_wait       <= 0;
        ram_ren        <= 0;
        op_zz          <= 0;
        regs_we        <= 0;
        keep_we        <= 0;
        ram_wait       <= 0;
        last_op        <= 0;
        ram_wen        <= 0;
        wr_len         <= 0;
        ram_dsel       <= 0;
        data_latch     <= 0;
        nodummy_fetch  <= 0;
        goxec          <= 0;
        exec_imm       <= 0;
        keep_pc_we     <= 0;
        pc_we          <= 0;
        pc_rel         <= 0;
        rfp_we         <= 0;
        was_load       <= 0;
        flag_we        <= 0;
        dly_fetch      <= 0;
        // RAM Controller
        sel_xsp        <= 0;
        dec_xsp        <= 0;
        inc_xsp        <= 0;
        keep_inc_xsp   <= 0;
        keep_dec_xsp   <= 0;
        sel_op16       <= 0;
        sel_op8        <= 0;
        keep_selop16   <= 0;

        riff           <= 3'b111;
        dec_bc         <= 0;
        idx_last       <= 0;
        ld_high        <= 0;
        link           <= 0;
        popf           <= 0;
        popsr          <= 0;
        // LDD/LDI
        dec_xde        <= 0;
        dec_xix        <= 0;
        inc_xde        <= 0;
        inc_xix        <= 0;
        keep_dec_xde   <= 0;
        keep_dec_xix   <= 0;
        keep_inc_xde   <= 0;
        keep_inc_xix   <= 0;
        ldd_write      <= 0;
        keep_lddwr     <= 0;
        rep            <= 0;
        intproc        <= 0;
        intnest        <= 0;
        reti           <= 0;
        ex_we          <= 0;
        keep_ex        <= 0;
        imm2idx        <= 0;
        rda_imm        <= 0;
        rda_irq        <= 0;
        popw           <= 0;
        sel_xde        <= 0;
        sel_xhl        <= 0;
        dec_xhl        <= 0;
        ld2imm         <= 0;
        buserror       <= 0;
        halted         <= 0;
    end else if(cen) begin
        op_phase       <= nx_phase;
        idx_en         <= nx_idx_en;
        regs_src       <= nx_src;
        regs_dst       <= nx_dst;
        alu_op         <= nx_alu_op;
        alu_imm        <= nx_alu_imm;
        alu_smux       <= nx_alu_smux;
        keep_smux      <= nx_keep_smux;
        alu_imux       <= nx_alu_imux;
        alu_wait       <= nx_alu_wait;
        ram_ren        <= nx_ram_ren;
        ram_wen        <= nx_ram_wen;
        op_zz          <= nx_op_zz;
        regs_we        <= nx_regs_we;
        ram_wait       <= nx_ram_wait;
        wr_len         <= nx_wr_len;
        ram_dsel       <= nx_ram_dsel;
        data_latch     <= nx_data_latch;
        inc_rfp        <= nx_inc_rfp;
        dec_rfp        <= nx_dec_rfp;
        keep_we        <= nx_keep_we;
        nodummy_fetch  <= nx_nodummy_fetch;
        goxec          <= nx_goexec;
        exec_imm       <= nx_exec_imm;
        keep_pc_we     <= nx_keep_pc_we;
        pc_we          <= nx_pc_we;
        pc_rel         <= nx_pc_rel;
        rfp_we         <= nx_rfp_we;
        was_load       <= nx_was_load;
        flag_we        <= nx_flag_we;
        dly_fetch      <= nx_dly_fetch;
        sel_xsp        <= nx_sel_xsp;
        sel_op16       <= nx_selop16;
        sel_op8        <= nx_selop8;
        keep_selop16   <= nx_keep_selop16;
        dec_xsp        <= nx_dec_xsp;
        inc_xsp        <= nx_inc_xsp;
        keep_inc_xsp   <= nx_keep_inc_xsp;
        keep_dec_xsp   <= nx_keep_dec_xsp;
        riff           <= nx_iff;
        dec_bc         <= nx_dec_bc;
        idx_last       <= nx_idx_last;
        // LDD/LDI:
        dec_xde        <= nx_dec_xde;
        dec_xix        <= nx_dec_xix;
        inc_xde        <= nx_inc_xde;
        inc_xix        <= nx_inc_xix;
        keep_dec_xde   <= nx_keep_dec_xde;
        keep_dec_xix   <= nx_keep_dec_xix;
        keep_inc_xde   <= nx_keep_inc_xde;
        keep_inc_xix   <= nx_keep_inc_xix;

        ldd_write      <= nx_ldd_write;
        keep_lddwr     <= nx_keep_lddwr;
        rep            <= nx_rep;

        ld_high        <= nx_ld_high;
        link           <= nx_link;
        popf           <= nx_popf;
        popsr          <= nx_popsr;

        intproc        <= nx_intproc;
        intnest        <= nx_intnest;
        reti           <= nx_reti;
        ex_we          <= nx_ex_we;
        keep_ex        <= nx_keep_ex;
        imm2idx        <= nx_imm2idx;
        rda_imm        <= nx_rda_imm;
        rda_irq        <= nx_rda_irq;
        popw           <= nx_popw;

        sel_xde        <= nx_sel_xde;
        sel_xhl        <= nx_sel_xhl;
        dec_xhl        <= nx_dec_xhl;
        ld2imm         <= nx_ld2imm;

        buserror       <= nx_buserror;
        halted         <= nx_halted;

        if( latch_op ) last_op <= op[7:0];
    end
end

endmodule