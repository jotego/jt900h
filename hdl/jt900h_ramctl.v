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
    input      [23:0] xsp,
    input      [15:0] sr,
    input      [23:0] pc,
    input             sel_xsp,
    input      [ 1:0] data_sel,

    // RAM writes
    input      [31:0] alu_dout,
    input             idx_wr,   // starts an indexed RAM write
    input      [ 2:0] len,

    // RAM interface
    output reg [23:0] ram_addr,
    input      [15:0] ram_dout,
    output reg [15:0] ram_din,
    output reg [ 1:0] ram_we,   // write enable mask, high/low bytes

    output     [31:0] dout,
    output            ram_rdy
);

reg  [23:0] cache_addr, op_addr;
reg  [15:0] cache0, cache1, // always keep 4 bytes of data
            op0, op1;
reg  [ 3:0] cache_ok, we_mask;
wire [23:1] next_addr;

wire [23:0] req_addr, eff_addr;
reg  [31:0] eff_data;
reg         wrbusy, idx_wr_l, ldram_l;
reg  [ 1:0] wron;

// assign next_addr = ldram_en ? idx_addr[23:1] : rdup_addr;
assign req_addr = ldram_en ? ( sel_xsp ? xsp : idx_addr ) : pc;
assign eff_addr = sel_xsp ? xsp : idx_addr;
assign ram_rdy  = &cache_ok && cache_addr==req_addr && !wrbusy;
assign dout = {cache1, cache0};

always @* begin
    case( data_sel )
        1: eff_data = {8'd0,pc};
        2: eff_data = {16'd0, sr};
        default: eff_data = alu_dout;
    endcase
end

always @(posedge clk,posedge rst) begin
    if( rst ) begin
        ram_addr   <= 0;
        cache_ok   <= 0;
        we_mask    <= 0;
        cache_addr <= 0;
        wrbusy     <= 0;
        wron       <= 0;
        ram_we     <= 0;
        ram_din    <= 0;
        ldram_l    <= ldram_en;
    end else if(cen) begin
        idx_wr_l <= idx_wr;
        wrbusy   <= 0;
        ram_we   <= 0;
        ldram_l  <= ldram_en;
        if( idx_wr || wron!=0 ) begin // Write access
            if( wron==0 ) begin
                ram_addr <= eff_addr;
                ram_din  <= len[0] || eff_addr[0] ? {2{eff_data[7:0]}} : eff_data[15:0];
                ram_we   <= len[0] ? { eff_addr[0], ~eff_addr[0] } :
                            eff_addr[0] ? 2'b10 : 2'b11;
                wrbusy   <= 1;
                if( (eff_addr[0] && len[1]) || len[2] ) wron <= 1;
            end else if( wron!=0 ) begin
                ram_addr <= ram_addr+24'd2;
                wrbusy <= 1;
                if( wron==2 ) begin
                    ram_din <= {2{eff_data[31:24]}};
                    ram_we  <= 2'b01;
                    wron    <= 0;
                end else begin
                    if( eff_addr[0] ) begin
                        ram_din <= len[1] ? {2{eff_data[15:8]}} :
                                  eff_data[23:8];
                        wron <= len[2] ? 2 : 0;
                        ram_we <= len[1] ? 2'b01 : 2'b11;
                    end else begin // even
                        ram_din <= eff_data[31:16];
                        ram_we  <= 2'b11;
                        wron <= 0;
                    end
                end
            end
        end else if(!wrbusy) begin // Read access
            if( we_mask!=0 ) begin // assume 0 bus waits for now
                ram_addr <= ram_addr+24'd2;
                if( we_mask[0] ) begin
                    cache0[7:0] <= req_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                    cache_ok[0] <= 1;
                    we_mask[0]  <= 0;
                end
                if( we_mask[1] && (!req_addr[0] || !we_mask[0]) ) begin
                    cache0[15:8] <= !req_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                    cache_ok[1] <= 1;
                    we_mask[1]  <= 0;
                end
                //if( we_mask[2] && !we_mask[0] && ( !req_addr[0] || we_mask[1] ) ) begin
                if( we_mask[2] && !we_mask[0] && ( !we_mask[1] || req_addr[0] ) ) begin
                    cache1[7:0] <= req_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                    cache_ok[2] <= 1;
                    we_mask[2]  <= 0;
                end
                if( we_mask[3] && !we_mask[1] && (!req_addr[0] || !we_mask[2]) ) begin
                    cache1[15:8] <= !req_addr[0] ? ram_dout[15:8] : ram_dout[7:0];
                    cache_ok[3] <= 1;
                    we_mask[3]  <= 0;
                end
            end
            // The OP code is kept apart while a load RAM
            // is performed to fetch operands. It is restored afterwards
            if( ldram_en && !ldram_l ) begin
                op_addr   <= cache_addr;
                {op1,op0} <= {cache1,cache0};
            end
            if( !ldram_en && ldram_l ) begin
                cache_addr      <= op_addr;
                {cache1,cache0} <= {op1,op0};
            end else if( (req_addr != cache_addr || cache_ok!=4'hf) && we_mask==0) begin
                if( req_addr==cache_addr+24'd1 && cache_ok[3:1]==3'b111 ) begin
                    cache_addr <= cache_addr+24'd1;
                    { cache1, cache0 } <= { 8'd0, cache1, cache0[15:8] };
                    ram_addr <= req_addr + 24'd3;
                    we_mask  <= 4'b1000;
                    cache_ok <= 4'b0111;
                end else if( req_addr==cache_addr+24'd2 && cache_ok[3:2]==2'b11 ) begin
                    cache_addr <= cache_addr+24'd2;
                    cache0 <= cache1;
                    ram_addr <= req_addr + 24'd2;
                    we_mask  <= 4'b1100;
                    cache_ok <= 4'b0011;
                end else if( req_addr==cache_addr+24'd3 && cache_ok[3] ) begin
                    cache_addr <= cache_addr+24'd3;
                    cache0[7:0] <= cache1[15:8];
                    ram_addr <= req_addr + {23'd0,req_addr[0]};
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
end

endmodule