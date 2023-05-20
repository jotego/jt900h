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
    Date: 2-12-2021 */

module jt900h_idxaddr(
    input             rst,
    input             clk,
    input             cen,

    input      [31:0] op,
    input             use_last,
    input             idx_en,
    output reg [ 2:0] fetched,
    // To register bank
    // index register
    output reg [ 7:0] idx_rdreg_sel,
    input      [31:0] idx_rdreg,
    input      [31:0] idx_auxreg,
    output reg [ 1:0] reg_step,
    output reg        reg_inc,
    output reg        reg_dec,
    input             ldd_write,
    // offset register
    output reg [ 7:0] idx_rdreg_aux,
    input      [15:0] idx_rdaux,

    output reg        ldar,
    output reg        idx_ok,
    output reg [23:0] idx_addr
);

localparam [7:0] NULL=8'h40;

reg  [23:0] nx_idx_offset, idx_offset, aux24, nx_idx_addr;
reg  [ 1:0] ridx_mode, nx_ridx_mode,
            nx_reg_step;
reg         nx_xdehl_dec;
reg  [ 4:0] mode, nx_mode;
reg  [ 7:0] nx_idx_rdreg_sel, nx_idx_rdreg_aux;
reg         nx_reg_dec, nx_reg_inc,
            nx_pre_inc, pre_inc,
            nx_was_CPI, was_CPI,
            nx_was_CPD, was_CPD,
            nx_was_LDD, was_LDD,
            nx_was_LDI, was_LDI;
reg  [ 7:0] nx_opl, opl;
reg         phase, nx_phase, nx_pre_ok, pre_ok, nx_ldar;
wire [31:0] eff_op;
wire        is_LDD, is_LDI, is_CPD, is_CPI;
reg  [ 2:0] nx_pre_offset, pre_offset;

assign eff_op = {op[31:8], use_last ? opl: op[7:0] };
// ignore the op LSB so it matches LDDR/CPDR/CPIR too
assign is_LDD = use_last ? was_LDD : eff_op[5:4]!=2'b11 && !eff_op[3] && eff_op[15:9]==7'h13>>1;
assign is_LDI = use_last ? was_LDI : eff_op[5:4]!=2'b11 && !eff_op[3] && eff_op[15:9]==7'h10>>1;
assign is_CPD = use_last ? was_CPD : eff_op[5:4]!=2'b11 && !eff_op[3] && eff_op[15:9]==7'h16>>1;
assign is_CPI = use_last ? was_CPI : eff_op[5:4]!=2'b11 && !eff_op[3] && eff_op[15:9]==7'h14>>1;

always @* begin
    aux24 = ridx_mode[0] ? { {8{idx_rdaux[15]}}, idx_rdaux} : { {16{idx_rdaux[7]}}, idx_rdaux[7:0]};
end

function [7:0] fullreg;
    input [2:0] rcode;
    fullreg = rcode==0 ? 8'he0 : // XWA
              rcode==1 ? 8'he4 : // XBC
              rcode==2 ? 8'he8 : // XDE
              rcode==3 ? 8'hec : // XHL
              rcode==4 ? 8'hf0 : // XIX
              rcode==5 ? 8'hf4 : // XIY
              rcode==6 ? 8'hf8 : // XIZ
                         8'hfc;  // XSP
endfunction

always @* begin
    if( nx_reg_dec && !(is_LDD || is_CPD))
        case( nx_reg_step )
            0: nx_pre_offset = 1;
            1: nx_pre_offset = 2;
            2: nx_pre_offset = 4;
            default: nx_pre_offset = 0;
        endcase
    else
        nx_pre_offset = 0;
end

