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
    output     [23:0] bus_addr,
    input      [15:0] bus_dout,
    input             bus_busy,
    output reg [15:0] bus_din,
    output reg [ 1:0] bus_we,
    output reg        bus_rd,
    // from ucode
    input       [1:0] fetch_sel,
    input       [2:0] ea_sel,
    input             da2ea,
    input             wr,
    input             inc_pc,       // only read memory for PC address if inc_pc is stable
    // from control unit
    input             bs, ws, qs,
    // from DMA
    input      [31:0] dma,
    // from register unit
    input      [31:0] da,
    input      [23:0] pc,
    input      [31:0] xsp,
    input      [31:0] md,
    // outputs
    output reg [31:0] ea,           // address calculated from memory addressing instructions
    output reg [31:0] mdata,
    output            busy
);

`include "900h_param.vh"

reg  [23:0] ca,     // cached address
            wa;     // write address
reg  [ 1:0] adelta;
wire [39:0] wdadj;
reg  [23:0] nx_din, nx_addr;
reg  [ 1:0] wp;
reg  [ 2:0] rp;
reg         wrk, wrl;
wire        part;
reg         bl, wl, ql;

assign wdadj    = nx_addr[0] ? {md,8'd0} : {8'd0,md};
assign bus_addr = (bus_we!=0?wa:ca) + {22'd0,adelta};
assign busy     = wrk || wr || (nx_addr != ca && (!inc_pc || ea_sel!=0));
assign part     = fetch_sel==VS_FETCH && (bl|wl);

always @* begin
    case( ea_sel )
        DA_EA:   nx_addr = da[23:0];
        SP_EA:   nx_addr = xsp[23:0];
        M_EA:    nx_addr = ea[23:0];
        DMA_EA:  nx_addr = dma[23:0];
        default: nx_addr = pc;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        ca         <= ~24'h0;
        wa         <= 0;
        bus_din    <= 0;
        bus_we     <= 0;
        bus_rd     <= 0;
        ea         <= 0;
        rp         <= 0;
        wp         <= 0;
        mdata      <= 0;
        adelta     <= 0;
        wrk        <= 0;
        wrl        <= 0;
        {ql,wl,bl} <= 0;
    end else if(cen) begin
        if( !bus_busy ) begin
            bus_we <= 0;
            wp     <= wp<<1;
            rp     <= rp<<1;
        end
        if( da2ea ) ea <= da;
        if( !wrk ) begin
            wrl <= wr;
            if( wr & ~wrl ) begin
                wa         <= nx_addr;
                adelta     <= 0;
                bus_din    <= wdadj[15:0];
                nx_din     <= wdadj[39-:24];
                bus_we     <= !nx_addr[0] ? { qs|ws, 1'b1 } : 2'b10;
                {ql,wl,bl} <= {qs,ws,bs};
                if( (ws & nx_addr[0]) | qs ) begin
                    wp  <= 1;
                    wrk <= 1;
                end
            end else if( !wr && nx_addr != ca && (!inc_pc || ea_sel!=0)) begin
                ca         <= nx_addr;
                adelta     <= 0;
                wrk        <= 1;
                bus_rd     <= 1;
                rp         <= 1;
                {ql,wl,bl} <= ea_sel==0 ? 3'b100 : {qs,ws,bs}; // always reads 32 bits for PC fetches
            end
        end else if( !bus_busy ) begin
            if( wp[0] ) begin
                adelta    <= bus_addr[0] ? 2'b01 : 2'b10;
                bus_din  <= nx_din[15:0];
                bus_we   <= { ql, ql | wl };
                nx_din   <= nx_din>>16;
                if( ~(ql&bus_addr[0]) ) begin
                    wp     <= 0;
                    wrk    <= 0;
                end
            end else if( wp[1] ) begin
                adelta  <= 2'b11;
                bus_din <= nx_din[15:0];
                bus_we  <= 2'b01;
                wrk     <= 0;
            end else if(rp[0]) begin
                mdata  <= 0;
                if(bus_addr[0]) begin
                    mdata[7:0] <= bus_dout[15:8];
                end else begin
                    mdata[15:0] <= bus_dout;
                end
                if(part & (bl|(wl&~bus_addr[0]))) begin
                    rp     <= 0;
                    wrk    <= 0;
                    bus_rd <= 0;
                end else begin
                    adelta <= bus_addr[0] ? 2'b01 : 2'b10;
                end
            end else if(rp[1]) begin
                mdata[(adelta[0]?8:16)+:16] <= bus_dout;
                if( ~adelta[0]|(part&wl) ) begin
                    rp     <= 0;
                    wrk    <= 0;
                    bus_rd <= 0;
                end else begin
                    adelta <= 2'b11;
                end
            end else if(rp[2]) begin
                mdata[31-:8] <= bus_dout[7:0];
                wrk    <= 0;
                bus_rd <= 0;
            end
        end
    end
end

endmodule