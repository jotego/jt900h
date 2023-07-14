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

module jt900h_udma(
    input             rst,
    input             clk,
    input             cen,
    // Register access
    input      [31:0] regin,
    input      [ 5:0] regsel,
    input      [ 2:0] regwe,
    input             int_inc,
    input             int_dec,
    output reg [31:0] regout
);

reg  [31:0] sreg[0:3], dreg[0:3];
reg  [15:0] dmac[0:3];
reg  [ 7:0] dmam[0:3];
reg  [15:0] intnest;

// output register mux
always @(posedge clk) if(cen) begin
    case( regsel[5:4] )
        0: regout <= sreg[regsel[3:2]];
        1: regout <= dreg[regsel[3:2]];
        2: regout <= { 8'd0, dmam[regsel[3:2]], dmac[regsel[3:2]] };
        3: regout <= { 16'd0, intnest };
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        sreg[0] <= 0; sreg[1] <= 0; sreg[2] <= 0; sreg[3] <= 0;
        dreg[0] <= 0; dreg[1] <= 0; dreg[2] <= 0; dreg[3] <= 0;
        dmac[0] <= 0; dmac[1] <= 0; dmac[2] <= 0; dmac[3] <= 0;
        dmam[0] <= 0; dmam[1] <= 0; dmam[2] <= 0; dmam[3] <= 0;
        intnest <= 0;
    end else if( cen ) begin
        if( int_inc ) intnest <= intnest + 1'd1;
        if( int_dec ) intnest <= intnest - 1'd1;
        case( regsel[5:4] )
            0: begin
                if( regwe[2] ) sreg[regsel[3:2]] <= regin;
                if( regwe[1] ) sreg[regsel[3:2]][ {regsel[1],4'd0} +: 16 ] <= regin[15:0];
                if( regwe[0] ) sreg[regsel[3:2]][ {regsel[1:0],3'd0} +: 8  ] <= regin[7:0];
            end
            1: begin
                if( regwe[2] ) dreg[regsel[3:2]] <= regin;
                if( regwe[1] ) dreg[regsel[3:2]][{regsel[1],4'd0} +: 16 ] <= regin[15:0];
                if( regwe[0] ) dreg[regsel[3:2]][{regsel[1:0],3'd0} +: 8  ] <= regin[7:0];
            end
            2: begin
                if( regwe[2] ) { dmam[regsel[3:2]], dmac[regsel[3:2]] } <= regin[23:0];
                if( regwe[1] ) begin
                    if( regsel[1] )
                        dmam[regsel[3:2]] <= regin[7:0];
                    else
                        dmac[regsel[3:2]] <= regin[15:0];
                end
                if( regwe[0] ) begin
                    if( regsel[1] )
                        dmam[regsel[3:2]][(regsel[0] ? 8:0) +: 8] <= regin[7:0];
                    else
                        dmac[regsel[3:2]][(regsel[0] ? 8:0) +: 8] <= regin[7:0];
                end
            end
            default:;
        endcase
    end
end

endmodule