always @* begin
    fetched          = 0;
    nx_mode          = {op[6],op[3:0]};
    nx_ridx_mode     = 0;
    nx_reg_step      = reg_step;
    nx_reg_inc       = pre_inc;
    nx_pre_inc       = 0;
    nx_reg_dec       = 0;
    nx_idx_offset    = idx_offset;
    nx_idx_rdreg_sel = idx_rdreg_sel;
    nx_phase         = 0;
    nx_pre_ok        = pre_ok & idx_en;
    nx_ldar          = ldar & idx_en;
    nx_idx_addr      = idx_en && !idx_ok ?
        (idx_rdreg[23:0] - {20'd0,pre_offset} + (ridx_mode[1] ?  aux24 : idx_offset)) :
        ldd_write ? idx_auxreg[23:0] : idx_addr;
    nx_idx_rdreg_aux = idx_rdreg_aux;
    nx_opl           = opl;
    nx_was_LDD       = was_LDD;
    nx_was_LDI       = was_LDI;
    nx_was_CPD       = was_CPD;
    nx_was_CPI       = was_CPI;
    if( idx_en && !pre_ok ) begin
        nx_pre_ok  = 0;
        nx_was_LDD = 0;
        nx_was_LDI = 0;
        if( !phase ) begin
            fetched    = 2;
            nx_reg_step= op[9:8];
            casez( {eff_op[6],eff_op[3:0]} ) // See 900H_CPU_BOOK_CP3.pdf Page 43
                5'b0_????: begin // this section may operate with the previous op
                    nx_idx_rdreg_sel = fullreg(eff_op[2:0]);
                    nx_idx_offset    = eff_op[3] ? { {16{eff_op[15]}}, eff_op[15:8] } : 24'd0;
                    nx_pre_ok        = 1;
                    nx_reg_dec       = is_CPD || is_LDD;
                    nx_reg_inc       = is_CPI || is_LDI;
                    nx_was_LDD       = use_last ? was_LDD : is_LDD;
                    nx_was_LDI       = use_last ? was_LDI : is_LDI;
                    nx_was_CPD       = use_last ? was_CPD : is_CPD;
                    nx_was_CPI       = use_last ? was_CPI : is_CPI;
                    nx_reg_step      = {1'b0,eff_op[4]};
                    nx_opl           = use_last ? opl : op[7:0]; // remember it, in case we are in a LDD instruction
                    fetched          = use_last ? 0 : eff_op[3] ? 3'd2: 3'd1;
                end
                5'h10,5'h11,5'h12: begin // memory address as immediate data
                    nx_idx_rdreg_sel = NULL;
                    case( op[1:0] )
                        0: begin
                            nx_idx_offset = { 16'd0, op[15:8] };
                            fetched       = 2;
                        end
                        1: begin
                            nx_idx_offset = {  8'd0, op[23:8] };
                            fetched       = 3;
                        end
                        default: begin
                            nx_idx_offset = op[31:8];
                            fetched       = 4;
                        end
                    endcase
                    nx_pre_ok = 1;
                end
                5'h13: begin
                    if( op[15:0]==16'h13f3 ) begin // LDAR
                        nx_idx_rdreg_sel = NULL;
                        nx_idx_offset    = { 8'd0, op[31:16] };
                        fetched          = 4;
                        nx_ldar          = 1;
                        nx_pre_ok        = 1;
                    end else begin // (r32) (r32+d16) (r32+r8) (r32+r16)
                        nx_idx_rdreg_sel = {op[15:10],2'd0};
                        nx_idx_offset = 0;
                        case( op[9:8] )
                            0: nx_pre_ok = 1;
                            1: begin
                                nx_pre_ok = 0;
                                nx_phase  = 1;
                                fetched   = 0; // data fetch will be done in phase 1
                            end
                            3: begin
                                nx_pre_ok = 0;
                                nx_phase  = 1;
                                fetched   = 0; // data fetch will be done in phase 1
                                nx_ridx_mode = { 1'b1, op[10] };
                            end
                        endcase
                    end
                end
                5'h14,5'h15: begin // (-r32) (r32+)
                    nx_idx_rdreg_sel = {op[15:10],2'd0};
                    nx_idx_offset    = 0;
                    nx_reg_dec       = !op[0];
                    nx_pre_inc       =  op[0];
                    nx_pre_ok        = 1;
                end
                default:;
            endcase
        end else begin
            case(mode)
                5'h11: begin
                    nx_idx_offset[23:8] = { {8{op[7]}}, op[7:0] };
                    nx_pre_ok           = 1;
                    fetched             = 1;
                end
                5'h12: begin
                    nx_idx_offset[23:8] = op[15:0];
                    nx_pre_ok           = 1;
                    fetched             = 2;
                end
                5'h13: begin
                    nx_ridx_mode = ridx_mode;
                    if( !ridx_mode[1] ) begin
                        nx_idx_offset = { {8{op[31]}}, op[31:16] };
                        nx_pre_ok     = 1;
                        fetched       = 4;
                    end else begin
                        nx_idx_rdreg_sel = op[23:16];
                        nx_idx_rdreg_aux = op[31:24];
                        nx_pre_ok        = 1;
                        fetched          = 4;
                    end
                end
                default:;
            endcase
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        pre_ok        <= 0;
        idx_ok        <= 0;
        mode          <= 0;
        ridx_mode     <= 0;
        reg_step      <= 0;
        reg_inc       <= 0;
        pre_inc       <= 0;
        reg_dec       <= 0;
        phase         <= 0;
        opl           <= 0;
        idx_rdreg_sel <= 0;
        idx_rdreg_aux <= 0;
        idx_offset    <= 0;
        was_LDD       <= 0;
        was_LDI       <= 0;
        was_CPD       <= 0;
        was_CPI       <= 0;
        pre_offset    <= 0;
        ldar          <= 0;
    end else if(cen) begin
        phase         <= nx_phase;
        mode          <= nx_mode;
        ridx_mode     <= nx_ridx_mode;
        reg_step      <= nx_reg_step;
        reg_inc       <= nx_reg_inc;
        pre_inc       <= nx_pre_inc;
        reg_dec       <= nx_reg_dec;
        pre_ok        <= nx_pre_ok;
        idx_ok        <= pre_ok;
        idx_rdreg_sel <= nx_idx_rdreg_sel;
        idx_rdreg_aux <= nx_idx_rdreg_aux;
        idx_offset    <= nx_idx_offset;
        idx_addr      <= nx_idx_addr;
        opl           <= nx_opl;
        was_LDD       <= nx_was_LDD;
        was_LDI       <= nx_was_LDI;
        was_CPD       <= nx_was_CPD;
        was_CPI       <= nx_was_CPI;
        pre_offset    <= nx_pre_offset;
        ldar          <= nx_ldar;
    end
end

endmodule