`timescale 1ns/1ps

module test;

reg         rst, clk;
wire        cen;
reg  [23:0] req_addr;
wire [23:0] ram_addr;
wire [15:0] ram_dout;
wire [31:0] dout;
wire        ram_rdy;

assign cen = 1;
assign ram_dout = { ram_addr[7:1],1'b1, ram_addr[7:1],1'b0 };

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
    req_addr = 24'hcafe;
    #100 rst=0;
    #100000 $finish;
end

always @(posedge clk) begin
    if( ram_rdy ) begin
        req_addr <= { ~req_addr[0]^req_addr[23]^req_addr[15],req_addr[23:1] };
    end
end

jt900h_ramctl uut(
    .rst            ( rst       ),
    .clk            ( clk       ),
    .cen            ( cen       ),

    .req_addr       ( req_addr  ),
    .ram_addr       ( ram_addr  ),
    .ram_dout       ( ram_dout  ),
    .dout           ( dout      ),
    .ram_rdy        ( ram_rdy   )
);

endmodule