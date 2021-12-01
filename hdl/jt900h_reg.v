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

module jt900h_reg(
    input             clk,
    input      [ 1:0] rfp, // register file pointer (i.e. bank)
    input      [ 2:0] rsel,
    input      [31:0] din,
    input      [ 2:0] we,
    output reg [31:0] dout,
    output reg [31:0] mulout
);

// 32-bit registers: acc. index and displacement
// 16-bit registers: accumulators or indexing
//  8-bit registers: general purpose

reg [ 7:0] lower[0:31]; // 4 banks of 8 registers each: WA, BC, DE, HL
reg [15:0] upper[0:15]; // 4 banks of 4 registers each: upper half of XWA, XBC, XDE, XHL

wire [7:0] cur_a = lower[{rfp,3'd0}];
wire [7:0] cur_w = lower[{rfp,3'd1}];
wire [7:0] cur_c = lower[{rfp,3'd2}];
wire [7:0] cur_b = lower[{rfp,3'd3}];
wire [7:0] cur_e = lower[{rfp,3'd4}];
wire [7:0] cur_d = lower[{rfp,3'd5}];
wire [7:0] cur_l = lower[{rfp,3'd6}];
wire [7:0] cur_h = lower[{rfp,3'd7}];

always @(posedge clk) begin
    dout <= { upper[{rfp,rsel[2:1]}] lower[{rfp,rsel|3'd1}], lower[{rfp,rsel}] };
    if( we ) begin
        if( we[0] ) lower[{rfp,rsel}]      <= din[ 7: 0];
        if( we[1] ) lower[{rfp,rsel|3'd1}] <= din[15: 8];
        if( we[2] ) upper[{rfp,rsel[2:1]}] <= din[31:16];
    end
end

always @(posedge clk) begin
    mulout <= {cur_d,cur_e} * {cur_h,cur_l}; // DE * HL
end

endmodule