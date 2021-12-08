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
    Date: 2-12-2021 */

module jt900h_idxaddr(
    input             rst,
    input             clk,
    input             cen,

    input      [31:0] op,
    input             idx_en,
    output reg [ 2:0] fetched,
    // To register bank
    // index register
    output reg [ 7:0] idx_rdreg_sel,
    input      [31:0] idx_rdreg,
    output reg [ 1:0] reg_step,
    output reg        reg_inc,
    output reg        reg_dec,
    // offset register
    output reg [ 7:0] idx_rdreg_aux,
    input      [15:0] idx_rdaux,

    output reg        idx_ok,
    output reg [23:0] idx_addr
);

localparam [7:0] NULL=8'h40;

reg  [23:0] nx_idx_offset, idx_offset, aux24;
reg  [ 1:0] ridx_mode, nx_ridx_mode,
            nx_reg_step;
reg  [ 4:0] mode, nx_mode;
reg  [ 7:0] nx_idx_rdreg_sel, nx_idx_rdreg_aux;
reg         nx_reg_dec, nx_reg_inc;
reg         phase, nx_phase, nx_idx_ok;

always @* begin
    aux24 = ridx_mode[0] ? { {8{idx_rdaux[15]}}, idx_rdaux} : { {16{idx_rdaux[7]}}, idx_rdaux[7:0]};
    idx_addr = idx_rdreg[23:0] + (ridx_mode[1] ?  aux24 : idx_offset);
end

function [7:0] fullreg( input [2:0] rcode );
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
    fetched      = 0;
    nx_mode      = {op[6],op[3:0]};
    nx_ridx_mode = 0;
    nx_reg_step  = op[9:8];
    nx_reg_inc   = 0;
    nx_reg_dec   = 0;
    nx_idx_offset= idx_offset;
    nx_idx_rdreg_sel = idx_rdreg_sel;
    nx_phase     = 0;
    nx_idx_ok   = idx_ok & idx_en;
    if( idx_en && !idx_ok ) begin
        nx_idx_ok = 0;
        if( !phase ) begin
            fetched    = 2;
            casez( {op[6],op[3:0]} )
                5'b0_????: begin
                    nx_idx_rdreg_sel = fullreg(op[2:0]);
                    nx_idx_offset = op[3] ? { {16{op[15]}}, op[15:8] } : 0;
                    nx_idx_ok = 1;
                    fetched = op[3] ? 2'd2: 2'd1;
                end
                5'h10,5'h11,5'h12: begin // memory address as immediate data
                    nx_idx_rdreg_sel = NULL;
                    case( op[1:0] )
                        0: begin
                            nx_idx_offset = { 16'd0, op[15:8] };
                            fetched = 2;
                        end
                        1: begin
                            nx_idx_offset = {  8'd0, op[23:8] };
                            fetched = 3;
                        end
                        default: begin
                            nx_idx_offset = op[31:8];
                            fetched = 4;
                        end
                    endcase
                    nx_idx_ok = 1;
                end
                5'h13: begin // (r32) (r32+d16) (r32+r8) (r32+r16)
                    nx_idx_rdreg_sel = {op[15:10],2'd0};
                    nx_idx_offset = 0;
                    case( op[9:8] )
                        0: nx_idx_ok = 1;
                        1: begin
                            nx_idx_ok = 0;
                            nx_phase   = 1;
                        end
                        2: begin
                            nx_idx_ok = 0;
                            nx_phase   = 1;
                            nx_ridx_mode = { 1'b1, op[10] };
                        end
                    endcase
                end
                5'h14,5'h15: begin // (-r32) (r32+)
                    nx_idx_rdreg_sel = {op[15:10],2'd0};
                    nx_idx_offset = 0;
                    nx_reg_dec = !op[0];
                    nx_reg_inc =  op[0];
                    nx_idx_ok = 1;
                end
                default:;
            endcase
        end else begin
            case(mode)
                5'h11: begin
                    nx_idx_offset[23:8] = { {8{op[7]}}, op[7:0] };
                    nx_idx_ok = 1;
                    fetched    = 1;
                end
                5'h12: begin
                    nx_idx_offset[23:8] = op;
                    nx_idx_ok = 1;
                    fetched    = 2;
                end
                5'h13: begin
                    fetched = 2;
                    if( !ridx_mode[1] ) begin
                        nx_idx_offset = { {8{op[15]}}, op };
                        nx_idx_ok = 1;
                    end else begin
                        nx_idx_rdreg_sel = op[7:0];
                        nx_idx_rdreg_aux = op[15:8];
                        nx_idx_ok = 1;
                    end
                end
                default:;
            endcase
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        idx_ok   <= 0;
        mode      <= 0;
        ridx_mode <= 0;
        reg_step  <= 0;
        reg_inc   <= 0;
        reg_dec   <= 0;
        phase     <= 0;
        idx_rdreg_sel <= 0;
        idx_rdreg_aux <= 0;
        idx_offset    <= 0;
    end else if(cen) begin
        phase     <= nx_phase;
        mode      <= nx_mode;
        ridx_mode <= nx_ridx_mode;
        reg_step  <= nx_reg_step;
        reg_inc   <= nx_reg_inc;
        reg_dec   <= nx_reg_dec;
        idx_ok   <= nx_idx_ok;
        idx_rdreg_sel <= nx_idx_rdreg_sel;
        idx_rdreg_aux <= nx_idx_rdreg_aux;
        idx_offset <= nx_idx_offset;
    end
end

endmodule