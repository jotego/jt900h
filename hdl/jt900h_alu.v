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
    input      [31:0] op0,      // destination
    input      [31:0] op1,      // source
    input      [31:0] imm,      // alternative source
    input             sel_imm,
    input             flag_we,   // instructions that affect the flags
    input      [ 2:0] w,        // operation width
    output reg [ 2:0] alu_we,
    input      [ 5:0] sel,      // operation selection
    // Flags
    output     [ 7:0] flags,
    output reg        djnz,

    output reg [31:0] dout
);

`include "jt900h.inc"

reg  [15:0] stcf;
reg  [31:0] op2, rslt;
reg         sign, zero, halfc, overflow, negative, carry;
reg         nx_s, nx_z, nx_h, nx_v, nx_n, nx_c, nx_djnz;
reg  [ 2:0] cc;
wire        is_zero, rslt_sign, op0_s, op1_s, rslt_c, rslt_v, rslt_even;
reg  [32:0] ext_op0, ext_op2, ext_rslt;

function [32:0] extend( input [31:0] x );
    extend = w[0] ? { {25{x[ 7]}}, x[ 7:0] } :
             w[1] ? { {17{x[15]}}, x[15:0] } : { x[31], x };
endfunction

assign flags   = {sign, zero, 1'b0, halfc, 1'b0, overflow, negative, carry};
assign is_zero = w[0] ? rslt[7:0]==0 : w[1] ? rslt[15:0]==0 : rslt[31:0]==0;
assign rslt_sign = w[0] ? rslt[7] : w[1] ? rslt[15] : rslt[31];
assign rslt_c  = w[0] ? cc[0] : w[1] ? cc[1] : cc[2];
assign rslt_v  = w[0] ? ext_rslt[32]^rslt[ 7] :
                 w[1] ? ext_rslt[32]^rslt[15] :
                        ext_rslt[32]^rslt[31];
assign rslt_even = w[0] ? ~^rslt[7:0] : ~^rslt[15:0];
assign op0_s   = w[0] ? op0[7] : w[1] ? op0[15] : op0[31];
assign op1_s   = w[0] ? op1[7] : w[1] ? op1[15] : op1[31];

always @* begin
//    stcf = op1;
//    stcf[op0[3:0]] = carry;
//
    op2 = sel_imm ? imm : op1;
end

always @* begin
    nx_s = sign;
    nx_z = zero;
    nx_h = halfc;
    nx_v = overflow;
    nx_n = negative;
    nx_c = carry;
    rslt = dout;
    ext_op0 = extend(op0);
    ext_op2 = extend(op2);
    ext_rslt = 0; // assign it for operations that alter the V bit
    nx_djnz  = djnz;
    cc = 0;

    case( sel )
        default:;
        ALU_MOVE: rslt = op2;
        ALU_ADD, ALU_ADC: // also INC, also MULA
        begin // checking w prevents executing twice the same inst.
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}+{1'b0,op2[ 3: 0]} + { 4'd0, sel==ALU_ADC?carry : 1'b0};
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op2[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op2[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op2[31:16]}+{16'b0,cc[1]};
            ext_rslt = ext_op0 + ext_op2;
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_n = 0;
            nx_c = rslt_c;
            nx_v = rslt_v;
        end
        ALU_AND: begin // use it for RES bit,dst too?
            rslt = op0 & op2;
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_h = 1;
            nx_v = rslt_even;
            nx_n = 0;
            nx_c = 0;
        end
        ALU_OR: begin
            rslt = op0 | op2;
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_h = 0;
            nx_v = rslt_even;
            nx_n = 0;
            nx_c = 0;
        end
        ALU_MDEC1: begin
            if( (op0[15:0] & op2[15:0]) ==0 )
                rslt[15:0] = op0[15:0] + op2[15:0];
            else begin
                rslt[15:0] = op0[15:0] - 16'd1;
            end
        end
        ALU_MDEC2: begin
            if( (op0[15:0] & op2[15:0]) ==0 )
                rslt[15:0] = op0[15:0] + op2[15:0];
            else begin
                rslt[15:0] = op0[15:0] - 16'd2;
            end
        end
        ALU_MDEC4: begin
            if( (op0[15:0] & op2[15:0]) ==0 )
                rslt[15:0] = op0[15:0] + op2[15:0];
            else begin
                rslt[15:0] = op0[15:0] - 16'd4;
            end
        end
        ALU_SUB, ALU_SBC, ALU_CP:
        begin
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[3:0]} - {1'b0,op2[3:0]} - { 4'd0, sel==ALU_SBC?carry : 1'b0};
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}-{1'b0,op2[ 7: 4]}-{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}-{1'b0,op2[15: 8]}-{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}-{1'b0,op2[31:16]}-{16'b0,cc[1]};
            ext_rslt = ext_op0 - ext_op2;
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_n = 1;
            nx_c = rslt_c;
            nx_v = rslt_v;
        end
        ALU_BIT: begin
            nx_z = ~op1[ {1'b0,imm[3:0]} ];
            nx_n = 0;
            nx_h = 1;
        end
        ALU_BITX: begin
            nx_z = ~imm[ {2'b0,imm[11:9]} ];
            nx_n = 0;
            nx_h = 1;
        end
        ALU_BS1F: begin
            casez(op1[15:0])
                16'b????_????_????_???1: rslt = 0;
                16'b????_????_????_?010: rslt = 1;
                16'b????_????_????_?100: rslt = 2;
                16'b????_????_????_1000: rslt = 3;
                16'b????_????_???1_0000: rslt = 4;
                16'b????_????_??10_0000: rslt = 5;
                16'b????_????_?100_0000: rslt = 6;
                16'b????_????_1000_0000: rslt = 7;
                16'b????_???1_0000_0000: rslt = 8;
                16'b????_??10_0000_0000: rslt = 9;
                16'b????_?100_0000_0000: rslt = 10;
                16'b????_1000_0000_0000: rslt = 11;
                16'b???1_0000_0000_0000: rslt = 12;
                16'b??10_0000_0000_0000: rslt = 13;
                16'b?100_0000_0000_0000: rslt = 14;
                16'b1000_0000_0000_0000: rslt = 15;
                default: rslt=0;
            endcase
            nx_v = op1[15:0]==0;
        end
        ALU_BS1B: begin
            casez(op1[15:0])
                16'b1???_????_????_????: rslt = 15;
                16'b01??_????_????_????: rslt = 14;
                16'b001?_????_????_????: rslt = 13;
                16'b0001_????_????_????: rslt = 12;
                16'b0000_1???_????_????: rslt = 11;
                16'b0000_01??_????_????: rslt = 10;
                16'b0000_001?_????_????: rslt = 9;
                16'b0000_0001_????_????: rslt = 8;
                16'b0000_0000_1???_????: rslt = 7;
                16'b0000_0000_01??_????: rslt = 6;
                16'b0000_0000_001?_????: rslt = 5;
                16'b0000_0000_0001_????: rslt = 4;
                16'b0000_0000_0000_1???: rslt = 3;
                16'b0000_0000_0000_01??: rslt = 2;
                16'b0000_0000_0000_0010: rslt = 1;
                16'b0000_0000_0000_0001: rslt = 0;
                default: rslt=0;
            endcase
            nx_v = op1[15:0]==0;
        end
        ALU_CCF: begin
            nx_c = ~carry;
            nx_n = 0;
        end
        ALU_CHG: begin
            rslt = op0;
            rslt[ {1'b0,imm[3:0]} ] = ~rslt[ {1'b0,imm[3:0]} ];
        end
        ALU_CPL: begin
            rslt = ~op2;
            nx_h = 1;
            nx_n = 1;
        end
        // ALU_DEC: begin
        //     rslt =
        // end

        ALU_DJNZ: begin
            if( w[1] ) begin
                rslt[15:0] = op0[15:0] - 16'd1;
                nx_djnz    = rslt[15:0]==0;
            end else begin
                rslt[7:0] = op0[ 7:0] - 8'd1;
                nx_djnz   = rslt[7:0]==0;
            end
        end
        ALU_EXTS: begin
            if( w[1] )
                rslt[15:0] = {{8{op0[7]}}, op0[7:0]};
            else
                rslt       = {{16{op0[15]}},op0[15:0]};
        end
        ALU_EXTZ: begin
            if( w[1] )
                rslt[15:0] = {8'd0, op0[7:0]};
            else
                rslt       = {16'd0,op0[15:0]};
        end
        // ALU_XOR: rslt = op0^op2; // use it for CHG bit,dst too?
        // Control unit should set op2 so MINC1,MINC2,MINC4 and MDEC1/2/4
        // can be performed
        /*
        NEG: rslt = -op0;
        PAA: rslt = op0[0] ? op0+1'd1 : op0;
        // MUL, MULS, DIV, DIVS
        LDCF: carry <= op2[ op0[3:0] ];
        STCF: rslt = stcf;
        ANDCF: carry <= carry & op2[ op0[3:0] ]; // reuse for RCF - reset carry
        ORCF:  carry <= carry | op2[ op0[3:0] ]; // reuse for SCF - set carry
        XORCF: carry <= carry ^ op2[ op0[3:0] ];
        ZCF:   carry <= ~zero;
        TSET: begin // reuse for BIT
            zero <= ~op2[op0[3:0]];
            rslt = op0 | (16'd1<<op0[3:0]);
        end
        MIRR: rslt = {
                op[0], op[1], op[2], op[3], op[4], op[5], op[6], op[7],
                op[8], op[9], op[10], op[11], op[12], op[13], op[14], op[15],
            };*/
        endcase
end

always @(posedge clk, posedge rst)  begin
    if( rst ) begin
        dout     <= 0;
        sign     <= 0;
        zero     <= 0;
        halfc    <= 0;
        overflow <= 0;
        negative <= 0;
        carry    <= 0;
        alu_we   <= 0;
        djnz     <= 0;
    end else if(cen) begin
        if( w!=0 ) begin // checking w prevents executing twice the same inst.
            dout     <= rslt;
        end
        if( w!=0 || flag_we ) begin
            sign     <= nx_s;
            zero     <= nx_z;
            halfc    <= nx_h;
            overflow <= nx_v;
            negative <= nx_n;
            carry    <= nx_c;
            djnz     <= nx_djnz;
        end
        alu_we <= w;
    end
end

endmodule