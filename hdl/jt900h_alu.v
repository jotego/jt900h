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
    input             div,
    output            div_busy,
    input       [4:0] alu_sel,
    input       [2:0] cx_sel,

    input             nin, hin, cin, zin,
    output            n,z,p,c,
    output reg        h,v,
    output reg [31:0] rslt
);

`include "900h_param.vh"

reg  cx,
     z8, z16, z32,
     n8, n16, n32;
reg  [ 7:0] daa;
reg  [ 2:0] cc;
wire [15:0] div_quot, div_rem;
wire [ 4:0] bidx;
wire [11:0] rdig;
wire        daa_carry, bsel,
            div_sign, div_v;

assign z = bs ? z8    : ws ? z16   : z32;
assign n = bs ? n8    : ws ? n16   : n32;
assign p = bs ? ~^rslt[7:0] : ~^rslt[15:0];
assign c = bs ? cc[0] : ws ? cc[1] : cc[2];
assign bidx = {1'b0,ws&op1[3],op1[2:0]};
assign bsel = op0[bidx];
assign div_sign = alu_sel==DIVS_ALU;
assign rdig = {op1[3:0],op0[7:0]};

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
    daa = 0;
    if( nin ) begin
        if( !cin && hin && op0[7:4]<9 && op0[3:0]>=6 ) daa=8'hfa;
        if(  cin && ( op0[7:4]>=7 && !hin && op0[3:0]<10 )) daa=8'ha0;
        if(  cin && ( op0[7:4]>=6 &&  hin && op0[3:0]>=6 )) daa=8'h9a;
    end else begin
        if ((cin || op0[7:4] > 9) || (op0[7:4] > 8) && op0[3:0] > 9) daa[7:4] =  4'd6;
        if  (hin || op0[3:0] > 9) daa[3:0] = 6;
    end
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

    v=0;
    cc={3{cx}};
    rslt = op0;
    case(alu_sel)
        ADD_ALU: begin
            { h    , rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}+{1'b0,op1[ 3: 0]}+{ 4'd0,cx   };
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op1[ 7: 4]}+{ 4'b0,h    };
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op1[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op1[31:16]}+{16'b0,cc[1]};
            // update v
        end
        SUB_ALU: begin
            { h    , rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}-{1'b0,op1[ 3: 0]}-{ 4'd0,cx   };
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}-{1'b0,op1[ 7: 4]}-{ 4'b0,h    };
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}-{1'b0,op1[15: 8]}-{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}-{1'b0,op1[31:16]}-{16'b0,cc[1]};
            // update v
        end
        DAA_ALU: rslt[7:0] = daa;
        BAND_ALU: begin cc[0]=bsel & cx; rslt[bidx]=cc[0]; end
        BOR_ALU:  begin cc[0]=bsel | cx; rslt[bidx]=cc[0]; end
        BXOR_ALU: begin cc[0]=bsel ^ cx; rslt[bidx]=cc[0]; end
        BSET_ALU: begin cc = ~{3{bsel}}; rslt[bidx]=cx;    end
        AND_ALU:  rslt = op0&op1;
        OR_ALU:   rslt = op0|op1;
        XOR_ALU:  rslt = op0^op1;
        CPL_ALU:  rslt[15:0] = ~op0[15:0];
        MUL_ALU:  rslt = op0[15:0]*op1[15:0];
        MULS_ALU: rslt = smul( op0[15:0], op1[15:0] );
        SH4_ALU:  rslt = { 27'd0, op1[3:0]==0, op1[3:0] }; // convert 4'd0 to 5'd16
        DIV_ALU, DIVS_ALU: begin
            if( bs )
                rslt[15:0] = { div_rem[ 7:0], div_quot[ 7:0] };
            else
                rslt[31:0] = { div_rem[15:0], div_quot[15:0] };
            v = div_v;
        end
        SHL_ALU: begin // shift one bit left
            {cc[2],rslt} = {op2,cx};
            cc[0] = op2[ 7];
            cc[1] = op2[15];
        end
        SHR_ALU: begin // shift one bit right
            {rslt,cc[0]} = {cx,op2};
            if( bs ) rslt[ 7] = cx;
            if( ws ) rslt[15] = cx;
            cc[2:1] = {2{op2[0]}};
        end
        RRD_ALU: rslt[15:0]={op1[7:4],rdig[3:0],rdig[11:4]}; // op0=mem, op1=A
        RLD_ALU: rslt[15:0]={op1[7:4],rdig[7:0],rdig[11:8]};
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
            default: begin rslt[7:0]=0; v=1; end
        endcase
        MOD_ALU: rslt[15:0] = (op0[15:0]&~op1[15:0])|(op2[15:0]&op1[15:0]);
        default:;
    endcase
    z8  = rslt[ 7: 0]==0;
    z16 = rslt[15: 8]==0 && z8;     // comparing all 16 bits would result in faster logic, but this is smaller
    z32 = rslt[31:16]==0 && z16;
    n8  = rslt[ 7];
    n16 = rslt[15];
    n32 = rslt[31];
end

endmodule
