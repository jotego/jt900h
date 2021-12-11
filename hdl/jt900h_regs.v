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
    Date: 2-12-2021 */

module jt900h_regs(
    input             rst,
    input             clk,
    input             cen,

    // input             src_mux,
    // input             aux_mux,
    input      [ 1:0] rfp,          // register file pointer
    // From indexed memory addresser
    input      [ 7:0] idx_rdreg_sel,
    input      [ 1:0] reg_step,
    input             reg_inc,
    input             reg_dec,
    // offset register
    input      [ 7:0] idx_rdreg_aux,
    input             idx_en,

    // from the memory
    input      [31:0] alu_dout,
    input      [31:0] ram_dout,
    input             data_sel,
    // read operands
    // input       [1:0] zsel,   // length selection
    // source register
    input       [7:0] src,
    output reg [31:0] src_out,

    // destination register
    input       [7:0] dst,
    output reg [31:0] dst_out,

    // write result
    //input       [2:0] wdst,
    input       [2:0] we,
    //input      [31:0] din
    // Register dump
    input      [7:0] dmp_addr,
    output reg [7:0] dmp_din
);

localparam [3:0] CURBANK  = 4'he,
                 PREVBANK = 4'hd;

// All registers
reg [7:0] accs[0:63];
reg [7:0] ptrs[0:15];
reg [7:0] r0sel, r1sel;

wire [31:0] full_step, data_mux;
wire [31:0] xix, xiy, xiz, xsp;

`ifdef SIMULATION
    wire [31:0] cur_xwa, cur_xbc, cur_xde, cur_xhl;

    assign cur_xwa = {accs[{rfp,4'd3}],accs[{rfp,4'd2}],accs[{rfp,4'd1}],accs[{rfp,4'd0}]};
    assign cur_xbc = {accs[{rfp,4'd7}],accs[{rfp,4'd6}],accs[{rfp,4'd5}],accs[{rfp,4'd4}]};
    assign cur_xde = {accs[{rfp,4'hb}],accs[{rfp,4'ha}],accs[{rfp,4'h9}],accs[{rfp,4'h8}]};
    assign cur_xhl = {accs[{rfp,4'hf}],accs[{rfp,4'he}],accs[{rfp,4'hd}],accs[{rfp,4'hc}]};
`endif

assign xix = { ptrs[ 3], ptrs[ 2], ptrs[ 1], ptrs[ 0] };
assign xiy = { ptrs[ 7], ptrs[ 6], ptrs[ 5], ptrs[ 4] };
assign xiz = { ptrs[11], ptrs[10], ptrs[ 9], ptrs[ 8] };
assign xsp = { ptrs[15], ptrs[14], ptrs[13], ptrs[12] };
assign data_mux = data_sel ? ram_dout : alu_dout;

assign full_step = reg_step == 1 ? 2 : reg_step==2 ? 4 : 1;

// gigantic multiplexer:
always @* begin
    r0sel   = idx_en ? simplify(idx_rdreg_sel) : simplify(src);
    src_out =
        r0sel[7:4]==4 ? 32'd0 : r0sel[7] ?
        {   ptrs[ {r0sel[3:2],2'b11} ], ptrs[ {r0sel[3:2],2'b10} ],
            ptrs[ {r0sel[3:1],1'b1}  ], ptrs[ r0sel[3:0] ] } :
        {   accs[ {r0sel[5:2],2'b11} ], accs[ {r0sel[5:2],2'b10} ],
            accs[ {r0sel[5:1],1'b1}  ], accs[ r0sel[5:0] ] };

    r1sel   = simplify(dst); //simplify(idx_rdreg_aux);
    dst_out = r1sel[7] ?
        {   ptrs[ {r1sel[3:2],2'b11} ], ptrs[ {r1sel[3:2],2'b10} ],
            ptrs[ {r1sel[3:1],1'b1}  ], ptrs[ r1sel[3:0] ] } :
        {   accs[ {r1sel[5:2],2'b11} ], accs[ {r1sel[5:2],2'b10} ],
            accs[ {r1sel[5:1],1'b1}  ], accs[ r1sel[5:0] ] };

    if( reg_dec )
        dst_out = dst_out - full_step;
end

integer gen_cnt;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        for( gen_cnt=0; gen_cnt<64; gen_cnt=gen_cnt+1 ) begin
            accs[gen_cnt] <= 0;
        end
        for( gen_cnt=0; gen_cnt<16; gen_cnt=gen_cnt+1 ) begin
            ptrs[gen_cnt] <= 0;
        end
    end else if(cen) begin
        if( reg_inc )
            { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
              ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= dst_out + full_step;
        if( reg_dec )
            { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
              ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= dst_out;
        if( we[0] ) begin
            if( r1sel[7] )
                ptrs[r1sel[3:0]] <= data_mux[7:0];
            else
                accs[r1sel[5:0]] <= data_mux[7:0];
        end
        if( we[1] ) begin
            if( r1sel[7] )
                { ptrs[{r1sel[3:1],1'b1}], ptrs[r1sel[3:0]] } <= data_mux[15:0];
            else
                { accs[{r1sel[5:1],1'b1}], accs[r1sel[5:0]] } <= data_mux[15:0];
        end
        if( we[2] ) begin
            if( r1sel[7] )
                { ptrs[{r1sel[3:2],2'd3}], ptrs[{r1sel[3:2],2'd2}],
                  ptrs[{r1sel[3:2],2'd1}], ptrs[{r1sel[3:2],2'd0}] } <= data_mux;
            else
                { accs[{r1sel[5:2],2'd3}], accs[{r1sel[5:2],2'd2}],
                  accs[{r1sel[5:2],2'd1}], accs[{r1sel[5:2],2'd0}] } <= data_mux;
        end
    end
end

function [7:0] simplify( input [7:0] rsel );
    simplify = {
               rsel[7:4]==CURBANK  ? { 2'd0, rfp } :
               rsel[7:4]==PREVBANK ? { 2'd0, rfp-2'd1 } : rsel[7:4],
               rsel[3:0] };
endfunction

// Status dump
always @(posedge clk) begin
    if( dmp_addr < 8'h40 )
        dmp_din <= accs[dmp_addr[5:0]];
    else if( dmp_addr < 8'h50 )
        dmp_din <= ptrs[dmp_addr[3:0]];
    else
        dmp_din <= 0;
end
endmodule