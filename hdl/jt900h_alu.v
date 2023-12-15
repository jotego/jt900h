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
    input             cin,
    input      [ 2:0] w;

    output            n,z,
    output reg [31:0] rslt
);

reg  cx,
     z8, z16, z32,
     n8, n16, n32;

assign z = w[0] ? z8 : w[1] ? z16 : z32;
assign n = w[0] ? n8 : w[1] ? n16 : n32;

always @* begin
    case( carry_sel )
        CIN_CARRY: cx = cin;
        B0_CARRY:  cx = op0[0]; // PAA instruction
        default:   cx = 0;
    endcase

    v=0;
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
        OR_ALU:  rslt = op0^op1;
        XOR_ALU: rslt = op0^op1;
        AND_ALU: rslt = op0^op1;
        BS1F_ALU: casez(op0[15:0])
            16'b????_????_????_???1: rslt[7:0] = 0;
            16'b????_????_????_??10: rslt[7:0] = 1;
            16'b????_????_????_?100: rslt[7:0] = 2;
            16'b????_????_????_1000: rslt[7:0] = 3;
            16'b????_????_???1_0000: rslt[7:0] = 4;
            16'b????_????_??10_0000: rslt[7:0] = 5;
            16'b????_????_?100_0000: rslt[7:0] = 6;
            16'b????_????_1000_0000: rslt[7:0] = 7;
            16'b????_???1_0000_0000: rslt[7:0] = 8;
            16'b????_??10_0000_0000: rslt[7:0] = 9;
            16'b????_?100_0000_0000: rslt[7:0] = 10;
            16'b????_1000_0000_0000: rslt[7:0] = 11;
            16'b???1_0000_0000_0000: rslt[7:0] = 12;
            16'b??10_0000_0000_0000: rslt[7:0] = 13;
            16'b?100_0000_0000_0000: rslt[7:0] = 14;
            16'b1000_0000_0000_0000: rslt[7:0] = 15;
            default: begin rslt[7:0]=0; v=1; end
        endcase
        BS1B_ALU: casez(op0[15:0])
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
        default: rslt = op1;
    endcase
    z8  = rslt[ 7: 0]==0;
    z16 = rslt[15: 8]==0;
    z32 = rslt[31:16]==0;
    n8  = rslt[ 7];
    n16 = rslt[15];
    n32 = rslt[31];
end

endmodule
