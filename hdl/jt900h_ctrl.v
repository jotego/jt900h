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
    Date: 30-11-2021 */

module jt900h_ctrl(
    input             rst,
    input             clk,
    input             cen,

    // PC
    output reg [ 1:0] fetched,    // number of bytes consumed
    output reg        pc_we,      // absolute value write
    output reg        pc_rel,     // relative value write

    output reg        ram_ren,    // read enable
    output reg        ram_wen,    // write enable
    output reg        idx_en,
    input             idx_ok,
    input      [23:0] idx_addr,
    output reg [ 2:0] idx_len,
    output reg        data_sel,

    output reg [31:0] data_latch,

    // RFP
    output reg        inc_rfp,
    output reg        dec_rfp,
    output reg        rfp_we,

    // ALU control
    output reg [31:0] alu_imm,
    output reg [ 5:0] alu_op,
    output reg        alu_smux,
    output reg        alu_wait,
    input      [ 7:0] flags,
    output reg        flag_we, // instructions that only affect the flags
    input             djnz,

    input      [31:0] op,
    input             op_ok,

    output reg [ 2:0] regs_we,
    output reg [ 7:0] regs_dst,
    output reg [ 7:0] regs_src
);

localparam [4:0] FETCH    = 5'd0,
                 IDX      = 5'd1,
                 LD_RAM   = 5'd2,
                 EXEC     = 5'd3,
                 FILL_IMM = 5'd4,
                 ST_RAM   = 5'd5,
                 DUMMY    = 5'd6,
                 DJNZ     = 5'd7,
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
reg  [2:0] nx_regs_we, nx_idx_len,
           nx_keep_we, keep_we;
reg        nx_alu_smux, nx_alu_wait,
           nx_ram_ren, nx_ram_wen,
           nx_idx_en, nx_data_sel;
reg [31:0] nx_alu_imm, nx_data_latch;
reg  [5:0] nx_alu_op;
reg        nx_inc_rfp, nx_dec_rfp,
           nx_nodummy_fetch, nodummy_fetch,
           nx_goexec, goxec,
           nx_exec_imm, exec_imm,
           nx_pc_we, nx_pc_rel,
           nx_keep_pc_we, keep_pc_we,
           nx_rfp_we,
           nx_was_load, was_load,
           nx_flag_we;
reg  [1:0] nx_dly_fetch, dly_fetch;         // fetch update to be run later

reg  [1:0] op_zz, nx_op_zz;
reg        ram_wait, nx_ram_wait, latch_op, req_wait;
reg        bad_zz;

`ifdef SIMULATION
wire [31:0] op_rev = {op[7:0],op[15:8],op[23:16],op[31:24]};
`endif

function [2:0] expand_zz(input [1:0] zz);
    expand_zz = zz==0 ? 3'b001 : zz==1 ? 3'b010 : 3'b100;
endfunction

function [7:0] expand_reg(input [2:0] short_reg, input [1:0] zz );
    expand_reg = zz==0 ?       {4'he, short_reg[2:1], 1'b0, ~short_reg[0]} :
                short_reg[2] ? {4'hf,  short_reg[1:0],2'd0  } :
                               {4'he, {short_reg[1:0],2'd0} };
