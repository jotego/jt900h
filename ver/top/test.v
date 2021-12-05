`timescale 1ns/1ps

module test;

reg         rst, clk;
wire        cen;
wire [23:0] ram_addr;
wire [15:0] ram_dout;
wire        ram_rdy;
reg  [15:0] mem[0:1023];

initial begin
    $readmemh("test.hex",mem);
end

assign cen = 1;
assign ram_dout = mem[ram_addr[9:1]];

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
    #100 rst=0;
    #100_000 $finish;
end

jt900h uut(
    .rst            ( rst       ),
    .clk            ( clk       ),
    .cen            ( cen       ),

    .ram_addr       ( ram_addr  ),
    .ram_dout       ( ram_dout  )
);

endmodule