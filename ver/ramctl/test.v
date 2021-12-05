`timescale 1ns/1ps

module test;

reg         rst, clk;
wire        cen;
reg  [23:0] req_addr;
wire [23:0] ram_addr;
wire [15:0] ram_dout;
wire [31:0] dout, expected;
wire        ram_rdy;
reg  [ 7:0] buffer[0:1023];
wire        match, mismatch;

assign cen = 1;
assign ram_dout = { buffer[ {ram_addr[23:1],1'b1} ], buffer[ {ram_addr[23:1],1'b0} ] };
assign expected = {
        buffer[req_addr+3], buffer[req_addr+2],
        buffer[req_addr+1], buffer[req_addr]    };

assign match = ram_rdy && dout == expected;
assign mismatch = ram_rdy && dout != expected;

initial begin
    $readmemh("test.hex",buffer);
end

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    $dumpon;
end

initial begin
    clk=0;
    forever #5 clk=~clk;
end

initial begin
    rst=1;
    req_addr = 0;
    #100 rst=0;
    #100000 $display("PASS");
    $finish;
end

always @(posedge clk) begin
    if( ram_rdy ) begin
        if( dout != expected ) begin
            $display("FAIL");
            #50 $finish;
        end else begin
            //req_addr <= req_addr + $random %5;
            req_addr <= req_addr + 4;
        end
    end
    if( req_addr > 24'd1020 ) begin
        $display("PASS");
        $finish;
    end
end

jt900h_ramctl uut(
    .rst            ( rst       ),
    .clk            ( clk       ),
    .cen            ( cen       ),

    .ldram_en       ( 1'b0      ),
    .idx_addr       ( 24'd0     ),
    .pc             ( req_addr  ),
    .ram_addr       ( ram_addr  ),
    .ram_dout       ( ram_dout  ),
    .dout           ( dout      ),
    .ram_rdy        ( ram_rdy   )
);

endmodule