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

module jt900h_div(
    input             rst,
    input             clk,
    input             cen,
    input      [15:0] op0,
    input      [15:0] op1,    
    input      [ 1:0] len,
    input             start,
    output     [15:0] quot,
    output     [15:0] rem,
    output            busy
);

always @(posedge clk or posedge rst) begin 
    if(rst) begin
        quot <= 0;
        rem  <= 0;
        busy <= 0;
    end else begin
        if( start ) begin
            busy <= 1;
    end
end

endmodule