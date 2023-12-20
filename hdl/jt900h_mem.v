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
    Date: 20-12-2023 */

module jt900h_mem(
    input             rst,
    input             clk,
    input             cen,
    // external interface
    output reg [23:0] bus_addr,
    input      [15:0] bus_dout,
    output reg [15:0] bus_din,
    output            bus_wr,
    output            bus_rd,
    // from ucode
    input       [2:0] fetch_sel,
    input       [1:0] ea_sel,
    input             da2ea,
    input             wr,
    // from control unit
    input             bs, ws, qs,
    // from register unit
    input      [23:0] da,
    input      [23:0] pc,
    input      [31:0] xsp,
    input      [31:0] md,
    // outputs
    output reg [23:0] ea,
    output reg [31:0] mdata,
    output            busy
);

reg  [31:0] ea;     // address calculated from memory addressing instructions

always @* begin
    case( ea_sel )
        DA_EA: nx_addr = da;
        SP_EA: nx_addr = xsp[23:0];
        M_EA:  nx_addr = ea;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        bus_addr <= 0;
        bus_din  <= 0;
        ea       <= 0;
        mdata    <= 0;
    end else if(cen) begin
        if( da2ea ) ea <= da;
        if( !busy ) begin
            if( wr ) begin
                bus_addr <= nx_addr;
            end
        end
    end
end

endmodule