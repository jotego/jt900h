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
    input      [31:0] din,
    output reg [31:0] dout,
    input      [ 5:0] addr,
    input             qs, ws, bs,
    input             we,
    // Nested interrupts
    input      [ 7:0] int_addr,
    input             nstinc,
    input             nstdec
);

reg  [31:0] sreg[0:3], dreg[0:3];
reg  [15:0] dmac[0:3];
reg  [ 7:0] dmam[0:3];
reg  [15:0] intnest;
wire [ 2:0] regwe;

`ifdef SIMULATION
wire [31:0] SREG0 = sreg[0], SREG1 = sreg[1],
            SREG2 = sreg[2], SREG3 = sreg[3],
            DREG0 = dreg[0], DREG1 = dreg[1],
            DREG2 = dreg[2], DREG3 = dreg[3];
wire [15:0] DMAC0 = dmac[0], DMAC1 = dmac[1],
            DMAC2 = dmac[2], DMAC3 = dmac[3];
wire [ 7:0] DMAM0 = dmam[0], DMAM1 = dmam[1],
            DMAM2 = dmam[2], DMAM3 = dmam[3];
`endif

assign regwe = {3{we}} & {qs,ws,bs};

// output register mux
always @(posedge clk) if(cen) begin
    dout <= 0;
    case( addr[5:4] )
        0: dout <= sreg[addr[3:2]];
        1: dout <= dreg[addr[3:2]];
        2: dout <= addr[1] ? {24'd0, dmam[addr[3:2]]} : { 8'd0, dmam[addr[3:2]], dmac[addr[3:2]] };
        3: if( addr[3:0]==4'hc ) dout[15:0] <= intnest;
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
        if( nstinc ) intnest <= intnest + 1'd1;
        if( nstdec ) intnest <= intnest - 1'd1;
        case( addr[5:4] )
            0: begin
                if( regwe[2] ) sreg[addr[3:2]] <= din;
                if( regwe[1] ) sreg[addr[3:2]][ {addr[1],4'd0}   +: 16 ] <= din[15:0];
                if( regwe[0] ) sreg[addr[3:2]][ {addr[1:0],3'd0} +: 8  ] <= din[7:0];
            end
            1: begin
                if( regwe[2] ) dreg[addr[3:2]] <= din;
                if( regwe[1] ) dreg[addr[3:2]][{addr[1],4'd0}   +: 16 ] <= din[15:0];
                if( regwe[0] ) dreg[addr[3:2]][{addr[1:0],3'd0} +: 8  ] <= din[7:0];
            end
            2: begin
                if( regwe[2] ) { dmam[addr[3:2]], dmac[addr[3:2]] } <= din[23:0];
                if( regwe[1] ) begin
                    if( addr[1] )
                        dmam[addr[3:2]] <= din[7:0];
                    else
                        dmac[addr[3:2]] <= din[15:0];
                end
                if( regwe[0] ) begin
                    if( addr[1] )
                        dmam[addr[3:2]][(addr[0] ? 8:0) +: 8] <= din[7:0];
                    else
                        dmac[addr[3:2]][(addr[0] ? 8:0) +: 8] <= din[7:0];
                end
            end
            default:;
        endcase
`ifdef SIMULATION
        if( regwe!=0 ) $display("uDMA written to"); `endif
    end
end

endmodule