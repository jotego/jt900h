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
    output reg        idx_en,
    input             idx_ok,

    // ALU control
    output reg [31:0] alu_imm,
    output reg [ 5:0] alu_op,
    output reg        alu_smux,
    output reg        alu_wait,

    input      [31:0] op,
    input             op_ok,

    output reg [ 2:0] regs_we,
    output reg [ 7:0] regs_dst
);

localparam [4:0] FETCH    = 5'd0,
                 IDX      = 5'd1,
                 LD_RAM   = 5'd2,
                 EXEC     = 5'd3,
                 FILL_IMM = 5'd4;

localparam [5:0] ALU_NOP  = 6'd0,
                 ALU_MOVE = 6'd1;

reg  [4:0] op_phase, nx_phase;
//reg        illegal;
reg  [7:0] last_op;
wire [2:0] expand_zz;
reg  [7:0] regs_src, nx_src, nx_dst;
reg  [2:0] nx_regs_we;
reg        nx_alu_smux, nx_alu_wait,
           nx_ldram_en, nx_idx_en;
reg [31:0] nx_alu_imm;
reg  [5:0] nx_alu_op;

reg  [1:0] op_zz, nx_op_zz;
reg        ram_wait;

assign expand_zz = last_op[5:4]==0 ? 3'd0 : last_op[5:4]==1 ? 3'd1 : 3'd2;

function [7:0] expand_reg(input [2:0] short_reg );
    expand_reg = short_reg[2] ? {4'hf,  short_reg[1:0],2'd0  } :
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
    nx_op_zz    = op_zz;
    if(op_ok && !ram_wait) case( op_phase )
        FETCH: begin
            nx_alu_op = ALU_NOP;
            casez( op[7:0] )
                8'h0: fetched = 1; // NOP
                8'b10??_????,
                8'b11??_00??,
                8'b11??_010?: begin // start indexed addressing
                    nx_phase = IDX;
                    nx_idx_en= 1;
                end
                8'b11??_1???: begin // two register operand instruction, r part
                    nx_dst   = expand_reg(op[ 2:0]);
                    nx_op_zz = op[5:4];
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
                    nx_dst      = expand_reg(op[ 2:0]);
                    nx_op_zz    = op[6:4]==2 ? 2'd0 : op[6:4]==3 ? 2'd1 : 2'd2;
                    nx_alu_imm  = { 24'd0, op[15:8] };
                    nx_alu_op   = ALU_MOVE;
                    nx_alu_smux = 1;
                    fetched     = 2;
                    if( nx_op_zz!=0 ) begin
                        nx_phase = FILL_IMM;
                        nx_alu_wait = 1;
                    end else begin
                        nx_phase = FETCH;
                    end
                end
                default:;
            endcase
        end
        IDX: if( idx_ok ) begin
            nx_idx_en = 0;
            casez( op[7:0] )
                8'b0010_0???: begin // LD R,(mem)
                    nx_phase    = LD_RAM;
                    nx_ldram_en = 1;
                    nx_regs_we  = expand_zz;
                    nx_dst      = expand_reg(op[2:0]);
                end
                default:;
            endcase
        end
        LD_RAM: begin
            nx_phase = FETCH;
            fetched    = 1;
        end
        EXEC: begin // second half of op-code decoding
            nx_phase = FETCH;
            casez( op[7:0] )
                8'b1000_1???: begin // LD R,r
                    nx_src = regs_dst;
                    nx_dst = expand_reg(op[2:0]);
                    nx_alu_op   = ALU_MOVE;
                    fetched = 1;
                end
                8'b1001_1???: begin // LD r,R
                    nx_src = expand_reg(op[2:0]);
                    nx_alu_op   = ALU_MOVE;
                    fetched = 1;
                end
                8'b1010_1???: begin
                    nx_alu_imm  = {29'd0,op[2:0]};
                    nx_alu_op   = ALU_MOVE;
                    nx_alu_smux = 1;
                    fetched = 1;
                end
                8'b0000_0011: begin // LD r,#
                    nx_alu_op   = ALU_MOVE;
                    nx_alu_smux = 1;
                    fetched     = 2;
                    if( nx_op_zz==0 ) begin
                        nx_alu_imm = {24'd0,op[15:8]};
                    end else begin
                        nx_alu_imm[7:0] = op[15:8];
                        nx_alu_wait = 1;
                        nx_phase = FILL_IMM;
                    end
                end
                default:;
            endcase
        end
        FILL_IMM: begin
            nx_alu_wait = 0;
            nx_phase = FETCH;
            if( op_zz == 1 ) begin
                nx_alu_imm[31:16] = 0;
                nx_alu_imm[15:8] = op[7:0];
                fetched = 1;
            end else begin
                nx_alu_imm[31:8] = op[23:0];
                fetched = 3;
            end
        end
        default:;
    endcase
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
        ram_wait <= 0;
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
        op_zz    <= nx_op_zz;
        regs_we  <= nx_regs_we;
        ram_wait <= fetched!=0;
    end
end

endmodule