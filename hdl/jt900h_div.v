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
    Date: 30-11-2021 */

module jt900h_div(
    input             rst,
    input             clk,
    input             cen,
    input      [31:0] op0, // dividend
    input      [15:0] op1, // divisor
    input             len,
    input             start,
    input             sign,
    output     [15:0] quot,
    output reg [15:0] rem,
    output reg        busy,
    output reg        v
);

reg  [31:0] divend, sub, fullq, op0_unsig;
reg  [15:0] divor, op1_unsig;
wire [31:0] rslt, nx_quot;
reg  [ 4:0] st;
wire        larger;
reg         start_l;
reg         sign0, sign1, rsi;

assign larger = sub>=divor;
assign rslt   = sub - { 16'd0, divor };
assign nx_quot= { fullq[30:0], larger };
assign quot   = fullq[15:0];

always @* begin
    op0_unsig = op0;
    op1_unsig = op1;
    sign0     = len ? op0[31] : op0[15];
    sign1     = len ? op1[15] : op1[7];
    if( sign ) begin
        if( sign0 ) op0_unsig = ~op0 + 32'd1;
        if( sign1 ) op1_unsig = ~op1 + 16'd1;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        fullq  <= 0;
        rem    <= 0;
        busy   <= 0;
        divend <= 0;
        divor  <= 0;
        sub    <= 0;
        st     <= 0;
        start_l<= 0;
        v      <= 0;
        rsi    <= 0;
    end else begin
        start_l <= start;
        if( start && !start_l) begin
            busy   <= 1;
            fullq  <= 0;
            rem    <= 0;
            { sub, divend } <= { 31'd0, len ? op0_unsig : { op0_unsig[15:0], 16'd0 }, 1'b0 };
            divor  <= len ? op1_unsig : { 8'd0, op1_unsig[7:0] };
            st     <= len ? 5'd0 : 5'd16;
            v      <= op1 == 0;
            rsi    <= sign & (sign0 ^ sign1);
        end else if( busy ) begin
            fullq <= nx_quot;
            { sub, divend } <= { larger ? rslt[30:0] : sub[30:0], divend, 1'b0 };
            st <= st+1'd1;
            if( &st ) begin
                busy <= 0;
                rem   <= larger ? rslt[15:0] : sub[15:0];
                if( rsi ) fullq <= ~nx_quot+1'd1;
                if( len ? nx_quot[31:16]!=0 : nx_quot[15:8]!=0 ) v <= 1;
            end
        end
    end
end

endmodule