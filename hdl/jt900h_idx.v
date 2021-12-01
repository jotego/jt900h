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
    Date: 29-11-2021 */

module jt900h_idx(
    input             clk,
    input      [ 1:0] rsel,
    input      [31:0] din,
    input      [ 1:0] we,
    output reg [31:0] dout
);

reg [15:0] lower[0:3]; // IX, IY, IZ, SP
reg [15:0] upper[0:3]; // upper half to make XIX, XIY, XIZ

always @(posedge clk) begin
    dout <= { upper[rsel], lower[rsel] };
    if( we ) begin
        if( we[0] ) lower[rsel] <= din[15: 0];
        if( we[1] ) upper[rsel] <= din[31:16];
    end
end

endmodule