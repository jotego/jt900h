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

    input      [15:0] op,
    output reg        fetch,
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

    output reg        addr_ok,
    output reg [23:0] idx_addr
);

localparam [7:0] NULL=8'h40;

reg  [23:0] idx_offset, aux24;
reg  [ 1:0] ridx_mode;
reg  [ 4:0] mode;

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



always @(posedge clk, posedge rst) begin
    if( rst ) begin
        addr_ok <= 0;
    end else begin
        mode <= {op[6],op[3:0]};
        ridx_mode <= 0;
        reg_step <= op[9:8];
        reg_inc <= 0;
        reg_dec <= 0;
        fetch   <= 0;
        if( fetch ) begin
            case(mode)
                5'h11: begin
                    idx_offset[23:8] <= { {8{op[7]}}, op[7:0] };
                    addr_ok <= 1;
                end
                5'h12: begin
                    idx_offset[23:8] <= op;
                    addr_ok <= 1;
                end
                5'h13: begin
                    if( !ridx_mode[1] ) begin
                        idx_offset <= { {8{op[15]}}, op };
                        addr_ok <= 1;
                    end else begin
                       idx_rdreg_sel <= op[7:0];
                       idx_rdreg_aux <= op[15:8];
                       addr_ok <= 1;
                    end
                end
                default:;
            endcase
        end else begin
            casez( {op[6],op[3:0]} )
                5'b0_????: begin
                    idx_rdreg_sel <= fullreg(op[2:0]);
                    idx_offset <= op[3] ? { {16{op[15]}}, op[15:8] } : 0;
                    addr_ok <= 1;
                end
                5'b1_0000: begin
                    idx_rdreg_sel <= NULL;
                    idx_offset <= { 16'd0, op[15:8] };
                    addr_ok <= 1;
                end
                5'h11, 5'h12: begin
                    idx_rdreg_sel <= NULL;
                    idx_offset <= { 16'd0, op[15:8] };
                    addr_ok <= 0;
                    fetch <= 1;
                end
                5'h13: begin // (r32) (r32+d16) (r32+r8) (r32+r16)
                    idx_rdreg_sel <= {op[15:10],2'd0};
                    idx_offset <= 0;
                    case( op[9:8] )
                        0: addr_ok <= 1;
                        1: begin
                            addr_ok <= 0;
                            fetch <= 1;
                        end
                        2: begin
                            addr_ok <= 0;
                            fetch <= 1;
                            ridx_mode <= { 1'b1, op[10] };
                        end
                    endcase
                end
                5'h14,5'h15: begin // (-r32) (r32+)
                    idx_rdreg_sel <= {op[15:10],2'd0};
                    idx_offset <= 0;
                    reg_dec <= !op[0];
                    reg_inc <=  op[0];
                    addr_ok <= 1;
                end
                default:;
            endcase
        end
    end
end

endmodule