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

module jt900h_regs(
    input             rst,
    input             clk,
    input             cen,
    input      [31:0] cr,       // control register
    // memory unit
    input      [23:0] ea,
    input      [31:0] din,      // data from memory controller
    // ALU
    input      [31:0] rslt,
    input             su,       // flag updates
    input             zu,
    input             hu,
    input             vu,
    input             nu,
    input             cu,
    // control
    input             bs,
    input             ws,
    input             qs,
    // register outputs
    output reg [23:0] pc,
    output reg [23:0] da,       // direct memory address from OP, like #8 in LD<W> (#8),#
    output     [31:0] op0,
    output     [31:0] op1,
);

`include "900h_param.vh"

localparam [3:0] XSP=6,
                  BC=4;

reg  [31:0] accs[0:15];
reg  [31:0] ptrs[0: 3];
reg  [ 7:0] r3sel, fsel, sdsel, src, dst;
wire [ 7:0] flags, flags_;
reg         s, z, h, v, n, c,    // flags (main)
            s_,z_,h_,v_,n_,c_,   // flags (alt)
reg  [ 2:0] imask;      // IFF
reg  [ 1:0] rfp;        // Register File Pointer
wire [15:0] sr;         // status register. lower byte contains the flags

assign flags   = {s, z, 1'b0,h, 1'b0,v, n, c };
assign flags_  = {s_,z_,1'b0,h_,1'b0,v_,n_,c_};
assign sr      = {1'b1,imask,2'b10,rfp,flags};

always @* begin
    // r3sel -> selects register from 3-bit R value in op
    r3sel = bs ? {2'd0,rfp,md[2:1],1'b0,~md[0]} :               // byte register
                 {mcode[2]?{4'hf:{2'd0,rfp},mcode[1:0],2'd0}} : // word/qword register
    casez( md[6:4] )
        3'b0??: fsel={2'd0,md[5:0]};
        3'b101: fsel={2'd0,rfp-2'd1,md[3:0]}; // previous bank
        3'b110: fsel={2'd0,rfp,     md[3:0]}; // current bank
        default:fsel=md;
    endcase
    // Register multiplexer
    sdsel = rmux_sel==DST_RMUX ? dst : src;
    sdmux = sdsel[7] ? ptrs[sdsel[5:2]] : accs[sdsel[3:2]]; // 32-bit registers
    sdsh  = bs ? {sdmux[1:0],3'd0} : ws ? {sdmux[1],4'd0} : 5'd0; // shift to select byte/word part as data
    case( rmux_sel )
        A_RMUX:   rmux = {16'd0, ws ? accs[{rfp,2'd1}]:8'd0, accs[{rfp,2'd0}][7:0]};
        BC_RMUX:  rmux = {16'd0, accs[{rfp,BC}][15:0]};
        CR_RMUX:  rmux = cr;
        F_RMUX:   rmux = alt ? flags_ : flags;
        PC_RMUX:  rmux = {8'd0,pc};
        RFP_RMUX: rmux[1:0] = rfp;
        XSP_RMUX: rmux = ptrs[XSP];

        SRC_RMUX, DST_RMUX: rmux = sdmux >> sdsh;
        N3_RMUX:  rmux = {29'd0,md[2:0]};
        N4_RMUX:  rmux = {28'd0,md[3:0]};

        ZERO_RMUX:rmux = 0;
        ONE_RMUX: rmux = 1;
        TWO_RMUX: rmux = 2;
        FOUR_RMUX:rmux = 4;

        EA_RMUX:  rmux = {8'd0,ea};
        default:  rmux = {qs?md[31:16]:16'd0,ws?md[15:8]:8'd0,md[7:0]};
    endcase
    // extend the sign
    if( ws & sex ) rmux[31: 8] = {24{rmux[ 7]}};
    if( qs & sex ) rmux[31:16] = {16{rmux[15]}};
    if( ws & zex ) rmux[31: 8] = 0;
    if( qs & zex ) rmux[31:16] = 0;
end

always @(posedge clk, posedge rst) begin
    if(rst) begin
        src   <= 0;
        dst   <= 0;
        op0   <= 0;
        op1   <= 0;
        rfp   <= 0;
        md    <= 0;
        pc    <= 0;
        imask <= 7;
        accs[ 0] <= 0; accs[ 1] <= 0; accs[ 2] <= 0; accs[ 3] <= 0;
        accs[ 4] <= 0; accs[ 5] <= 0; accs[ 6] <= 0; accs[ 7] <= 0;
        accs[ 8] <= 0; accs[ 9] <= 0; accs[10] <= 0; accs[11] <= 0;
        accs[12] <= 0; accs[13] <= 0; accs[14] <= 0; accs[15] <= 0;
        ptrs[ 0] <= 0; ptrs[ 1] <= 0; ptrs[ 2] <= 0; ptrs[ 3] <= 0;
        {s, z, h, v, n, c } <= 0;
        {s_,z_,h_,v_,n_,c_} <= 0;
    end else if(cen) begin
        if(exff) {s_,z_,h_,v_,n_,c_,s,z,h,v,n,c} <= {s,z,h,v,n,c,s_,z_,h_,v_,n_,c_};
        case( cc_sel )
            SZHVN0C_CC:     {s,z,h,v,n,c} <= {si,zi,hi,   vi,1'b0,ci  };
            SZHVN1C_CC:     {s,z,h,v,n,c} <= {si,zi,hi,   vi,1'b1,ci  };
            SZH0VN0C_CC:    {s,z,h,v,n,c} <= {si,zi,1'b0, vi,1'b0,ci  };
            SZH0VN0_CC:     {s,z,h,v,n  } <= {si,zi,1'b0, vi,1'b0     };
            SZHVN0_CC:      {s,z,h,v,n  } <= {si,zi,hi,   vi,1'b0     };
            SZHVN1_CC:      {s,z,h,v,n  } <= {si,zi,hi,   vi,1'b1     };
            SZH1PN0C0_CC:   {s,z,h,v,n,c} <= {si,zi,1'b1, pi,1'b0,1'b0};
            SZH0PN0C0_CC:   {s,z,h,v,n,c} <= {si,zi,1'b0, pi,1'b0,1'b0};
            ZCH1N0_CC:      {  z,h,  n  } <= {   ci,1'b1,    1'b0     }; // ci -> zi
            ZHN_CC:         {  z,h,  n  } <= {   zi,hi,      ni       };
            N0C_CC:         {        n,c} <= {               1'b0,ci  };
            H0N0C0_CC:      {    h,  n,c} <= {      1'b0,    1'b0,1'b0};
            H0N0C_CC:       {    h,  n,c} <= {      1'b0,    1'b0,ci  };
            H1N1_CC:        {    h,  n  } <= {      1'b1,    1'b1     };
            V_CC:           {      v    } <= {          vi            };
            C_CC:           {          c} <= {               ci       };
            Z2V_CC:         {      v    } <= {               zi       };
            Z3V_CC:         {      v    } <= {              ~zi       };
            SZV_CC:         {s,z,  v    } <= {si,zi,    vi            };
            SZHVCR_CC:      {s,z,h,v,  c} <= {si,zi,hi, vi,     c|ci  };
            H0V3N0_CC:      {    h,v,n  } <= {      1'b0,~zi,1'b0     };
            default:;
        endcase
        case( fetch_sel )
            Q_FETCH:  md <= din;
            S8_FETCH: md <= md>>8;
            default:;
        endcase
        case( ral_sel ) // Register Address Latch
            SRC_RAL: src <= r3sel;
            DST_RAL: dst <= full ? fsel : r3sel;
            SWP_RAL: {src,dst}<={dst,src};
            default:;
        endcase
        case( opnd_sel )
            LD0_OPND: op0 <= rmux;
            LD1_OPND: op1 <= rmux;
            SWP_OPND: {op0,op1} <= {op1,op0};
            default:;
        endcase
        case( ld_sel )
            DST_LD: begin
                if( bs ) begin
                    if( dst[7] ) case(dst[1:0])
                        0: ptrs[dst[3:2]][ 7: 0] <= rslt[7:0];
                        1: ptrs[dst[3:2]][15: 8] <= rslt[7:0];
                        2: ptrs[dst[3:2]][23:16] <= rslt[7:0];
                        3: ptrs[dst[3:2]][31:24] <= rslt[7:0];
                    endcase else case(dst[1:0])
                        0: accs[dst[5:2]][ 7: 0] <= rslt[7:0];
                        1: accs[dst[5:2]][15: 8] <= rslt[7:0];
                        2: accs[dst[5:2]][23:16] <= rslt[7:0];
                        3: accs[dst[5:2]][31:24] <= rslt[7:0];
                    endcase
                end else if( ws ) begin
                    if( dst[7] ) case(dst[1])
                        0: ptrs[dst[3:2]][15: 0] <= rslt[15:0];
                        1: ptrs[dst[3:2]][31:16] <= rslt[15:0];
                    endcase else case(dst[1])
                        0: accs[dst[5:2]][15: 0] <= rslt[15:0];
                        1: accs[dst[5:2]][31:16] <= rslt[15:0];
                    endcase
                end else begin
                    if( dst[7] )
                        ptrs[dst[3:2]] <= rslt;
                    else
                        accs[dst[5:2]] <= rslt[15:0];
                end
            end
            RFP_LD: rfp <= rslt[1:0];
            MD_LD:  md  <= rslt;
            A_LD:   begin
                accs[{rfp,2'd0}][7:0] <= rslt[7:0];
                if( ws ) accs[{rfp,2'd1}][15:8] <= rslt[15:8];
            end
            BC_LD:  accs[{rfp,BC}][15:0] <= rslt[15:0];
            F_LD:   {s,z,h,v,n,c} <= {rslt[7:6],rslt[4],rslt[2:0]};
            SR_LD:  {imask,rfp,s,z,h,v,n,c} <= {rslt[14:12],rslt[9:8],rslt[7:6],rslt[4],rslt[2:0]};
            PC_LD:  pc <= rslt[23:0];
            XSP_LD: ptrs[XSP] <= rslt;
            IFF_LD: imask <= rslt[2:0];
            DA_LD:  da <= rslt[23:0];
            default:;
        endcase
    end
end

endmodule