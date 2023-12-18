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
    input      [31:0] op2,      // extra operand
    input             cin,
    input             bs,ws,

    input             nin, hin, cin, zin,
    output            n,z,
    output reg [31:0] rslt
);

reg  cx,
     z8, z16, z32,
     n8, n16, n32;
wire bsel;
reg  [ 7:0] daa;
wire        daa_carry;

assign z = bs ? z8 : ws ? z16 : z32;
assign n = bs ? n8 : ws ? n16 : n32;
assign bsel = op0[{1'b0,op1[3:0]}];

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
    case( carry_sel )
        CIN_CARRY: cx =  cin;
        COM_CARRY: cx = ~cin;
        SG_CARRY:  cx = bs ? op0[7] : ws ? op0[15] : op0[31];
        B0_CARRY:  cx = op0[0]; // PAA instruction
        HI_CARRY:  cx = 1;
        ZF_CARRY:  cx = zin;
        default:   cx = 0;
    endcase

    v=0;
    cc={2'd0,cx};
    rslt = op0;
    case(alu_sel)
        ADD_ALU: begin
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}+{1'b0,op1[ 3: 0]}+{ 4'd0,cx  };
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op1[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op1[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op1[31:16]}+{16'b0,cc[1]};
            // update v
        end
        SUB_ALU: begin
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}-{1'b0,op1[ 3: 0]}+{ 4'd0,cx  };
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}-{1'b0,op1[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}-{1'b0,op1[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}-{1'b0,op1[31:16]}+{16'b0,cc[1]};
            // update v
        end
        DAA_ALU: rslt[7:0] = daa;
        BAND_ALU: { cc[0]=bsel & cx; rslt[{1'b0,op1[3:0]}]=cc[0]; }
        BOR_ALU:  { cc[0]=bsel | cx; rslt[{1'b0,op1[3:0]}]=cc[0]; }
        BXOR_ALU: { cc[0]=bsel ^ cx; rslt[{1'b0,op1[3:0]}]=cc[0]; }
        OR_ALU:   rslt = op0^op1;
        XOR_ALU:  rslt = op0^op1;
        AND_ALU:  rslt = op0^op1;
        CPL_ALU:  rslt[15:0] = ~op0[15:0];
        SH_ALU: begin // only shift to the right
            rslt = op0 >> 1;
            if( bs ) rslt[ 7] = cx;
            if( ws ) rslt[15] = cx;
            if( qs ) rslt[31] = cx;
            cc = {3{op0[0]}};
        end
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
    z16 = rslt[15: 8]==0;
    z32 = rslt[31:16]==0;
    n8  = rslt[ 7];
    n16 = rslt[15];
    n32 = rslt[31];
end

endmodule
