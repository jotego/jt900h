module jt900h_regs(
    input             rst,
    input             clk,
    input             cen,

    // read operands
    input       [1:0] zsel,   // length selection
    // source register
    input       [7:0] lsrc,   // long format
    input       [2:0] ssrc,   // short format
    input             sln,    // short format (high) - long (low)
    output reg [31:0] src_out,

    // destination register
    input       [2:0] dst,
    output reg [31:0] dst_out,

    // write result
    input       [2:0] wdst,
    input       [1:0] wz,
    input             we,
    input      [31:0] din
);

localparam [7:0] CURBANK = 8'he0,
                 PREVBANK = 8'hd0;

// All registers
reg [7:0] regs0[0:19];
reg [7:0] regs1[0:19];
reg [7:0] regs2[0:19];
reg [7:0] regs3[0:19];

reg [1:0] cur_bank, prev_bank;
reg [5:0] gr_sel;   // general register
reg [7:0] src_sel, dst_sel, wr_sel;

reg [4:0] src_idx, dst_idx, wr_idx;

// register reads
always @(*) begin
    src_sel = lsrc;
    if( sln )
        src_sel = short2long(ssrc,zsel) + CURBANK;
    src_idx = long2bank(src_sel);
    dst_sel = short2long(dst,zsel) + CURBANK;
    dst_idx = long2bank(dst_sel);
end

always @(posedge clk) if(cen) begin
    src_out <= read_reg(src_idx, src_sel[1:0]);
    dst_out <= read_reg(dst_idx, dst_sel[1:0]);
end

// register writes
always @(*) begin
    wr_sel = short2long(wdst,wz) + CURBANK;
    wr_idx = long2bank(wr_sel);
end

always @(posedge clk) if(cen && we) begin
    case(wz)
        0: case(wr_sel[0]) // byte
            0: regs0[wr_idx] <= din[7:0];
            1: regs1[wr_idx] <= din[7:0];
        endcase
        1: { regs1[wr_idx], regs0[wr_idx] } <= din[15:0];
        2: { regs3[wr_idx], regs2[wr_idx],
             regs1[wr_idx], regs0[wr_idx] } <= din;
    endcase
end

reg [31:0] qmux;
reg [15:0] wmux;
reg [ 7:0] bmux;

function [31:0] read_reg( input [4:0] idx, input [1:0] subsel );
    qmux = {regs3[idx], regs2[idx], regs1[idx], regs0[idx]};
    wmux = subsel[1] ? qmux[31:16] : qmux[15:0];
    case(subsel)
        0: bmux=regs0[idx];
        1: bmux=regs1[idx];
        2: bmux=regs2[idx];
        3: bmux=regs3[idx];
    endcase
    case( zsel )
        0: read_reg = { 24'd0, bmux };
        1: read_reg = { 16'd0, wmux };
        default: read_reg = qmux;
    endcase
endfunction

function [4:0] long2bank( input[7:0] long );
    if( long[7:4] < 4 )
        long2bank = {1'b0, long[5:2]};
    if( long[7:4] == 'hd )
        long2bank = { 1'b0, prev_bank, long[3:2] };
    if( long[7:4] == 'he )
        long2bank = { 1'b0, cur_bank, long[3:2] };
    if( long[7:4] == 'hf )
        long2bank = { 3'b111, long[3:2] };
endfunction

function [7:0] short2long( input [2:0] short, input [1:0] zsel );
    case(zsel)
        0: // byte
            case(short)
                0: short2long =  1;
                1: short2long =  0;
                2: short2long =  5;
                3: short2long =  4;
                4: short2long =  9;
                5: short2long =  8;
                6: short2long = 13;
                7: short2long = 12;
            endcase
        1,2: // word or quad
            case(short)
                0: short2long =  0; // WA
                1: short2long =  4; // BC
                2: short2long =  8; // DE
                3: short2long = 12; // HL
                4: short2long = 16+ 0; // IX
                5: short2long = 16+ 4; // IY
                6: short2long = 16+ 8; // IZ
                7: short2long = 16+12; // SP
            endcase
    endcase
endfunction // short2long

endmodule