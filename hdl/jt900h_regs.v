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
    // memory unit
    input      [31:0] ea,
    input      [31:0] din,      // data from memory controller
    output     [31:0] xsp,
    output reg [31:0] md,
    // ALU
    input      [31:0] rslt,
    input             zi,hi,vi,ni,ci,pi, // flag updates
    output            no,ho,co,zo,
    // control (from module logic)
    input             cc,
    output      [7:0] flags,
    output reg  [2:0] riff,      // IFF
    input      [ 2:0] int_lvl,
    input      [ 7:0] int_addr,
    // control (from ucode)
    input             bs,
    input             exff,
    input             alt,
    input             inc_pc,
    input             mul,
    input             mulcheck,
    input             qs,
    input             sex,
    input             ws,
    input             zex,
    input       [1:0] opnd_sel,
    input       [1:0] fetch_sel,
    input       [2:0] ral_sel,
    input       [3:0] ld_sel,
    input       [4:0] cc_sel,
    input       [3:0] rmux_sel,
    // "Control Registers" (MCU MMR)
    output reg [ 7:0] cra,
    output reg [31:0] crin,
    input      [31:0] cr,
    output reg        cr_we,    // cr_rd goes directly from control unit
    // register outputs
    output reg [23:0] pc,
    output reg [31:0] da,       // direct memory address from OP, like #8 in LD<W> (#8),#
    output reg [31:0] op0,
    output reg [31:0] op1,
    output reg [31:0] op2,
    // Register dump
    input      [ 7:0] dmp_addr,
    output     [ 7:0] dmp_dout
);

`include "900h_param.vh"

localparam [1:0] XSP=3;
localparam [1:0] BC=1;

reg  [31:0] sdmux, rmux;
reg  [31:0] accs[0:15];
reg  [31:0] ptrs[0: 3];
wire [31:0] dmp_mux;
reg  [ 7:0] r3sel, fsel, sdsel, mulsel,
            src, dst; // RALs (Register Address Latches)
reg  [ 4:0] sdsh;
reg         s, z, h, v, n, c,    // flags (main)
            s_,z_,h_,v_,n_,c_;   // flags (alt)
reg  [ 1:0] rfp;        // Register File Pointer
wire [15:0] sr;         // status register. lower byte contains the flags
reg         is_mul;

assign flags   = {s, z, 1'b0,h, 1'b0,v, n, c };
assign sr      = {1'b1,riff,2'b10,rfp,flags};
assign {no,ho,co,zo} = {n,h,c,z};
assign xsp     = ptrs[XSP];

assign dmp_mux  = dmp_addr[7:6]!=0 ? ptrs[dmp_addr[3:2]] : accs[dmp_addr[5:2]];
assign dmp_dout = dmp_addr==8'd80 ? sr[15:8] :
                  dmp_addr==8'd81 ? sr[ 7:0] :
                                    dmp_mux[{dmp_addr[1:0],3'b0}+:8];

`ifdef SIMULATION
    wire [31:0] xwa0 /* verilator public */, xbc0 /* verilator public */, xde0 /* verilator public */, xhl0 /* verilator public */,
                xwa1 /* verilator public */, xbc1 /* verilator public */, xde1 /* verilator public */, xhl1 /* verilator public */,
                xwa2 /* verilator public */, xbc2 /* verilator public */, xde2 /* verilator public */, xhl2 /* verilator public */,
                xwa3 /* verilator public */, xbc3 /* verilator public */, xde3 /* verilator public */, xhl3 /* verilator public */,
                xix  /* verilator public */, xiy  /* verilator public */, xiz  /* verilator public */;
    assign { xwa3, xwa2, xwa1, xwa0 } = {accs[{2'd3,2'd0}],accs[{2'd2,2'd0}],accs[{2'd1,2'd0}],accs[{2'd0,2'd0}]};
    assign { xbc3, xbc2, xbc1, xbc0 } = {accs[{2'd3,2'd1}],accs[{2'd2,2'd1}],accs[{2'd1,2'd1}],accs[{2'd0,2'd1}]};
    assign { xde3, xde2, xde1, xde0 } = {accs[{2'd3,2'd2}],accs[{2'd2,2'd2}],accs[{2'd1,2'd2}],accs[{2'd0,2'd2}]};
    assign { xhl3, xhl2, xhl1, xhl0 } = {accs[{2'd3,2'd3}],accs[{2'd2,2'd3}],accs[{2'd1,2'd3}],accs[{2'd0,2'd3}]};
    assign { xix,  xiy,  xiz } = { ptrs[0], ptrs[1], ptrs[2] };
