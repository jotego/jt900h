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
    Date: 14-12-2023 */

module jt900h_alu(
    input             rst,
    input             clk,
    input             cen,

    input      [31:0] op0,      // destination
    input      [31:0] op1,      // source
    input      [31:0] op2,      // extra operand for shift and module operations
    input             bs,ws,qs,

    // control
    input             div_sign,      // used for signed mul/div
    input             div,
    output            div_busy,
    input       [4:0] alu_sel,
    input       [2:0] cx_sel,

    input             nin, hin, cin, zin,
    output            s,z,p,c,v,
    output reg        h,
    output reg [31:0] rslt
);

`include "900h_param.vh"

reg  cx,
     c8, c16, c32,
     z8, z16, z32,
     v8, v16, v32,
     s8, s16, s32;
reg  [ 7:0] daa;
wire [15:0] div_quot, div_rem;
wire [ 4:0] bidx;
wire [11:0] rdig;
wire        daa_carry, bsel,
            div_v;
reg         upper02, upper03, upper08, upper09, upperaf, upper9f,
            upper7f, upper6f, lower09, loweraf, lower03, lower6f, cdaa;

assign z = bs ? z8 : ws ? z16 : z32;
assign s = bs ? s8 : ws ? s16 : s32;
assign v = bs ? v8 : ws ? v16 : v32;
assign c = bs ? c8 : ws ? c16 : c32;
assign p = bs ? ~^rslt[7:0] : ~^rslt[15:0];
assign bidx = {1'b0,op1[3:0]};
assign bsel = op0[bidx];
assign rdig = {op1[3:0],op0[7:0]}; // op1=A, op0=mem

jt900h_div u_div (
    .rst  ( rst         ),
    .clk  ( clk         ),
    .cen  ( cen         ),
    .op0  ( op0         ), // dividend
    .op1  ( op1[15:0]   ),
    .len  ( qs          ),
    .sign ( div_sign    ),
    .start( div         ),
    .quot ( div_quot    ),
    .rem  ( div_rem     ),
    .busy ( div_busy    ),
    .v    ( div_v       )
);

function signed [31:0] smul( input signed [15:0] a,b );
    smul = a*b;
endfunction

// daa is the value to add during the DAA instruction
always @* begin
    {cdaa,daa} = 0;
    upper02 = op0[7:4]<=2;
    upper03 = op0[7:4]<=3;
    upper08 = op0[7:4]<=8;
    upper09 = op0[7:4]<=9;
    upperaf = ~upper09;
    upper9f = ~upper08;
    upper7f = op0[7:4]>=7;
    upper6f = op0[7:4]>=6;

    lower09 = op0[3:0]<=9;
    loweraf = ~lower09;
    lower03 = op0[3:0]<=3;
    lower6f = op0[3:0]>=6;
    if( !nin && !cin && upper09 && !hin && lower09 ) { cdaa, daa } = 9'h000;
    if( !nin && !cin && upper08 && !hin && loweraf ) { cdaa, daa } = 9'h006;
    if( !nin && !cin && upper09 &&  hin && lower03 ) { cdaa, daa } = 9'h006;
    if( !nin && !cin && upperaf && !hin && lower09 ) { cdaa, daa } = 9'h160;
    if( !nin && !cin && upper9f && !hin && loweraf ) { cdaa, daa } = 9'h166;
    if( !nin && !cin && upperaf &&  hin && lower03 ) { cdaa, daa } = 9'h166;
    if( !nin &&  cin && upper02 && !hin && lower09 ) { cdaa, daa } = 9'h160;
    if( !nin &&  cin && upper02 && !hin && loweraf ) { cdaa, daa } = 9'h166;
    if( !nin &&  cin && upper03 &&  hin && lower03 ) { cdaa, daa } = 9'h166;

    if(  nin && !cin && upper09 && !hin && lower09 ) { cdaa, daa } = 9'h000;
    if(  nin && !cin && upper08 &&  hin && lower6f ) { cdaa, daa } = 9'h0fa;
    if(  nin &&  cin && upper7f && !hin && lower09 ) { cdaa, daa } = 9'h1a0;
    if(  nin &&  cin && upper6f &&  hin && lower6f ) { cdaa, daa } = 9'h19a;
end

always @* begin
    case( cx_sel )
        CIN_CX:  cx =  cin;
        COM_CX:  cx = ~cin;
        B0_CX:   cx = op0[0]; // PAA instruction
        HI_CX:   cx = 1;
        ZF_CX:   cx = ~zin;
        // used for shifts (op2)
        SA_CX:   cx = bs ? op2[7] : ws ? op2[15] : op2[31];   // shift arithmetic
        SH_CX:   cx = op2[0];
        default: cx = 0;
    endcase

    {c32,c16,c8}={3{cx}};
    {v32,v16,v8}= 3'd0;
    rslt = op0;
    h    = 0;
    case(alu_sel)
        ADD_ALU: begin
            { h,   rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}+{1'b0,op1[ 3: 0]}+{ 4'd0,cx };
            { c8,  rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op1[ 7: 4]}+{ 4'b0,h  };
            { c16, rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op1[15: 8]}+{ 8'b0,c8 };
            { c32, rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op1[31:16]}+{16'b0,c16};
            v8  = &{op0[ 7],op1[ 7],~rslt[ 7]}|&{~op0[ 7],~op1[ 7],rslt[ 7]};
            v16 = &{op0[15],op1[15],~rslt[15]}|&{~op0[15],~op1[15],rslt[15]};
            v32 = &{op0[31],op1[31],~rslt[31]}|&{~op0[31],~op1[31],rslt[31]};
        end
        SUB_ALU: begin
            { h,   rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}-{1'b0,op1[ 3: 0]}-{ 4'd0,cx };
            { c8,  rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}-{1'b0,op1[ 7: 4]}-{ 4'b0,h  };
            { c16, rslt[15: 8] } = {1'b0,op0[15: 8]}-{1'b0,op1[15: 8]}-{ 8'b0,c8 };
            { c32, rslt[31:16] } = {1'b0,op0[31:16]}-{1'b0,op1[31:16]}-{16'b0,c16};
            v8  = &{op0[ 7],~op1[ 7],~rslt[ 7]}|&{~op0[ 7],op1[ 7],rslt[ 7]};
            v16 = &{op0[15],~op1[15],~rslt[15]}|&{~op0[15],op1[15],rslt[15]};
            v32 = &{op0[31],~op1[31],~rslt[31]}|&{~op0[31],op1[31],rslt[31]};
        end
        DAA_ALU:  {c8, rslt[7:0]}= {cdaa,daa};
        BAND_ALU: begin {c32,c16,c8} =  {3{bsel & cx}}; rslt[bidx]=c8; end
        BOR_ALU:  begin {c32,c16,c8} =  {3{bsel | cx}}; rslt[bidx]=c8; end
        BXOR_ALU: begin {c32,c16,c8} =  {3{bsel ^ cx}}; rslt[bidx]=c8; end
        BSET_ALU: begin {c32,c16,c8} =  {3{bsel ^ cx}}; rslt[bidx]=cx; end
        AND_ALU:  rslt = op0&op1;
        OR_ALU:   rslt = op0|op1;
        XOR_ALU:  rslt = op0^op1;
        CPL_ALU:  rslt[15:0] = ~op0[15:0];
        MUL_ALU:  rslt = op0[15:0]*op1[15:0];
        MULS_ALU: rslt = smul( op0[15:0], op1[15:0] );
        SH4_ALU:  rslt = { 27'd0, op1[3:0]==0, op1[3:0] }; // convert 4'd0 to 5'd16
        DIV_ALU: begin
            if( ws )
                rslt[15:0] = { div_rem[ 7:0], div_quot[ 7:0] };
            else
                rslt[31:0] = { div_rem[15:0], div_quot[15:0] };
            {v32,v16,v8} = {3{div_v}};
        end
        SHL_ALU: begin // shift one bit left
            {c32,rslt} = {op2,cx};
            c8  = op2[ 7];
            c16 = op2[15];
        end
        SHR_ALU: begin // shift one bit right
            {rslt,c8} = {cx,op2};
            if( bs ) rslt[ 7] = cx;
            if( ws ) rslt[15] = cx;
            {c32,c16} = {2{op2[0]}};
        end
        RRD_ALU: {rslt[7:0],rslt[15:8]}={op1[7:4], rdig[3:0],rdig[11:4]}; // op1=A
        RLD_ALU: {rslt[7:0],rslt[15:8]}={op1[7:4], rdig[7:0],rdig[11:8]}; // op1=A
        MIRR_ALU: rslt[15:0] = {
                op0[0], op0[1], op0[2], op0[3], op0[4], op0[5], op0[6], op0[7],
                op0[8], op0[9], op0[10], op0[11], op0[12], op0[13], op0[14], op0[15] };
        BS1B_ALU: casez(op0[15:0]) // used for BS1F too after a MIRR
            16'b1???_????_????_????: rslt[7:0] = 15;
            16'b01??_????_????_????: rslt[7:0] = 14;
            16'b001?_????_????_????: rslt[7:0] = 13;
            16'b0001_????_????_????: rslt[7:0] = 12;
            16'b0000_1???_????_????: rslt[7:0] = 11;
            16'b0000_01??_????_????: rslt[7:0] = 10;
            16'b0000_001?_????_????: rslt[7:0] = 9;
            16'b0000_0001_????_????: rslt[7:0] = 8;
            16'b0000_0000_1???_????: rslt[7:0] = 7;
            16'b0000_0000_01??_????: rslt[7:0] = 6;
            16'b0000_0000_001?_????: rslt[7:0] = 5;
            16'b0000_0000_0001_????: rslt[7:0] = 4;
            16'b0000_0000_0000_1???: rslt[7:0] = 3;
            16'b0000_0000_0000_01??: rslt[7:0] = 2;
            16'b0000_0000_0000_001?: rslt[7:0] = 1;
            16'b0000_0000_0000_0001: rslt[7:0] = 0;
            default: begin rslt[7:0]=0; {v32,v16,v8}=3'b111; end
        endcase
        MOD_ALU: rslt[15:0] = (op0[15:0]&~op1[15:0])|(op2[15:0]&op1[15:0]);
        default:;
    endcase
    z8  = rslt[ 7: 0]==0;
    z16 = rslt[15: 8]==0 && z8;     // comparing all 16 bits would result in faster logic, but this is smaller
    z32 = rslt[31:16]==0 && z16;
    s8  = rslt[ 7];
    s16 = rslt[15];
    s32 = rslt[31];
end

endmodule
