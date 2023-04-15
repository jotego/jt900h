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
    Date: 2-12-2021 */

module jt900h_regs(
    input             rst,
    input             clk,
    input             cen,

    input      [15:0] sr,           // status register
    output reg [ 1:0] rfp,          // register file pointer
    input             inc_rfp,
    input             dec_rfp,
    input             rfp_we,
    input      [ 1:0] imm,
    output reg        bc_unity,
    input             dec_bc,
    input             ex_we,        // Exchange two registers
    // stack
    output     [31:0] xsp,
    input      [15:0] inc_xsp,
    input      [15:0] dec_xsp,

    // MULA support
    output     [31:0] xde,
    output     [31:0] xhl,
    input             dec_xhl,

    // Direct access to accumulator (RRD, RLD)
    input             ld_high,
    output     [31:0] acc,

    // From indexed memory addresser
    input      [ 7:0] idx_rdreg_sel,
    input      [ 1:0] reg_step,
    input             reg_inc,
    input             reg_dec,
    // LDD/LDI:
    input             dec_xde,
    input             dec_xix,
    input             inc_xde,
    input             inc_xix,
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
    output reg [31:0] aux_out,

    // destination register
    input       [7:0] dst,
    output reg [31:0] dst_out,

    // write result
    input       [2:0] ram_we,
    input       [2:0] alu_we,
    input             flag_only,
    //input      [31:0] din
    // Register dump
    input      [7:0] dmp_addr,
    output reg [7:0] dmp_dout
    `ifdef SIMULATION
    ,output   [31:0] sim_xix
    ,output   [31:0] sim_xiy
    ,output   [31:0] sim_xiz
    ,output   [31:0] sim_xsp
    `endif
);

localparam [3:0] CURBANK  = 4'he,
                 PREVBANK = 4'hd;

// All registers
reg [7:0] accs[0:63];
reg [7:0] ptrs[0:15];
reg [7:0] r0sel, r1sel, aux_sel;

wire [31:0] full_step, data_mux, ptr_out;
wire [ 2:0] we;
wire [15:0] cur_bc;
wire [31:0] cur_xwa, cur_xde, cur_xhl, xix;

assign acc = {accs[{rfp,4'd3}],accs[{rfp,4'd2}],accs[{rfp,4'd1}],accs[{rfp,4'd0}]};
assign cur_xwa = acc;
assign cur_bc = { accs[{rfp,4'd5}],accs[{rfp,4'd4}] };
assign cur_xde = {accs[{rfp,4'hb}],accs[{rfp,4'ha}],accs[{rfp,4'h9}],accs[{rfp,4'h8}]};
assign cur_xhl = {accs[{rfp,4'hf}],accs[{rfp,4'he}],accs[{rfp,4'hd}],accs[{rfp,4'hc}]};
assign xsp = { ptrs[15], ptrs[14], ptrs[13], ptrs[12] };
assign xix = { ptrs[ 3], ptrs[ 2], ptrs[ 1], ptrs[ 0] };
assign xde = cur_xde;
assign xhl = cur_xhl;

`ifdef SIMULATION
    wire [31:0] xiy,xiz;
    wire [31:0] cur_xbc;

    assign cur_xbc = {accs[{rfp,4'd7}],accs[{rfp,4'd6}],accs[{rfp,4'd5}],accs[{rfp,4'd4}]};
    assign xiy = { ptrs[ 7], ptrs[ 6], ptrs[ 5], ptrs[ 4] };
    assign xiz = { ptrs[11], ptrs[10], ptrs[ 9], ptrs[ 8] };
    assign sim_xix = xix;
    assign sim_xiy = xiy;
    assign sim_xiz = xiz;
    assign sim_xsp = xsp;
`endif

assign data_mux = ex_we ? src_out : data_sel ? ram_dout : alu_dout;
assign we       = flag_only ? 3'd0 : data_sel ? ram_we : alu_we;
assign ptr_out  = { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
                    ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] };
assign full_step = reg_step == 1 ? 2 : reg_step==2 ? 4 : 1;

