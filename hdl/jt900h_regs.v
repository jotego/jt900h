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

    output     [31:0] op0,
    output     [31:0] op1,
);

localparam [3:0] XSP=6;

reg  [31:0] accs[0:15];
reg  [31:0] ptrs[0: 3];
reg  [ 7:0] subsel, fsel;
reg         s, z, h, v, n, c,    // flags (main)
            s_,z_,h_,v_,n_,c_,   // flags (alt)
wire [15:0] sr;             // status register. lower byte contains the flags

assign flags   = {s, z, 1'b0,h, 1'b0,v, n, c };
assign flags_  = {s_,z_,1'b0,h_,1'b0,v_,n_,c_};
assign sr[7:0] = flags;

always @* begin
    subsel = bs ? {md[2:1],1'b0,~md[0]} :     // byte register
                  {{4{md[2]}},md[1:0],2'b0};  // word register
    casez( md[6:4] )
        3'b0??: fsel={2'd0,md[5:0]};
        3'b101: fsel={2'd0,rfp-2'd1,md[3:0]}; // previous bank
        3'b110: fsel={2'd0,rfp,     md[3:0]}; // current bank
        default:fsel=md;
    endcase
    // Register multiplexer
    sdsel = rmux_sel==DST_RMUX ? dst : src;
    sdmux = sdmux[7] ? ptrs[sdmux[5:2]] : accs[sdmux[3:2]]; // 32-bit registers
    sdsh  = bs ? {sdmux[1:0],3'd0} : ws ? {sdmux[1],4'd0} : 5'd0; // shift to select byte/word part as data
    case( rmux_sel )
        A_RMUX:   rmux = {16'd0, ws ? accs[{rfp,2'd1}]:8'd0, accs[{rfp,2'd0}][7:0]};
        SRC_RMUX, DST_RMUX: rmux = sdmux >> sdsh;
        RFP_RMUX: rmux[1:0] = rfp;
        N3_RMUX:  rmux = {29'd0,md[2:0]};
        N4_RMUX:  rmux = {28'd0,md[3:0]};
        CR_RMUX:  rmux = cr;
        F_RMUX:   rmux = alt ? flags_ : flags;
        XSP_RMUX: rmux = ptrs[XSP];
        ZERO_RMUX:rmux = 0;
        default:  rmux = md;
    endcase
    // extend the sign
    if( bs & sex ) rmux[31: 8] = {24{rmux[ 7]}};
    if( ws & sex ) rmux[31:16] = {16{rmux[15]}};
end

always @(posedge clk, posedge rst) begin
    if(rst) begin

    end else begin
        case( ral_sel ) // Register Address Latch
            SRC_RAL: src <= full ? fsel : subsel;
            DST_RAL: dst <= subsel;
            default:;
        endcase
        case( opnd_sel )
            LD0_OPND: op0 <= rmux;
            LD1_OPND: op1 <= rmux;
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
            PC_LD:  pc <= rslt[23:0];
            XSP_LD: ptrs[XSP] <= rslt;
            default:;
        endcase
    end
end

endmodule