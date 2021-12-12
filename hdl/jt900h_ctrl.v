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

    output reg [ 1:0] fetched,    // number of bytes consumed

    output reg        ldram_en,
    output reg        stram_en,
    output reg        idx_en,
    input             idx_ok,
    input      [23:0] idx_addr,
    output reg [ 2:0] idx_len,
    output reg        data_sel,

    output reg [31:0] data_latch,

    // RFP
    output reg        inc_rfp,
    output reg        dec_rfp,

    // ALU control
    output reg [31:0] alu_imm,
    output reg [ 5:0] alu_op,
    output reg        alu_smux,
    output reg        alu_wait,

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
                 ILLEGAL  = 5'd31;

`include "jt900h.inc"

reg  [4:0] op_phase, nx_phase;
//reg        illegal;
reg  [7:0] last_op;
reg  [7:0] nx_src, nx_dst;
reg  [2:0] nx_regs_we, nx_idx_len,
           nx_keep_we, keep_we;
reg        nx_alu_smux, nx_alu_wait,
           nx_ldram_en, nx_stram_en,
           nx_idx_en, nx_data_sel;
reg [31:0] nx_alu_imm, nx_data_latch;
reg  [5:0] nx_alu_op;
reg        nx_inc_rfp, nx_dec_rfp,
           nx_nodummy_fetch, nodummy_fetch,
           nx_goexec, goxec,
           nx_exec_imm, exec_imm;

reg  [1:0] op_zz, nx_op_zz;
reg        ram_wait, nx_ram_wait, latch_op, req_wait;

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
    fetched     = 0;
    nx_phase    = op_phase;
    nx_idx_en   = idx_en;
    nx_src      = regs_src;
    nx_dst      = regs_dst;
    nx_alu_op   = alu_op;
    nx_alu_imm  = alu_imm;
    nx_alu_smux = alu_smux;
    nx_alu_wait = alu_wait;
    nx_ldram_en = ldram_en;
    nx_stram_en = stram_en;
    nx_op_zz    = op_zz;
    nx_regs_we  = 0;
    nx_keep_we  = keep_we;
    latch_op    = 0;
    req_wait    = 0;
    nx_data_latch = data_latch;
    nx_inc_rfp  = 0;
    nx_dec_rfp  = 0;
    nx_nodummy_fetch = nodummy_fetch;
    nx_goexec   = goxec;
    nx_exec_imm = exec_imm;
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
            casez( op[7:0] )
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
                    nx_phase = EXEC;
                    fetched  = 1;
                end
                8'b11??_0111: begin // two operand, r with arbitraty register
                    nx_op_zz = op[5:4];
                    nx_dst   = op[15:8];
                    fetched  = 2;
                    nx_phase = EXEC;
                end
                8'b0???_0???: begin // LD R,# 0zzz_0RRR, register and immediate value
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
                8'b0000_1100: begin
                    nx_inc_rfp = 1;
                    fetched = 1;
                end
                8'b0000_1101: begin
                    nx_dec_rfp = 1;
                    fetched = 1;
                end
                default:;
            endcase
        end
        IDX: if( idx_ok ) begin
            nx_idx_en = 0;
            // leave the fetched update to the next state
            // either LD_RAM or ST_RAM
            casez( op[7:0] )
                8'b001?_0???: begin // LD   R,(mem) 0010_0RRR
                                    // LDA  R,mem   001s_0RRR, but first half had zz==11
                    if( op_zz==2'b11 ) begin // LDA
                        nx_regs_we  = op[4] ? 3'b100 : 3'b010;
                        nx_dst      = expand_reg(op[2:0],op[4] ? 2'b10 : 2'b01);
                        nx_alu_imm  = { 8'd0, idx_addr };
                        nx_alu_op   = ALU_MOVE;
                        nx_phase    = DUMMY;
                    end else begin // LD
                        nx_phase    = LD_RAM;
                        nx_dst      = expand_reg(op[2:0],op_zz);
                        nx_keep_we  = expand_zz( op_zz );
                        nx_ldram_en = 1;
                    end
                end
                8'b01??_0???: begin // LD (mem),R
                    nx_phase    = ST_RAM;
                    nx_op_zz    = op[5:4];
                    nx_src      = expand_reg(op[2:0],nx_op_zz);
                    nx_idx_len  = expand_zz( nx_op_zz );
                    nx_stram_en = 1;
                    req_wait    = 1;
                end
                8'b100?_0???, // ADD R,(mem) - ADC R,(mem)
                8'b1100_0???: // AND R,(mem)
                begin
                    nx_phase  = LD_RAM;
                    nx_ldram_en = 1;
                    nx_goexec = 1;
                end
                default: nx_phase = ILLEGAL;
            endcase
        end
        DUMMY: begin
            if( !nodummy_fetch ) fetched = 1;
            nx_nodummy_fetch = 0;
            nx_alu_op  = ALU_NOP;
            nx_regs_we = keep_we;
            nx_phase   = FETCH;
        end
        LD_RAM: begin
            if( goxec ) begin
                nx_phase    = EXEC;
                nx_exec_imm = 1;
                // no change to fetched because we will
                // reuse the last OP code byte
            end else begin
                nx_phase    = FETCH;
                nx_data_sel = 1; // copy the RAM output
                fetched = 1;  // this will set the RAM wait flag too
            end
            nx_regs_we  = keep_we;
            nx_ldram_en = 0;
            nx_data_latch = op; // is it necessary to have it in data_latch
                                // and alu_imm?
            nx_alu_imm    = op; // make it available to the ALU too
        end
        ST_RAM: begin
            nx_phase    = FETCH;
            nx_stram_en = 0;
            nx_idx_len  = 0;
            fetched     = 1;  // this will set the RAM wait flag too
        end
        EXEC: begin // second half of op-code decoding
            nx_phase = FETCH;
            casez( op[7:0] )
                8'b1000_1???: begin // LD R,r
                    nx_src = regs_dst;
                    nx_dst = expand_reg(op[2:0],op_zz);
                    nx_alu_op   = ALU_MOVE;
                    fetched = 1;
                end
                8'b1001_1???: begin // LD r,R
                    nx_src = expand_reg(op[2:0],op_zz);
                    nx_alu_op   = ALU_MOVE;
                    fetched = 1;
                end
                8'b1010_1???: begin
                    nx_alu_imm  = {29'd0,op[2:0]};
                    nx_alu_op   = ALU_MOVE;
                    nx_alu_smux = 1;
                    fetched     = 1;
                    nx_regs_we  = expand_zz( op_zz );
                    // nx_phase    = DUMMY;
                end
                8'b0000_0011: begin // LD r,#
                    nx_alu_op   = ALU_MOVE;
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
                8'b100?_0???, // ADD R,r
                8'b1100_0???: // AND R,r
                begin
                    nx_keep_we  = expand_zz( op_zz );
                    nx_src      = regs_dst; // swap R, r
                    nx_dst      = expand_reg(op[2:0],op_zz);
                    nx_alu_op   =
                        op[7:3] == 5'b1000_0 ? ALU_ADD :
                        op[7:3] == 5'b1001_0 ? ALU_ADC :
                        op[7:3] == 5'b1100_0 ? ALU_AND :
                        ALU_NOP;
                    nx_regs_we  = expand_zz( op_zz );
                    nx_phase    = DUMMY;
                    if( exec_imm )
                        nx_alu_smux = 1;
                end
                8'b1100_1000, // ADD r,#
                8'b1100_1100: // AND r,#
                begin
                    nx_alu_op   = op[7:0]==8'b1100_1000 ? ALU_ADD :
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
                end
                default:;
            endcase
        end
        FILL_IMM: begin
            nx_alu_wait = 0;
            nx_phase = FETCH;
            nx_regs_we = keep_we;
            if( op_zz == 1 ) begin
                nx_alu_imm[31:16] = 0;
                nx_alu_imm[15:8] = op[7:0];
                fetched = 1;
            end else begin
                nx_alu_imm[31:8] = op[23:0];
                fetched = 3;
            end
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
        ldram_en <= 0;
        op_zz    <= 0;
        regs_we  <= 0;
        keep_we  <= 0;
        ram_wait <= 0;
        last_op  <= 0;
        stram_en <= 0;
        idx_len  <= 0;
        data_sel <= 0;
        data_latch <= 0;
        nodummy_fetch <= 0;
        goxec    <= 0;
        exec_imm <= 0;
    end else if(cen) begin
        op_phase <= nx_phase;
        idx_en   <= nx_idx_en;
        regs_src <= nx_src;
        regs_dst <= nx_dst;
        alu_op   <= nx_alu_op;
        alu_imm  <= nx_alu_imm;
        alu_smux <= nx_alu_smux;
        alu_wait <= nx_alu_wait;
        ldram_en <= nx_ldram_en;
        stram_en <= nx_stram_en;
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
        if( latch_op ) last_op <= op[7:0];
    end
end

endmodule