// gigantic multiplexer:
always @* begin
    r0sel   = idx_en ? simplify(rfp,idx_rdreg_sel) : simplify(rfp,src);
    src_out =
        r0sel[7:4]==4 ? 32'd0 : r0sel[7] ?
        {   ptrs[ {r0sel[3:2],2'b11} ], ptrs[ {r0sel[3:2],2'b10} ],
            ptrs[ {r0sel[3:1],1'b1}  ], ptrs[ r0sel[3:0] ] } :
        {   accs[ {r0sel[5:2],2'b11} ], accs[ {r0sel[5:2],2'b10} ],
            accs[ {r0sel[5:1],1'b1}  ], accs[ r0sel[5:0] ] };
    // aux_out is used for instructions with two index registers, like LDD
    // the aux register is the same as src_out but with bit 2 at zero
    aux_sel = simplify(rfp,idx_rdreg_sel) & ~8'h4;
    aux_out =
        aux_sel[7:4]==4 ? 32'd0 : aux_sel[7] ?
        {   ptrs[ {aux_sel[3:2],2'b11} ], ptrs[ {aux_sel[3:2],2'b10} ],
            ptrs[ {aux_sel[3:1],1'b1}  ], ptrs[ aux_sel[3:0] ] } :
        {   accs[ {aux_sel[5:2],2'b11} ], accs[ {aux_sel[5:2],2'b10} ],
            accs[ {aux_sel[5:1],1'b1}  ], accs[ aux_sel[5:0] ] };

    r1sel   = idx_en ? simplify(rfp,idx_rdreg_aux) : simplify(rfp,dst);
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
        bc_unity <= 0;
        { ptrs[15], ptrs[14], ptrs[13], ptrs[12] } <= 32'h100; // XSP initial value
    end else if(cen) begin
        bc_unity <= cur_bc==1;
        if( reg_inc ) begin
            if( r0sel[7] ) // pointer
                { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
                  ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= ptr_out + full_step;
            else // general registers are used by CPD/CPI/LDD instruction
                { accs[ {r0sel[5:2],2'd3} ], accs[ {r0sel[5:2],2'd2} ],
                  accs[ {r0sel[5:2],2'd1} ], accs[ {r0sel[5:2],2'd0} ] } <= src_out + full_step;
        end
        if( reg_dec ) begin
            if( r0sel[7] ) // pointer
                { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
                  ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= ptr_out - full_step;
            else // general registers are used by CPD/CPI/LDD instruction
                { accs[ {r0sel[5:2],2'd3} ], accs[ {r0sel[5:2],2'd2} ],
                  accs[ {r0sel[5:2],2'd1} ], accs[ {r0sel[5:2],2'd0} ] } <= src_out - full_step;
        end

        if( dec_bc )
            { accs[{rfp,4'd5}],accs[{rfp,4'd4}] } <= cur_bc-16'd1;

        if( dec_xhl )
            {accs[{rfp,4'hf}],accs[{rfp,4'he}],accs[{rfp,4'hd}],accs[{rfp,4'hc}]}
                <= cur_xhl-32'd2;

        // LDD
        if( dec_xde ) begin
            { accs[{rfp,4'hb}], accs[{rfp,4'ha}], accs[{rfp,4'h9}], accs[{rfp,4'h8}]} <= cur_xde - full_step;
        end
        if( dec_xix ) begin
            { ptrs[ 3], ptrs[ 2], ptrs[ 1], ptrs[ 0] } <= xix - full_step;
        end
        if( inc_xde ) begin
            { accs[{rfp,4'hb}], accs[{rfp,4'ha}], accs[{rfp,4'h9}], accs[{rfp,4'h8}]} <= cur_xde + full_step;
        end
        if( inc_xix ) begin
            { ptrs[ 3], ptrs[ 2], ptrs[ 1], ptrs[ 0] } <= xix + full_step;
        end

        // Stack
        if( dec_xsp != 0 )
            { ptrs[15], ptrs[14], ptrs[13], ptrs[12] } <= xsp - { 16'd0, dec_xsp };
        if( inc_xsp != 0 )
            { ptrs[15], ptrs[14], ptrs[13], ptrs[12] } <= xsp + { 16'd0, inc_xsp };

        // Register writes from ALU/RAM
        if( we[0] ) begin
            if( r1sel[7] )
                ptrs[r1sel[3:0]] <= data_mux[7:0];
            else begin
                // ld_high is used by the RLD/RRD instructions
                accs[r1sel[5:0]] <= ld_high ? data_mux[15:8] : data_mux[7:0];
            end
            if( ex_we ) begin
                if( r0sel[7] )
                    ptrs[r0sel[3:0]] <= dst_out[7:0];
                else begin
                    // ld_high is used by the RLD/RRD instructions
                    accs[r0sel[5:0]] <= dst_out[7:0];
                end
            end
        end
        if( we[1] ) begin
            if( r1sel[7] )
                { ptrs[{r1sel[3:1],1'b1}], ptrs[r1sel[3:0]] } <= data_mux[15:0];
            else
                { accs[{r1sel[5:1],1'b1}], accs[r1sel[5:0]] } <= data_mux[15:0];
            if( ex_we ) begin
                if( r0sel[7] )
                    { ptrs[{r0sel[3:1],1'b1}], ptrs[r0sel[3:0]] } <= dst_out[15:0];
                else
                    { accs[{r0sel[5:1],1'b1}], accs[r0sel[5:0]] } <= dst_out[15:0];
            end
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

function [7:0] simplify;
    input [1:0] rfp;
    input [7:0] rsel;
    simplify = {
               rsel[7:4]==CURBANK  ? { 2'd0, rfp } :
               rsel[7:4]==PREVBANK ? { 2'd0, rfp-2'd1 } : rsel[7:4],
               rsel[3:0] };
endfunction

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rfp <= 0;
    end else if(cen) begin
        if( inc_rfp ) rfp <= rfp+2'd1;
        if( dec_rfp ) rfp <= rfp-2'd1;
        if( rfp_we  ) rfp <= imm;
    end
end

// Status dump
always @(posedge clk) begin
    if( dmp_addr < 8'h40 )
        dmp_dout <= accs[dmp_addr[5:0]];
    else if( dmp_addr < 8'h50 )
        dmp_dout <= ptrs[dmp_addr[3:0]];
    else begin
        case( dmp_addr )
            8'h51: dmp_dout <= sr[ 7:0];
            8'h50: dmp_dout <= sr[15:8];
            default: dmp_dout <= 0;
        endcase
    end
end
endmodule