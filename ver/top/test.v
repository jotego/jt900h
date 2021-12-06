`timescale 1ns/1ps

module test;

reg         rst, clk;
reg         cen;
wire [23:0] ram_addr;
wire [15:0] ram_dout;
wire        ram_rdy;
reg  [15:0] mem[0:1023];

reg  [7:0] dmp_addr;
wire [7:0] dmp_din;
reg  [7:0] dmp_buf[0:79];


initial begin
    $readmemh("test.hex",mem);
end

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
    cen=1;
    dmp_addr = 0;
    #100 rst=0;
    #1000_000
    $display("Time over");
    $finish;
end

integer cnt,file;
function [31:0] xreg( input [7:0] a );
    xreg = { dmp_buf[a+3], dmp_buf[a+2], dmp_buf[a+1], dmp_buf[a] };
endfunction

always @(posedge clk) begin
    if (ram_addr>=`END_RAM) begin
        dmp_addr <= dmp_addr+1'd1;
        dmp_buf[ dmp_addr-1 ] <= dmp_din;
        cen <= 0;
        if( dmp_addr==81 ) begin
            file=$fopen("test.out","w");
            for( cnt=0; cnt<16; cnt=cnt+4 ) begin
                $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(cnt), xreg(cnt+16),
                                                      xreg(cnt+32), xreg(cnt+48) );
            end
            $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(64), xreg(68),
                                                  xreg(72), xreg(76) );
            $fclose(file);
            $finish;
        end
    end
end

jt900h uut(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),

    .ram_addr   ( ram_addr  ),
    .ram_dout   ( ram_dout  ),
    .dmp_addr   ( dmp_addr  ),
    .dmp_din    ( dmp_din   )
);

endmodule