`endif

always @* begin
    // r3sel -> selects register from 3-bit R value in op
    r3sel = bs ? {             2'd0,rfp, md[2:1],1'b0,~md[0]} : // byte register
                 {md[2]?4'hf:{2'd0,rfp}, md[1:0],2'd0};         // word/qword register
    mulsel = bs ? { 2'd0, rfp, md[2:1], 2'd0 } :
          md[2] ? { 4'hf,      md[1:0], 2'd0 } :
                  { 2'd0, rfp, md[1:0], 2'd0 } ; // pointers
    is_mul = mulcheck && md[15:10]==6'h2; // detects MUL/DIV(s) rr,#
    casez( md[6:4] )
        3'b0??: fsel={2'd0,md[5:0]};
        3'b101: fsel={2'd0,rfp-2'd1,md[3:0]}; // previous bank
        3'b110: fsel={2'd0,rfp,     md[3:0]}; // current bank
        default:fsel=md[7:0];
    endcase
    if(qs) fsel[1:0]=0;     // bs/ws/qs must be set before loading the RAL
    if(ws) fsel[  0]=0;
    // Register multiplexer
    sdsel = rmux_sel==DST_RMUX ? dst : src;
    sdmux = sdsel[7] ? ptrs[sdsel[3:2]] : accs[sdsel[5:2]]; // 32-bit registers
    sdsh  = qs | alt ? 5'd0 : bs ? {sdsel[1:0],3'd0} : {sdsel[1],4'd0}; // shift to select byte/word part as data. alt selects long word
    rmux  = md;
    case( rmux_sel )
        BC_RMUX:  rmux = {16'd0, accs[{rfp,BC}][15:0]};
        CR_RMUX:  rmux = cr;
        SR_RMUX:  rmux = alt ? {29'd0, int_lvl  } : { 16'd0, sr };
        PC_RMUX:  rmux = alt ? {24'd0, int_addr } : {  8'd0, pc };
        RFP_RMUX: rmux[1:0] = rfp;
        XSP_RMUX: rmux = ptrs[XSP];
        CC_RMUX:  rmux = {31'd0,cc};
        SRC_RMUX, DST_RMUX: rmux = sdmux >> sdsh;
        N3_RMUX:  rmux = {28'd0, alt&&md[2:0]==0, md[2:0]};
        N4_RMUX:  rmux = {28'd0, md[3:0]};

        ZERO_RMUX:rmux = 0;
        SPD_RMUX: rmux = bs ? 1 : ws ? 2 : 4;

        EA_RMUX:  rmux = ea;
        default:  rmux = md;
    endcase
    // extend the sign
    if( bs & sex ) rmux[31: 8] = {24{rmux[ 7]}};
    if( ws & sex ) rmux[31:16] = {16{rmux[15]}};
    if( bs & zex ) rmux[31: 8] = 0;
    if( ws & zex ) rmux[31:16] = 0;
    if( qs & zex & alt) rmux[31:24] = 0; // used for loading #24 addresses
end

always @(posedge clk, posedge rst) begin
    if(rst) begin
        src   <= 0;
        dst   <= 0;
        op0   <= 0;
        op1   <= 0;
        op2   <= 0;
        rfp   <= 0;
        md    <= 0;
        pc    <= 0;
        da    <= 0;
        riff  <= 7;
        cr_we <= 0;
        accs[ 0] <= 0; accs[ 1] <= 0; accs[ 2] <= 0; accs[ 3] <= 0;
        accs[ 4] <= 0; accs[ 5] <= 0; accs[ 6] <= 0; accs[ 7] <= 0;
        accs[ 8] <= 0; accs[ 9] <= 0; accs[10] <= 0; accs[11] <= 0;
        accs[12] <= 0; accs[13] <= 0; accs[14] <= 0; accs[15] <= 0;
        ptrs[ 0] <= 0; ptrs[ 1] <= 0; ptrs[ 2] <= 0; ptrs[ 3] <= 32'h100;
        {s, z, h, v, n, c } <= 0;
        {s_,z_,h_,v_,n_,c_} <= 0;
    end else if(cen) begin
        cr_we <= 0;
        if(exff) {s_,z_,h_,v_,n_,c_,s,z,h,v,n,c} <= {s,z,h,v,n,c,s_,z_,h_,v_,n_,c_};
        if(inc_pc) pc <= pc + 24'd1;
        case( cc_sel )
            0:;
            C_CC:            {          c} <= {               ci       };
            H0N0C_CC:        {    h,  n,c} <= {      1'b0,    1'b0,ci  };
            H0V3N0_CC:       {    h,v,n  } <= {      1'b0,~zi,1'b0     };
            H1N1_CC:         {    h,  n  } <= {      1'b1,    1'b1     };
            N0C_CC:          {        n,c} <= {               1'b0,ci  };
            SZH0PN0_CC:      {s,z,h,v,n  } <= {ni,zi,1'b0, pi,1'b0     };
            SZH0PN0C0_CC:    {s,z,h,v,n,c} <= {ni,zi,1'b0, pi,1'b0,1'b0};
            SZH0PN0C_CC:     {s,z,h,v,n,c} <= {ni,zi,1'b0, pi,1'b0,ci  };
            SZH1PN0C0_CC:    {s,z,h,v,n,c} <= {ni,zi,1'b1, pi,1'b0,1'b0};
            SZHN1_CC:        {s,z,h,  n  } <= {ni,zi,hi,      1'b1     };
            SZHVCR_CC:       {s,z,h,v,  c} <= {ni,zi,hi, vi,     c|ci  };
            SZHVN0_CC: if(bs){s,z,h,v,n  } <= {ni,zi,hi,   vi,1'b0     }; // INC, only applies to byte operands
            SZHVN0C_CC:      {s,z,h,v,n,c} <= {ni,zi,hi,   vi,1'b0,ci  };
            SZHVN1C_CC:      {s,z,h,v,n,c} <= {ni,zi,hi,   vi,1'b1,ci  };
            SZHVN1D_CC:if(bs){s,z,h,v,n  } <= {ni,zi,hi,   vi,1'b1     }; // DEC, only applies to byte operands
            SZV_CC:          {s,z,  v    } <= {ni,zi,    vi            };
            V_CC:            {      v    } <= {          vi            };
            Z2V_CC:          {      v    } <= {               zi       };
            Z3V_CC:          {      v    } <= {           ~zi          }; // CPD/CPI
            ZCH1N0_CC:       {  z,h,  n  } <= {   ci,1'b1,    1'b0     }; // ci -> zi
        endcase
        case( fetch_sel )
            VS_FETCH, Q_FETCH: md <= din;
            S8_FETCH:          md <= md>>8;
            default:;
        endcase
        case( ral_sel ) // Register Address Latch
            SRC_RAL:  src <= r3sel;
            A_RAL:    src <= {2'b0,rfp,4'b0};
            DST_RAL:  dst <= alt ? fsel : (mul|is_mul) ? mulsel : r3sel;
            XSRC_RAL: src <= dst & ~8'h04; // if dst=XHL, src<-XDE, if dst=XIY, src<-XIX
            XDE_RAL:  src <= {2'b0,rfp,4'h8};
            XHL_RAL:  src <= {2'b0,rfp,4'hc};
            SWP_RAL:  {src,dst}<={dst,src};
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
                        accs[dst[5:2]] <= rslt;
                end
            end
            DSTQ_LD: if(dst[7]) ptrs[dst[3:2]] <= rslt; else accs[dst[5:2]] <= rslt;
            RFP_LD: rfp <= rslt[1:0];
            MD_LD:  md  <= rslt;
            A_LD:   begin
                accs[{rfp,2'd0}][7:0] <= {alt ? 4'd0 : rslt[7:4], rslt[3:0]};
                if( ws ) accs[{rfp,2'd1}][15:8] <= rslt[15:8];  // loads into BC!
            end
            BC_LD:  accs[{rfp,BC}][15:0] <= rslt[15:0];
            OP2_LD: op2 <= rslt;
            SR_LD:  begin
                if( ws ) {riff,rfp} <= {rslt[14:12],rslt[9:8]};
                {s,z,h,v,n,c} <= {rslt[7:6],rslt[4],rslt[2:0]};
            end
            PC_LD:   pc <= rslt[23:0];
            XSP_LD:  ptrs[XSP] <= rslt;
            IFF_LD:  riff <= rslt[2:0];
            IFF7_LD: riff <= rslt[2:0]==0 ? 3'b111 : rslt[2:0];
            DA_LD:   da   <= rslt;
            DAS_LD:  da   <= { qs ? rslt[31:16]:16'd0, (qs|ws) ? rslt[15:8]:8'd0, rslt[7:0] };
            CR_LD:  begin cra <= md[7:0]; crin <= rslt; cr_we <= 1; end
            default:;
        endcase
    end
end

endmodule