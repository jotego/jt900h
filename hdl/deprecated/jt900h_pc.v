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

module jt900h_pc(
    input             rst,
    input             clk,
    input             cen,

    input      [ 2:0] idx_fetched,
    input             idx_en,
    input             op_ok,
    input      [ 2:0] ctl_fetched,

    input      [31:0] imm,
    input             we,
    input             rel,

    output reg [31:0] pc
);

parameter PC_RSTVAL=0;

`ifdef SIMULATION
    wire [11:0] pc_short = pc[11:0];
    wire [23:0] pc24     = pc[23:0];
`endif

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        pc <= PC_RSTVAL;
    end else if(cen) begin
        if( rel ) begin // 8-bit relative jump
            pc <= pc + imm;
        end else if( we ) begin
            pc[23:0] <= imm[23:0];    // should I clear the upper bits?
        end else if( op_ok ) begin
            pc <= pc + {29'd0, idx_en ? idx_fetched : ctl_fetched};
        end
    end
end

endmodule