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

module jt900h_pc(
    input             rst,
    input             clk,
    input             cen,

    input      [ 1:0] idx_fetched,
    input             idx_en,
    input      [ 1:0] ctl_fetched,

    output reg [31:0] pc
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        pc <= 0;
    end else if(cen) begin
        pc <= pc + {30'd0, idx_en ? idx_fetched : ctl_fetched};
    end
end

endmodule