endfunction

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
    nx_pc_we         = op_phase==FETCH ? 0 : pc_we;
    nx_pc_rel        = 0;
    nx_keep_pc_we    = keep_pc_we;
    nx_rfp_we        = 0;
    nx_was_load      = was_load;
    nx_flag_we       = flag_we;
    nx_idx_len       = idx_len;
    nx_data_sel      = data_sel;
    nx_dly_fetch     = dly_fetch;
    bad_zz           = op_zz == 2'b11;
    if(op_ok && !ram_wait) case( op_phase )
        FETCH: begin
            `ifdef SIMULATION
            //$display("Fetched %04X_%04X", {op[7:0],op[15:8]},{op[23:16],op[31:24]});
            `endif
            nx_alu_op   = ALU_NOP;
            nx_alu_smux = 0;
            nx_alu_wait = 0;
            nx_regs_we  = 0;
            nx_idx_len  = 0;
            nx_data_sel = 0;
            nx_keep_we  = 0;
            nx_exec_imm = 0;
            nx_pc_we    = 0;
            nx_was_load = 0;
            nx_goexec   = 0;
            nx_dly_fetch= 0;
            nx_flag_we  = 0;
            casez( op[7:0] )
                8'b0000_0000: begin // NOP
                    fetched = 1;
                end
                8'b10??_????,
                8'b11??_00??,
                8'b11??_010?: begin // start indexed addressing
                    latch_op = 1;
                    nx_phase = IDX;
                    nx_op_zz = op[5:4];
                    nx_idx_en= 1;
                    fetched  = 0; // let the indexation module take control
                end
                8'b11??_1???: begin // two register operand instruction, r part
                    nx_op_zz = op[5:4];
                    nx_dst   = expand_reg(op[2:0], nx_op_zz);
                    nx_src   = nx_dst;
                    nx_phase = EXEC;
                    fetched  = 1;
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
                8'b0001_0111: begin // LDF - LoaD register File pointer
                    nx_rfp_we  = 1;
                    nx_alu_imm = { 24'd0, op[15:8] };
                    fetched    = 2;
                end
                8'b0010_0???,   // byte
                8'b0011_0???,   // word
                8'b0100_0???:   // long word
                begin // LD R,# 0zzz_0RRR, register and immediate value
                    if( op[7:0]==0 ) begin
                        fetched = 1; // NOP
                    end else begin
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
                end
                8'b0001_101?: begin // JP 16/24-bit immediate value
                    fetched       = 2;
                    nx_alu_imm    = { 24'd0, op[15:8] };
                    nx_op_zz      = !op[0] ? 2'd1: 2'd3; // 3 = special case to load 24 bits
                    nx_phase      = FILL_IMM;
                    nx_keep_pc_we = 1;
                end
                8'b0000_1100: begin
                    nx_inc_rfp = 1;
                    fetched    = 1;
                end
                8'b0000_1101: begin
                    nx_dec_rfp = 1;
                    fetched    = 1;
                end
                default:;
            endcase
        end
        IDX: if( idx_ok ) begin
            nx_idx_en = 0;
            // leave the fetched update to the next state
            // either LD_RAM or ST_RAM
            casez( {op[7:0], op_zz==2'b11} )
                9'b001?_0???_?: begin // LD   R,(mem) 0010_0RRR
                                    // LDA  R,mem   001s_0RRR, but first half had zz==11
                    if( op_zz==2'b11 ) begin // LDA
                        nx_regs_we  = op[4] ? 3'b100 : 3'b010;
                        nx_dst      = expand_reg(op[2:0],op[4] ? 2'b10 : 2'b01);
                        nx_alu_imm  = { 8'd0, idx_addr };
                        nx_alu_op   = ALU_MOVE;
                        nx_alu_smux = 1;
                        nx_phase    = DUMMY;
                    end else begin // LD
                        nx_phase    = LD_RAM;
                        nx_dst      = expand_reg(op[2:0],op_zz);
                        nx_keep_we  = expand_zz( op_zz );
                        nx_ram_ren = 1;
                    end
                end
                9'b01??_0???_1: begin // LD (mem),R
                    nx_phase = EXEC;
                    nx_was_load = 1;
//                    nx_phase    = ST_RAM;
//                    nx_op_zz    = op[5:4];
//                    nx_src      = expand_reg(op[2:0],nx_op_zz);
//                    nx_idx_len  = expand_zz( nx_op_zz );
//                    nx_ram_wen = 1;
//                    req_wait    = 1;
                end
                9'b1101_????_1: begin // JP cc,mem
                    nx_alu_imm  = { 8'd0, idx_addr };
                    case( op[3:0] ) // conditions
                        0: nx_pc_we = 0;    // false
                        1: nx_pc_we = flags[FS]^flags[FV];               // signed <
                        2: nx_pc_we = flags[FZ] | (flags[FS]^flags[FV]); // signed <=
                        3: nx_pc_we = flags[FZ] | flags[FC];             // <=
                        4: nx_pc_we = flags[FV];  // overflow
                        5: nx_pc_we = flags[FS];  // minux
                        6: nx_pc_we = flags[FZ];  // =
                        7: nx_pc_we = flags[FC];  // carry
                        8: nx_pc_we = 1;          // true
                        9: nx_pc_we = ~(flags[FS]^flags[FV]); // >=
                        10: nx_pc_we = ~(flags[FZ]|(flags[FS]^flags[FV])); // signed >
                        11: nx_pc_we = ~(flags[FZ]|flags[FC]); // >
                        12: nx_pc_we = ~flags[FV];
                        13: nx_pc_we = ~flags[FS];
                        14: nx_pc_we = ~flags[FZ];
                        15: nx_pc_we = ~flags[FC];
                    endcase
                    nx_phase    = DUMMY;
                end
                //8'b1100_0???, // CHG #3,(mem)
                9'b1100_1???_?: begin // BIT #3,(mem)
                    nx_phase    = LD_RAM;
                    nx_ram_ren = 1;
                    nx_goexec   = 1;
                end
                default: begin // load operand from memory
                    nx_phase  = LD_RAM;
                    nx_ram_ren = 1;
                    nx_goexec = 1;
                    nx_dst    = expand_reg(op[2:0],op_zz);
                    nx_src    = nx_dst;
                end
            endcase
        end
        DUMMY: begin
            if( !nodummy_fetch ) fetched = 1;
            nx_nodummy_fetch = 0;
            nx_alu_op  = ALU_NOP;
            nx_regs_we = keep_we;
            if( keep_we!=0 ) nx_flag_we = flag_we;
            nx_phase   = FETCH;
        end
        LD_RAM: begin
            if( goxec ) begin
                nx_phase    = EXEC;
                nx_was_load = 1;
                nx_exec_imm = 1;
                // no change to fetched because we will
                // reuse the last OP code byte
            end else begin
                nx_phase    = FETCH;
                nx_data_sel = 1; // copy the RAM output
                fetched = 1;  // this will set the RAM wait flag too
            end
            nx_regs_we  = keep_we;
            nx_ram_ren = 0;
            nx_data_latch = op; // is it necessary to have it in data_latch
                                // and alu_imm?
            nx_alu_imm    = op; // make it available to the ALU too
        end
        ST_RAM: begin
            nx_phase   = FETCH;
            nx_ram_wen = 1;
            nx_idx_len = regs_we;
            fetched    = dly_fetch;  // this will set the RAM wait flag too
            nx_dly_fetch = 0;
        end
        DJNZ: begin
            nx_alu_imm = { 24'd0, op[7:0] };
            nx_pc_rel  = !djnz;
            fetched    = 1;
            nx_phase   = DUMMY;
            nx_nodummy_fetch = 1;
        end
        EXEC: begin // second half of op-code decoding
            nx_phase = FETCH;
            casez( { op[7:0], was_load, bad_zz } )
                10'b1???_1???_11: begin // Arithmetic on memory (mem), R
                    // 9'b1100_1???_1 BIT #3,(mem), only byte length
                    // 9'b1001_1???_1 LDCF #3,(mem)
                    // 9'b1000_1???_1 ORCF #3,(mem)
                    case( op[6:4] )
                        3'b100: nx_alu_op = ALU_BITX;
                        3'b001: nx_alu_op = ALU_LDCFX;
                        3'b000: nx_alu_op = ALU_ORCFX;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_alu_imm[10:8] = op[2:0];
                    nx_flag_we  = 1;
                    fetched = 1;
                end
                10'b1???_1???_10: begin // arithmetic to memory
                    nx_src       = regs_dst;
                    case( op[6:4] )
                        3'b110:  nx_alu_op = ALU_OR;
                        3'b101:  nx_alu_op = ALU_XOR;
                        3'b100:  nx_alu_op = ALU_AND;
                        3'b011:  nx_alu_op = ALU_SBC;
                        3'b010:  nx_alu_op = ALU_SUB;
                        3'b001:  nx_alu_op = ALU_ADC;
                        3'b000:  nx_alu_op = ALU_ADD;
                        // 3'b111:  nx_alu_op = ALU_CP;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    nx_regs_we   = expand_zz( op_zz );
                    nx_flag_we   = 1;
                    nx_alu_smux  = 1;
                    nx_dly_fetch = 1;
                    nx_phase     = ST_RAM;
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
                10'b0000_0111_??, // NEG dst
                10'b0000_0110_??: begin // CPL dst
                    nx_regs_we = expand_zz( op_zz );
                    case( op[2:0] )
                        3'b110: nx_alu_op  = ALU_CPL;
                        3'b111: nx_alu_op  = ALU_NEG;
                        default: nx_alu_op = ALU_NOP;
                    endcase
                    fetched    = 1;
                end
                10'b0001_0110_??: begin // MIRR
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
                10'b0011_0010_??: begin // CHG #4,dst
                    nx_alu_imm = { 28'd0,op[11:8] };
                    nx_alu_op   = ALU_CHG;
                    nx_regs_we  = expand_zz( op_zz );
                    nx_alu_smux = 1;
                    fetched     = 2;
                end
                10'b0011_0011_??: begin // BIT #4,r
                    nx_alu_imm = { 28'd0,op[11:8] };
                    nx_alu_op   = ALU_BIT;
                    nx_alu_smux = 1;
                    nx_flag_we  = 1;
                    fetched     = 2;
                end
                10'b0010_?011_0?, // LDCF #4,r   - A,r
                10'b0010_?010_0?, // XORCF #4,r  - A,r
                10'b0010_?001_0?, // ORCF #4,r   - A,r
                10'b0010_?000_0?: // ANDCF #4,r  - A,r
                begin
                    nx_alu_imm = { 28'd0,op[11:8] };
                    nx_src      = 8'he0;    // A
                    if( !op[3] ) begin
                        nx_alu_smux = 1;
                        fetched     = 2;
                    end else begin
                        fetched     = 1;
                    end
                    case( op[1:0] )
                        0: nx_alu_op = ALU_ANDCF;
                        1: nx_alu_op = ALU_ORCF;
                        2: nx_alu_op = ALU_XORCF;
                        3: nx_alu_op = ALU_LDCF;
                    endcase
                    nx_flag_we = 1;
                    nx_regs_we = expand_zz( op_zz );
                end
                10'b0010_1000_1?, // ANDCF A,(mem)
                10'b0010_1001_1?, // ORCF A,(mem)
                10'b0010_1010_1?, // XORCF A,(mem)
                10'b0010_1011_1?: // LDCF A,(mem)
                begin
                    nx_src = 8'hE0;
                    case(op[1:0])
                        0: nx_alu_op = ALU_ANDCFA;
                        1: nx_alu_op = ALU_ORCFA;
                        2: nx_alu_op = ALU_XORCFA;
                        3: nx_alu_op = ALU_LDCFA;
                    endcase
                    nx_flag_we = 1;
                    nx_regs_we = 1;
                    fetched    = 1;
                end
                10'b01??_0???_11: begin // LD (mem),R
                    nx_alu_op = ALU_MOVE;
                    nx_src    = expand_reg(op[2:0],op[5:4]);
                    nx_regs_we = expand_zz( op[5:4] );
                    nx_flag_we = 1;
                    nx_dly_fetch = 1;
                    nx_phase     = ST_RAM;
                end
                10'b0110_0???_?0, // INC #3, dst
                10'b0110_1???_?0: // DEC #3, dst
                begin
                    nx_regs_we  = expand_zz( op_zz );
                    nx_alu_smux = 1;
                    if( was_load ) begin
                        nx_alu_imm[23:16] = { 5'd0, op[2:0] };
                        nx_alu_op   = op[3] ? ALU_DECX : ALU_INCX;
                        nx_dly_fetch = 1;
                        nx_flag_we   = 1;
                        nx_phase     = ST_RAM;
                    end else begin
                        nx_alu_imm = { 29'd0, op[2:0] };
                        nx_alu_op  = op[3] ? ALU_DEC : ALU_INC;
                        fetched    = 1;
                    end
                end
                10'b0000_111?_??: begin // BS1B, BS1F
                    nx_alu_op  = op[0] ? ALU_BS1B : ALU_BS1F;
                    nx_dst     = 8'hE0;
                    nx_regs_we = expand_zz( op_zz );
                    fetched    = 1;
                end
                10'b0001_001?_??: begin // EXTS, EXTZ
                    nx_alu_op  = op[0] ? ALU_EXTS : ALU_EXTZ;
                    nx_regs_we = expand_zz( op_zz );
                    fetched    = 1;
                end
                10'b0011_1100_??, // MDEC1
                10'b0011_1101_??, // MDEC2
                10'b0011_1110_??, // MDEC4
                10'b0000_0011_??: // LD r,#
                begin
                    nx_alu_op   = op[7:0] == 8'b0000_0011 ? ALU_MOVE  :
                                  op[7:0] == 8'b0011_1100 ? ALU_MDEC1 :
                                  op[7:0] == 8'b0011_1101 ? ALU_MDEC2 :
                                  op[7:0] == 8'b0011_1110 ? ALU_MDEC4 :
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
                10'b1001_0???_11, // XORCF #3,(mem)
                10'b1000_0???_11: // ANDCF #3,(mem)
                begin
                    case(op[4])
                        1: nx_alu_op = ALU_XORCFX;
                        0: nx_alu_op = ALU_ANDCFX;
                    endcase
                    nx_alu_imm[10:8] = op[2:0];
                    nx_regs_we       = expand_zz( op_zz );
                    nx_flag_we       = 1;
                    nx_alu_smux      = 1;   // not really needed, left for consistency
                    fetched          = 1;
                end
                10'b1111_0???_??, // CP  R,r
                10'b1110_0???_??, // OR  R,r
                10'b1101_0???_??, // XOR R,r
                10'b1100_0???_??, // AND R,r
                10'b1010_0???_??, // SUB R,r
                10'b100?_0???_?0: // ADD R,r
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
                default:;
            endcase
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
            endcase
        end
        default: nx_phase=ILLEGAL;
    endcase
    // leave this at the bottom
    nx_ram_wait = fetched!=0 || req_wait;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        //illegal  <= 0;
        op_phase <= FETCH;
        idx_en   <= 0;
        regs_src <= 0;
        regs_dst <= 0;
        alu_op   <= 0;
        alu_imm  <= 0;
        alu_smux <= 0;
        alu_wait <= 0;
        ram_ren <= 0;
        op_zz    <= 0;
        regs_we  <= 0;
        keep_we  <= 0;
        ram_wait <= 0;
        last_op  <= 0;
        ram_wen <= 0;
        idx_len  <= 0;
        data_sel <= 0;
        data_latch <= 0;
        nodummy_fetch <= 0;
        goxec    <= 0;
        exec_imm <= 0;
        keep_pc_we <= 0;
        pc_we    <= 0;
        pc_rel   <= 0;
        rfp_we   <= 0;
        was_load <= 0;
        flag_we  <= 0;
        dly_fetch<= 0;
    end else if(cen) begin
        op_phase <= nx_phase;
        idx_en   <= nx_idx_en;
        regs_src <= nx_src;
        regs_dst <= nx_dst;
        alu_op   <= nx_alu_op;
        alu_imm  <= nx_alu_imm;
        alu_smux <= nx_alu_smux;
        alu_wait <= nx_alu_wait;
        ram_ren  <= nx_ram_ren;
        ram_wen  <= nx_ram_wen;
        op_zz    <= nx_op_zz;
        regs_we  <= nx_regs_we;
        ram_wait <= nx_ram_wait;
        idx_len  <= nx_idx_len;
        data_sel <= nx_data_sel;
        data_latch <= nx_data_latch;
        inc_rfp  <= nx_inc_rfp;
        dec_rfp  <= nx_dec_rfp;
        keep_we  <= nx_keep_we;
        nodummy_fetch <= nx_nodummy_fetch;
        goxec    <= nx_goexec;
        exec_imm <= nx_exec_imm;
        keep_pc_we <= nx_keep_pc_we;
        pc_we    <= nx_pc_we;
        pc_rel   <= nx_pc_rel;
        rfp_we   <= nx_rfp_we;
        was_load <= nx_was_load;
        flag_we  <= nx_flag_we;
        dly_fetch<= nx_dly_fetch;
        if( latch_op ) last_op <= op[7:0];
    end
end

endmodule