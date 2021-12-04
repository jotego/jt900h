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
    input      [31:0] op0,
    input      [31:0] op1,
    input      [31:0] imm,
    input             opmux,
    input      [ 2:0] w,        // operation width
    input      [ 5:0] sel,      // operation selection
    output reg        carry,
    output reg        zero,
    output reg [31:0] dout
);

reg [15:0] stcf;
reg [31:0] op2;

always @* begin
    stcf = op1;
    stcf[op0[3:0]] = carry;

    op2 = opmux ? imm : op1;
end

always @(posedge clk) begin
    case( sel )
        ADD: dout <= op0+op2;   // also INC, also MULA
        SUB: dout <= op0-op2;   // also DEC and CP
        ADC: dout <= op0+op2+carry;
        SBC: dout <= op0-op2-carry;
        AND: dout <= op0&op2; // use it for RES bit,dst too?
        OR:  dout <= op0|op2; // use it for SET bit,dst too?
        XOR: dout <= op0^op2; // use it for CHG bit,dst too?
        // Control unit should set op2 so MINC1,MINC2,MINC4 and MDEC1/2/4
        // can be performed
        MODULO: dout <= op0[15:0]==op2[15:0] ? 0 : {16'd0,op0[15:0]+op2[15:0]};
        NEG: dout <= -op0;
        CPL: dout <= ~op0;
        EXTZ: dout <= w[1] ? {24'd0,op0[7:0]} : {16'd0,op0[15:0]};
        EXTS: dout <= w[1] ? {16'd0,{8{op0[7]}}, op0[7:0]} : {{16{op0[15]}},op0[15:0]};
        PAA: dout <= op0[0] ? op0+1'd1 : op0;
        // MUL, MULS, DIV, DIVS
        LDCF: carry <= op2[ op0[3:0] ];
        STCF: dout <= stcf;
        ANDCF: carry <= carry & op2[ op0[3:0] ]; // reuse for RCF - reset carry
        ORCF:  carry <= carry | op2[ op0[3:0] ]; // reuse for SCF - set carry
        XORCF: carry <= carry ^ op2[ op0[3:0] ];
        CCF:   carry <= ~carry;
        ZCF:   carry <= ~zero;
        TSET: begin // reuse for BIT
            zero <= ~op2[op0[3:0]];
            dout <= op0 | (16'd1<<op0[3:0]);
        end
        MIRR: dout <= {
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
        endcase
end

endmodule