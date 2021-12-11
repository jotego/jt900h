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
    Date: 30-11-2021 */

module jt900h_alu(
    input             rst,
    input             clk,
    input             cen,
    input      [31:0] op0,
    input      [31:0] op1,
    input      [31:0] imm,
    input             opmux,
    input      [ 2:0] w,        // operation width
    input      [ 5:0] sel,      // operation selection
    output     [ 7:0] flags,
    output reg [31:0] dout
);

`include "jt900h.inc"

reg [15:0] stcf;
reg [31:0] op2, rslt;
reg        sign, zero, halfc, overflow, negative, carry;
reg        nx_s, nx_z, nx_h, nx_v, nx_n, nx_c;
reg [ 2:0] cc;
wire       is_zero, rslt_sign, op0_s, op1_s;

assign flags   = {sign, zero, 1'b0, halfc, 1'b0, overflow, negative, carry};
assign is_zero = w[0] ? rslt[7:0]==0 : w[1] ? rslt[15:0]==0 : rslt[31:0]==0;
assign rslt_sign = w[0] ? rslt[7] : w[1] ? rslt[15] : rslt[31];
assign rslt_c  = w[0] ? cc[0] : w[1] ? cc[1] : cc[2];
assign op0_s   = w[0] ? op0[7] : w[1] ? op0[15] : op0[31];
assign op1_s   = w[0] ? op1[7] : w[1] ? op1[15] : op1[31];

always @* begin
    stcf = op1;
    stcf[op0[3:0]] = carry;

    op2 = opmux ? imm : op1;
end

always @* begin
    case( sel )
        ALU_MOVE: rslt = imm;
        ALU_ADD: begin    // also INC, also MULA
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[3:0]} + {1'b0,op1[3:0]};
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op2[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op2[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op2[31:16]}+{16'b0,cc[1]};
            nx_z = is_zero;
            nx_n = 0;
            nx_s = rslt_sign;
            nx_c = rslt_c;
            nx_v = nx_s ^ op0_s ^ op1_s;
        end
        // ALU_SUB: rslt = op0-op2;   // also DEC and CP
        // ALU_ADC: rslt = op0+op2+carry;
        // ALU_SBC: rslt = op0-op2-carry;
        // ALU_AND: rslt = op0&op2; // use it for RES bit,dst too?
        // ALU_OR:  rslt = op0|op2; // use it for SET bit,dst too?
        // ALU_XOR: rslt = op0^op2; // use it for CHG bit,dst too?
        // Control unit should set op2 so MINC1,MINC2,MINC4 and MDEC1/2/4
        // can be performed
        /*
        MODULO: rslt = op0[15:0]==op2[15:0] ? 0 : {16'd0,op0[15:0]+op2[15:0]};
        NEG: rslt = -op0;
        CPL: rslt = ~op0;
        EXTZ: rslt = w[1] ? {24'd0,op0[7:0]} : {16'd0,op0[15:0]};
        EXTS: rslt = w[1] ? {16'd0,{8{op0[7]}}, op0[7:0]} : {{16{op0[15]}},op0[15:0]};
        PAA: rslt = op0[0] ? op0+1'd1 : op0;
        // MUL, MULS, DIV, DIVS
        LDCF: carry <= op2[ op0[3:0] ];
        STCF: rslt = stcf;
        ANDCF: carry <= carry & op2[ op0[3:0] ]; // reuse for RCF - reset carry
        ORCF:  carry <= carry | op2[ op0[3:0] ]; // reuse for SCF - set carry
        XORCF: carry <= carry ^ op2[ op0[3:0] ];
        CCF:   carry <= ~carry;
        ZCF:   carry <= ~zero;
        TSET: begin // reuse for BIT
            zero <= ~op2[op0[3:0]];
            rslt = op0 | (16'd1<<op0[3:0]);
        end
        MIRR: rslt = {
                op[0], op[1], op[2], op[3], op[4], op[5], op[6], op[7],
                op[8], op[9], op[10], op[11], op[12], op[13], op[14], op[15],
            };
        BS1F:
            casez(op0[15:0])
                16'b????_????_????_???1: dout<=1;
                16'b????_????_????_?100: dout<=2;
                16'b????_????_????_1000: dout<=3;
                16'b????_????_???1_0000: dout<=4;
                16'b????_????_??10_0000: dout<=5;
                16'b????_????_?100_0000: dout<=6;
                16'b????_????_1000_0000: dout<=7;
                16'b????_???1_0000_0000: dout<=8;
                16'b????_??10_0000_0000: dout<=9;
                16'b????_?100_0000_0000: dout<=10;
                16'b????_1000_0000_0000: dout<=11;
                16'b???1_0000_0000_0000: dout<=12;
                16'b??10_0000_0000_0000: dout<=13;
                16'b?100_0000_0000_0000: dout<=14;
                16'b1000_0000_0000_0000: dout<=15;
                default: dout<=0;
            endcase
        BS1B:
            casez(op0[15:0])
                16'b1000_0000_0000_0000: dout<=15;
                16'b?100_0000_0000_0000: dout<=14;
                16'b??10_0000_0000_0000: dout<=13;
                16'b???1_0000_0000_0000: dout<=12;
                16'b????_1000_0000_0000: dout<=11;
                16'b????_?100_0000_0000: dout<=10;
                16'b????_??10_0000_0000: dout<=9;
                16'b????_???1_0000_0000: dout<=8;
                16'b????_????_1000_0000: dout<=7;
                16'b????_????_?100_0000: dout<=6;
                16'b????_????_??10_0000: dout<=5;
                16'b????_????_???1_0000: dout<=4;
                16'b????_????_????_1000: dout<=3;
                16'b????_????_????_?100: dout<=2;
                16'b????_????_????_???1: dout<=1;
                default: dout<=0;
            endcase
            */
        endcase
end

always @(posedge clk) if(cen) begin
    dout     <= rslt;
    sign     <= nx_s;
    zero     <= nx_z;
    halfc    <= nx_h;
    overflow <= nx_v;
    negative <= nx_n;
    carry    <= nx_c;
end


endmodule