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

    output reg        ldram_en,
    output reg        idx_en,
    input             idx_ok,

    input      [15:0] cur_op,
    input             op_ok,

    output reg [ 2:0] regs_we,
    output reg [ 7:0] regs_dst
);

localparam FETCH=0, IDX=1, LD_RAM=2;

integer    op_phase;
reg        illegal;
reg  [7:0] last_op;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        illegal <= 0;
        op_phase <= FETCH;
    end else if(cen) begin

        case( op_phase )
            FETCH: if( op_ok ) begin
                casez( cur_op[7:0] )
                    8'b10??_????,8'b11??_0???: begin // start indexed addressing
                        op_phase <= IDX;
                        idx_en   <= 1;
                        last_op  <= cur_op[7:0];
                    end
                    default:;
                endcase
            end
            IDX: if( idx_ok ) begin
                idx_en <= 0;
                casez( cur_op[7:0] )
                    8'b0010_0???: begin // LD R,(mem)
                        op_phase <= LD_RAM;
                        ldram_en <= 1;
                        regs_we  <= last_op[5:4]==0 ? 3'd0 : last_op[5:4]==1 ? 3'd1 : 3'd2;
                        regs_dst <= cur_op[2] ? {4'hf,cur_op[1:0],2'd0} :
                                                {4'he, {cur_op[1:0],2'd0}  };
                    end
                    default:;
                endcase
            end
            LD_RAM: begin
                op_phase <= FETCH;
            end
            default:;
        endcase
    end
end

endmodule