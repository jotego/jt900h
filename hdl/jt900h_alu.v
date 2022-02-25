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
    input      [31:0] acc,      // accumulator
    input      [31:0] op0,      // destination
    input      [31:0] op1,      // source
    input      [31:0] imm,      // alternative source
    input             sel_imm,
    input             flag_we,   // instructions that affect the flags
    output reg        flag_only, // flag_we delayed one clock
    input      [ 2:0] w,        // operation width
    output reg [ 2:0] alu_we,   // w delayed one clock
    input      [ 6:0] sel,      // operation selection
    input             bc_unity, // high when BC==1
    // multi-cycle operations
    output reg        busy,     // high if more cycles are needed
    // Flags
    output     [ 7:0] flags,
    output reg        nx_v,
    output reg        nx_z,
    output reg        djnz,

    output reg [31:0] dout
);

`include "jt900h.inc"

reg  [15:0] stcf;
reg  [31:0] op2, rslt;
reg         sign, zero, halfc, overflow, negative, carry;
reg  [ 5:0] fdash, nx_fdash; // shadow flags, F' in the documentation
reg         nx_s, nx_h, nx_n, nx_c, nx_djnz;
reg         nx_busy, busyl, busy_cen;
reg  [ 2:0] cc;
wire        is_zero, rslt_sign, op0_s, op1_s, rslt_c, rslt_v, rslt_even;
wire        imm_s;
reg  [32:0] ext_op0, ext_op2, ext_rslt;
reg  [ 4:0] nx_cnt, cnt;
wire        shr_msb, shl_lsb, shrx_msb, shlx_lsb;
wire [15:0] rld, rrd, rr_result;

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
assign op0_s    = w[0] ? op0[7] : w[1] ? op0[15] : op0[31];
assign op1_s    = w[0] ? op1[7] : w[1] ? op1[15] : op1[31];
assign imm_s    = w[0] ? imm[7] : w[1] ? imm[15] : imm[31];
assign shr_msb  = sel==ALU_RR ? carry : sel==ALU_SRA ? op0_s : 1'b0;
assign shl_lsb  = sel==ALU_RL && carry;
assign shrx_msb = sel==ALU_RRX ? carry : sel==ALU_SRAX ? imm_s : 1'b0;
assign shlx_lsb = sel==ALU_RLX && carry;

assign rld = { acc[7:4], imm[7:0], acc[3:0] };
assign rrd = { acc[7:4], imm[3:0], acc[3:0], imm[7:4] };
assign rr_result = sel==ALU_RLD ? rld : rrd;


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
    nx_fdash = fdash;
    rslt = dout;
    ext_op0 = extend(op0);
    ext_op2 = extend(op2);
    ext_rslt = 0; // assign it for operations that alter the V bit
    nx_djnz  = djnz;
    nx_busy  = 0;
    nx_cnt   = 0;
    cc = 0;

    case( sel )
        default:;
        ALU_MOVE: rslt = op2;
        ALU_ADD, ALU_ADC, ALU_INC: // also INC on register, also MULA
        begin // checking w prevents executing twice the same inst.
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[ 3: 0]}+{1'b0,op2[ 3: 0]} + { 4'd0, sel==ALU_ADC?carry : 1'b0};
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}+{1'b0,op2[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}+{1'b0,op2[15: 8]}+{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}+{1'b0,op2[31:16]}+{16'b0,cc[1]};
            ext_rslt = ext_op0 + ext_op2;
            if( sel!=ALU_INC || w[0]  ) begin
                nx_s = rslt_sign;
                nx_z = is_zero;
                nx_n = 0;
                nx_v = rslt_v;
            end
            if (sel!=ALU_INC ) begin
                nx_c = rslt_c;
            end
        end
        ALU_INCX: // INC on memory
        begin // checking w prevents executing twice the same inst.
            { nx_h,  rslt[ 3: 0] } = {1'b0,imm[ 3: 0]}+{2'b0,imm[18:16]};
            { cc[0], rslt[ 7: 4] } = {1'b0,imm[ 7: 4]}+{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,imm[15: 8]}+{ 8'b0,cc[0]};
            // The documentation only sets a limit to flag changes for INC #3,r
            // Not for INC<W> #3,(mem)
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_n = 0;
            nx_v = rslt_sign ^ (w[0] ? ^op2[7] : op2[15]);
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
        ALU_OR, ALU_XOR: begin
            rslt = sel==ALU_OR ? op0 | op2 : op0 ^ op2;
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
        ALU_SUB, ALU_SBC, ALU_CP, ALU_DEC, ALU_CPD:
        begin
            { nx_h,  rslt[ 3: 0] } = {1'b0,op0[3:0]} - {1'b0,op2[3:0]} - { 4'd0, sel==ALU_SBC?carry : 1'b0};
            { cc[0], rslt[ 7: 4] } = {1'b0,op0[ 7: 4]}-{1'b0,op2[ 7: 4]}-{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,op0[15: 8]}-{1'b0,op2[15: 8]}-{ 8'b0,cc[0]};
            { cc[2], rslt[31:16] } = {1'b0,op0[31:16]}-{1'b0,op2[31:16]}-{16'b0,cc[1]};
            ext_rslt = ext_op0 - ext_op2;
            if( sel!=ALU_DEC || w[0]  ) begin
                nx_s = rslt_sign;
                nx_z = is_zero;
                nx_n = 1;
                nx_v = sel==ALU_CPD ? ~bc_unity : rslt_v;
            end
            if( sel!=ALU_DEC && sel!=ALU_CPD ) begin
                nx_c = rslt_c;
            end
        end
        ALU_LDD: begin
            rslt = imm;
            nx_h = 0;
            nx_n = 0;
            nx_v = ~bc_unity;
        end
        ALU_DECX: // DEC on memory
        begin // checking w prevents executing twice the same inst.
            { nx_h,  rslt[ 3: 0] } = {1'b0,imm[ 3: 0]}-{2'b0,imm[18:16]};
            { cc[0], rslt[ 7: 4] } = {1'b0,imm[ 7: 4]}-{ 4'b0,nx_h};
            { cc[1], rslt[15: 8] } = {1'b0,imm[15: 8]}-{ 8'b0,cc[0]};
            // The documentation only sets a limit to flag changes for DEC #3,r
            // Not for DEC<W> #3,(mem)
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_n = 1;
            nx_v = rslt_sign ^ (w[0] ? ^op2[7] : op2[15]);
        end
        ALU_BIT: begin
            nx_z = ~op1[ {1'b0,imm[3:0]} ];
            nx_n = 0;
            nx_h = 1;
        end
        ALU_BITX: begin
            nx_z = ~imm[ {2'b0,imm[10:8]} ];
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
        ALU_ZCF: begin
            nx_c = ~zero;
            nx_n = 0;
        end
        ALU_CCF: begin
            nx_c = ~carry;
            nx_n = 0;
        end
        ALU_SCF: begin
            nx_c = 1;
            nx_n = 0;
            nx_h = 0;
        end
        ALU_RCF: begin
            nx_c = 0;
            nx_n = 0;
            nx_h = 0;
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
        ALU_EXFF: begin // exchange F and F'
            nx_fdash = { sign, zero, halfc, overflow, negative, carry };
            { nx_s, nx_z, nx_h, nx_v, nx_n, nx_c } = fdash;
        end
        ALU_MIRR: begin
            rslt[15:0] = {
                op0[0], op0[1], op0[2], op0[3], op0[4], op0[5], op0[6], op0[7],
                op0[8], op0[9], op0[10], op0[11], op0[12], op0[13], op0[14], op0[15]
            };
        end
        ALU_NEG: begin
            rslt = -op0;
            nx_s = rslt_sign;
            nx_z = is_zero;
            nx_n = 1;
            nx_c = rslt_c;
            nx_v = rslt_v;
        end
        ALU_RES: begin
            rslt = op0;
            rslt[ {1'b0,op2[3:0]} ] = 0;
        end
        ALU_RESX: begin
            rslt = imm;
            rslt[ {2'b0,imm[10:8]} ] = 0;
        end
        ALU_SET: begin
            rslt = op0;
            rslt[ {1'b0,op2[3:0]} ] = 1;
        end
        ALU_SETX: begin
            rslt = imm;
            rslt[ {2'b0,imm[10:8]} ] = 1;
        end
        ALU_TSET: begin
            rslt = op0;
            rslt[ {1'b0,op2[3:0]} ] = 1;
            nx_z = ~op0[{1'b0,op2[3:0]}];
            nx_n = 0;
            nx_h = 1;
        end
        ALU_TSETX: begin
            rslt = imm;
            rslt[ {2'b0,imm[10:8]} ] = 1;
            nx_z = ~op0[{2'b0,imm[10:8]}];
            nx_n = 0;
            nx_h = 1;
        end
        ALU_LDCF: begin
            nx_c = op0[ {1'b0,op2[3:0]} ];
        end
        ALU_LDCFX: begin
            nx_c = imm[ {2'b0,imm[10:8]} ];
        end
        ALU_LDCFA: begin
            nx_c = imm[ {2'b0,op1[2:0]} ];
        end
        ALU_XORCF: begin
            nx_c = carry ^ op0[ {1'b0,op2[3:0]} ];
        end
        ALU_XORCFX: begin
            nx_c = carry ^ imm[ {2'b0,imm[10:8]} ];
        end
        ALU_XORCFA: begin
            nx_c = carry ^ imm[ {2'b0,op1[2:0]} ];
        end
        ALU_ORCF: begin
            nx_c = carry | op0[ {1'b0,op2[3:0]} ];
        end
        ALU_ORCFX: begin
            nx_c = carry | imm[ {2'b0,imm[10:8]} ];
        end
        ALU_ORCFA: begin
            nx_c = carry | imm[ {2'b0,op1[2:0]} ];
        end
        ALU_ANDCF: begin
            nx_c = carry & op0[ {1'b0,op2[3:0]} ];
        end
        ALU_ANDCFX: begin
            nx_c = carry & imm[ {2'b0,imm[10:8]} ];
        end
        ALU_ANDCFA: begin
            nx_c = carry & imm[ {2'b0,op1[2:0]} ];
        end
        ALU_RLD, ALU_RRD: begin
            rslt = {16'd0, rr_result };
            nx_s = acc[7];
            nx_z = rr_result[15:8]==0;
            nx_h = 0;
            nx_v = ^rr_result[15:8];
            nx_n = 0;
        end
        ALU_RLC, ALU_RRC, ALU_RL, ALU_RR, ALU_SLA, ALU_SRA, ALU_SLL, ALU_SRL: begin
            case( sel )
                ALU_RL,ALU_SLA,ALU_SLL: begin
                    if( w[0] )
                        { nx_c, rslt[7:0] } = { op0[7:0], shl_lsb };
                    else if( w[1] )
                        { nx_c, rslt[15:0] } = { op0[15:0], shl_lsb };
                    else
                        { nx_c, rslt[31:0] } = { op0[31:0], shl_lsb };
                end
                ALU_RR,ALU_SRA,ALU_SRL: begin
                    if( w[0] )
                        { rslt[ 7:0], nx_c } = { shr_msb, op0[7:0] };
                    else if( w[1] )
                        { rslt[15:0], nx_c } = { shr_msb, op0[15:0] };
                    else
                        { rslt[31:0], nx_c } = { shr_msb, op0[31:0] };
                end
                ALU_RLC: begin
                    if( w[0] )
                        rslt[7:0] = { op0[6:0], op0[7] };
                    else if( w[1] )
                        rslt[15:0] = { op0[14:0], op0[15] };
                    else
                        rslt[31:0] = { op0[30:0], op0[31] };
                    nx_c = op0_s;
                end
                ALU_RRC: begin
                    if( w[0] )
                        rslt[7:0] = { op0[0], op0[7:1] };
                    else if( w[1] )
                        rslt[15:0] = { op0[0], op0[15:1] };
                    else
                        rslt[31:0] = { op0[0], op0[31:1] };
                    nx_c = op0[0];
                end
                default:;
            endcase
            nx_z = is_zero;
            nx_s = rslt_sign;
            nx_h = 0;
            nx_v = rslt_even;
            nx_n = 0;
            if( !busy ) begin
                nx_busy = op2[3:0]!=1;
                nx_cnt = { op2[3:0]==0, op2[3:0]};
            end else begin
                nx_busy = cnt > 1;
                nx_cnt  = cnt-5'd1;
            end
        end
        ALU_RLCX, ALU_RRCX, ALU_RLX, ALU_RRX, ALU_SLAX, ALU_SRAX, ALU_SLLX, ALU_SRLX: begin
            case( sel )
                ALU_RLX,ALU_SLAX,ALU_SLLX: begin
                    if( w[0] )
                        { nx_c, rslt[7:0] } = { imm[7:0], shlx_lsb };
                    else
                        { nx_c, rslt[15:0] } = { imm[15:0], shlx_lsb };
                end
                ALU_RRX,ALU_SRAX,ALU_SRLX: begin
                    if( w[0] )
                        { rslt[ 7:0], nx_c } = { shrx_msb, imm[7:0] };
                    else
                        { rslt[15:0], nx_c } = { shrx_msb, imm[15:0] };
                end
                ALU_RLCX: begin
                    if( w[0] ) begin
                        rslt[7:0] = { imm[6:0], imm[7] };
                        nx_c = imm[6];
                    end else begin
                        rslt[15:0] = { imm[14:0], imm[15] };
                        nx_c = imm[15];
                    end
                end
                ALU_RRCX: begin
                    if( w[0] )
                        rslt[7:0] = { imm[0], imm[7:1] };
                    else
                        rslt[15:0] = { imm[0], imm[15:1] };
                    nx_c = imm[0];
                end
                default:;
            endcase
            nx_z = is_zero;
            nx_s = rslt_sign;
            nx_h = 0;
            nx_v = rslt_even;
            nx_n = 0;
        end
    endcase
end

reg flag_wel;
wire busy_end;

//assign busy_end = busy && cnt==0;
assign busy_end = busyl & ~busy;

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
        flag_only<= 0;
        djnz     <= 0;
        flag_wel <= 0;
        busy     <= 0;
        busyl    <= 0;
        busy_cen <= 0;
        cnt      <= 0;
        fdash    <= 0;
    end else if(cen) begin
        flag_wel <= flag_we;
        busyl    <= busy;
        if( w!=0 ) begin // checking w prevents executing twice the same inst.
            dout      <= rslt;
        end
        if( (w!=0 || (flag_we && !flag_wel)) && ((!busy && !busyl) || busy_cen)) begin
            sign     <= nx_s;
            zero     <= nx_z;
            halfc    <= nx_h;
            overflow <= nx_v;
            negative <= nx_n;
            carry    <= nx_c;
            fdash    <= nx_fdash;
            djnz     <= nx_djnz;
            busy     <= nx_busy;
            cnt      <= nx_cnt;
        end
        flag_only <= flag_we;
        alu_we    <= (busyl && cnt<=1) ? 0 : w;
        busy_cen  <= busy ? ~busy_cen : 1'b1;
    end
end

endmodule