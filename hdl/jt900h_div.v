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
    input      [15:0] op0, // dividend
    input      [15:0] op1, // divisor
    input             len,
    input             start,
    output reg [15:0] quot,
    output reg [15:0] rem,
    output reg        busy,
    output reg        v
);

reg  [15:0] divend, divor;
reg  [15:0] sub;
wire [15:0] rslt;
reg  [ 3:0] st;
wire        larger;

assign larger = sub>=divor;
assign rslt   = sub - divor;

always @(posedge clk or posedge rst) begin 
    if(rst) begin
        quot   <= 0;
        rem    <= 0;
        busy   <= 0;
        divend <= 0;
        divor  <= 0;
        sub    <= 0;
        st     <= 0;
    end else begin
        if( start ) begin
            busy   <= 1;
            quot   <= 0;
            rem    <= 0;
            { sub, divend } <= { 15'd0, len ? op0 : { op0[7:0], 8'd0 }, 1'b0 };
            divor  <= len ? op1 : { 8'd0, op1[7:0] };
            st     <= len ? 0 : 8;
            v      <= op1 == 0;
        end else if( busy ) begin
            quot <= { quot[14:0], larger };
            { sub, divend } <= { larger ? rslt[14:0] : sub[14:0], divend, 1'b0 };
            st <= st+4'd1;
            if( &st ) begin
                busy <= 0;
                rem  <= larger ? rslt : sub;
            end
        end
    end
end

endmodule