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
    Date: 3-12-2021 */

module jt900h_ramctl(
    input             rst,
    input             clk,
    input             cen,

    //input      [ 2:0] regs_we,
    input             ldram_en,
    input      [23:0] idx_addr,
    input      [23:0] pc,

    output reg [23:0] ram_addr,
    input      [15:0] ram_dout,
    output     [31:0] dout,
    output            ram_rdy
);

reg  [23:0] cache_addr;
reg  [15:0] cache0, cache1; // always keep 4 bytes of data
reg  [ 3:0] cache_ok, we_mask;
wire [23:1] next_addr;

wire [23:0] req_addr;


// assign next_addr = ldram_en ? idx_addr[23:1] : rdup_addr;
assign req_addr = ldram_en ? idx_addr : pc;
assign ram_rdy  = &cache_ok;
assign dout = {cache1, cache0};

always @(posedge clk,posedge rst) begin
    if( rst ) begin
        ram_addr <= 0;
        cache_ok <= 0;
        we_mask  <= 0;
        cache_addr <= 0;
    end else if(cen) begin
        if( we_mask!=0 ) begin // assume 0 bus waits for now
            ram_addr <= ram_addr+24'd2;
            if( we_mask[0] ) begin
                cache0[7:0] <= ram_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                cache_ok[0] <= 1;
                we_mask[0]  <= 0;
            end
            if( we_mask[1] && (!ram_addr[0] || !we_mask[0]) ) begin
                cache0[15:8] <= !ram_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                cache_ok[1] <= 1;
                we_mask[1]  <= 0;
            end
            if( we_mask[2] && !we_mask[0] && ( !ram_addr[0] || we_mask[1] ) ) begin
                cache1[7:0] <= ram_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                cache_ok[2] <= 1;
                we_mask[2]  <= 0;
            end
            if( we_mask[3] && !we_mask[1] && (!ram_addr[0] || !we_mask[2]) ) begin
                cache1[15:8] <= !ram_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                cache_ok[3] <= 1;
                we_mask[3]  <= 0;
            end
        end
        if( req_addr != cache_addr && we_mask==0) begin
            if( req_addr[23:1]==cache_addr[23:1] ) begin
                cache_addr <= cache_addr+24'd1;
                { cache1, cache0 } <= { 8'd0, cache1, cache0[15:8] };
                ram_addr <= req_addr + 24'd2;
                we_mask  <= 4'b1000;
                cache_ok <= 4'b0111;
            end else if( req_addr==cache_addr+24'd2 ) begin
                cache_addr <= cache_addr+24'd2;
                cache0 <= cache1;
                ram_addr <= req_addr + 24'd2;
                we_mask  <= 4'b1100;
                cache_ok <= 4'b0011;
            end else if( req_addr==cache_addr+24'd3 ) begin
                cache_addr <= cache_addr+24'd3;
                cache0[7:0] <= cache1[15:8];
                ram_addr <= req_addr + 24'd3;
                we_mask  <= 4'b1110;
                cache_ok <= 4'b0001;
            end else begin
                ram_addr <= req_addr;
                cache_addr <= req_addr;
                we_mask  <= 4'b1111;
                cache_ok <= 4'b0000;
            end
        end
    end
end

endmodule