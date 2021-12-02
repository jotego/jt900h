module jt900h_regs(
    input             rst,
    input             clk,
    input             cen,

    // input             src_mux,
    // input             aux_mux,
    input      [ 1:0] rfp,          // register file pointer
    // From indexed memory addresser
    input      [ 7:0] idx_rdreg_sel,
    input      [ 1:0] reg_step,
    input             reg_inc,
    input             reg_dec,
    // offset register
    input      [ 7:0] idx_rdreg_aux,
/*
    // from the memory
    input      [15:0] mem_dout,

    // read operands
    input       [1:0] zsel,   // length selection
    // source register
    input       [7:0] lsrc,   // long format
    input       [2:0] ssrc,   // short format
    input             sln,    // short format (high) - long (low)
    */
    output reg [31:0] src_out,

    // destination register
    //input       [2:0] dst,
    output reg [31:0] dst_out
/*
    // write result
    input       [2:0] wdst,
    input       [1:0] wz,
    input             we,
    input      [31:0] din*/
);

localparam [3:0] CURBANK  = 4'he,
                 PREVBANK = 4'hd;

// All registers
reg [7:0] accs[0:63];
reg [7:0] ptrs[0:15];
reg [7:0] r0sel, r1sel;

wire [31:0] full_step;

assign full_step = reg_step == 1 ? 2 : reg_step==2 ? 4 : 1;

// gigantic multiplexer:
always @* begin
    r0sel   = simplify(idx_rdreg_sel);
    src_out = r0sel[7:4]==4'hf ?
        {   ptrs[ {r0sel[3:2],2'b11} ], ptrs[ {r0sel[3:2],2'b10} ],
            ptrs[ {r0sel[3:1],1'b1}  ], ptrs[ r0sel[3:0] ] } :
        {   accs[ {r0sel[5:2],2'b11} ], accs[ {r0sel[5:2],2'b10} ],
            accs[ {r0sel[5:1],1'b1}  ], accs[ r0sel[5:0] ] };

    r1sel   = simplify(idx_rdreg_aux);
    dst_out = r1sel[7:4]==4'hf ?
        {   ptrs[ {r1sel[3:2],2'b11} ], ptrs[ {r1sel[3:2],2'b10} ],
            ptrs[ {r1sel[3:1],1'b1}  ], ptrs[ r1sel[3:0] ] } :
        {   accs[ {r1sel[5:2],2'b11} ], accs[ {r1sel[5:2],2'b10} ],
            accs[ {r1sel[5:1],1'b1}  ], accs[ r1sel[5:0] ] };

    if( reg_dec )
        dst_out = dst_out - full_step;
end

always @(posedge clk) begin
    if( reg_inc )
        { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
          ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= dst_out + full_step;
    if( reg_dec )
        { ptrs[ {r0sel[3:2],2'd3} ], ptrs[ {r0sel[3:2],2'd2} ],
          ptrs[ {r0sel[3:2],2'd1} ], ptrs[ {r0sel[3:2],2'd0} ] } <= dst_out;
end

function [7:0] simplify( input [7:0] rsel );
    simplify = {
               rsel[7:4]==CURBANK  ? { 2'd0, rfp } :
               rsel[7:4]==PREVBANK ? { 2'd0, rfp-2'd1 } : rsel[7:4],
               rsel[3:0] };
endfunction


endmodule