`timescale 1ns/1ps

module test;

reg         rst, clk;
reg         cen;
wire [23:0] ram_addr;
wire [11:0] ram_a;
wire [15:0] ram_dout, ram_din, ram_win;
wire [ 1:0] ram_we;
wire        ram_rdy;
reg  [15:0] mem[0:1023];

reg  [7:0] dmp_addr;
wire [7:0] dmp_din;
reg  [7:0] dmp_buf[0:255];
reg        dump_rdout, dump_2file;


initial begin
    $readmemh("test.hex",mem,0,`HEXLEN-1); // pass the length to avoid a warning msg
end

assign ram_a    = ram_addr[11:0]; // short version for plotting
assign ram_dout = mem[ram_addr[9:1]];
assign ram_win  = { ram_we[1] ? ram_din[15:8] : ram_dout[15:8],
                    ram_we[0] ? ram_din[ 7:0] : ram_dout[ 7:0] };

`ifndef NODUMP
initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    $dumpon;
end
`endif

integer cnt,file;
function [31:0] xreg( input [7:0] a );
    xreg = { dmp_buf[a+3], dmp_buf[a+2], dmp_buf[a+1], dmp_buf[a] };
endfunction

always @(posedge dump_2file) begin
    file=$fopen("test.out","w");
    for( cnt=0; cnt<16; cnt=cnt+4 ) begin
        $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(cnt), xreg(cnt+16),
                                              xreg(cnt+32), xreg(cnt+48) );
    end
    $fdisplay(file,"-- index registers --");
    $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(64), xreg(68),
                                          xreg(72), xreg(76) );
    $fdisplay(file,"SR = %02X",{ dmp_buf[81], dmp_buf[80]} );
    $fclose(file);
    // Dump the memory too
    file=$fopen("mem.bin","wb");
    for( cnt=0; cnt<1024; cnt=cnt+2) begin
        $fwrite(file,"%u",{mem[cnt+1],mem[cnt]});
    end
    $fclose(file);
    $finish;
end

initial begin
    clk=0;
    forever #5 clk=~clk;
end

initial begin
    rst=1;
    cen=1;
    dmp_addr = 0;
    dump_rdout=0;
    $display("Simulating up to RAM address %X",`END_RAM);
    #100 rst=0;
    #1000_000
    $display("Time over");
    dump_rdout=1;
end

always @(posedge clk) begin
    `ifdef USECEN
    cen<=~cen;
    `endif
    if( ram_we !=0 ) begin
        mem[ ram_addr>>1 ] <= ram_win;
        $display("RAM: %X written to %X",ram_win, ram_addr&24'hffffe);
    end
end

always @(posedge clk) begin
    if (ram_addr>=`END_RAM || dump_rdout ) begin
        dmp_addr <= dmp_addr+1'd1;
        dmp_buf[ dmp_addr-1 ] <= dmp_din;
        cen <= 0;
        if( dmp_addr==84 ) begin
            dump_2file=1;
        end
    end
end

jt900h uut(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),

    .ram_addr   ( ram_addr  ),
    .ram_dout   ( ram_dout  ),
    .ram_din    ( ram_din   ),
    .ram_we     ( ram_we    ),

    .dmp_addr   ( dmp_addr  ),
    .dmp_din    ( dmp_din   )
);

endmodule