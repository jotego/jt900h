`timescale 1ns/1ps

module test;

localparam AW=12;

reg         rst, clk;
reg         cen;
wire [23:0] ram_addr;
wire [11:0] ram_a;
wire [15:0] ram_dout, ram_din, ram_win;
wire [ 1:0] ram_we;
wire        ram_rdy;
reg  [15:0] mem[0:2**AW-1];

reg  [ 8:0] intcnt=9'h1ff; // count-down for an interrupt
reg  [ 2:0] int_lvl=0;
reg         irq=0;
wire        irq_ack;

reg  [7:0] dmp_addr;
wire [7:0] dmp_dout;
reg  [7:0] dmp_buf[0:255];
reg        dump_rdout, dump_2file;

reg        simctrl_cs, intctrl_cs;
// CPU registers
// wire [31:0] sim_xix = uut.u_regs.xix;
// wire [31:0] sim_xiy = uut.u_regs.xiy;
// wire [31:0] sim_xiz = uut.u_regs.xiz;
// wire [15:0] mem_xix;
// wire [15:0] mem_xiy;
// wire [15:0] mem_xiz;

integer    cnt,file;

initial begin
    // Initialize the memory with random values to prevent fluke results
    for( cnt=0; cnt<2**AW-1; cnt=cnt+1 ) mem[cnt] = $random;
    $readmemh( {`FNAME,".hex"},mem,0,`HEXLEN-1); // pass the length to avoid a warning msg
    // memory data region at 800h~9ffh with 16-bit values
    // upper byte = address, lower byte = ~address
    for( cnt=0; cnt<256; cnt=cnt+1 ) mem[ 12'h400+cnt[7:0] ] = { cnt[7:0],~cnt[7:0]};
end

assign ram_a    = ram_addr[AW-1:0]; // short version for plotting
assign ram_dout = ram_addr[23:2]==22'h3fffc0 ? 8'd0 : mem[ram_addr[AW-1:1]]; // reset vector in FFFF00
assign ram_win  = { ram_we[1] ? ram_din[15:8] : ram_dout[15:8],
                    ram_we[0] ? ram_din[ 7:0] : ram_dout[ 7:0] };
// assign mem_xix  = mem[sim_xix];
// assign mem_xiy  = mem[sim_xiy];
// assign mem_xiz  = mem[sim_xiz];

`ifndef NODUMP
initial begin
    $dumpfile( {`FNAME,".lxt"} );
    $dumpvars;
    $dumpon;
end
`endif

function [31:0] xreg( input [7:0] a );
    xreg = { dmp_buf[a+3], dmp_buf[a+2], dmp_buf[a+1], dmp_buf[a] };
endfunction

always @(posedge dump_2file) begin
    file=$fopen( {`FNAME,".out"},"w");
    for( cnt=0; cnt<16; cnt=cnt+4 ) begin
        $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(cnt), xreg(cnt+16),
                                              xreg(cnt+32), xreg(cnt+48) );
    end
    $fdisplay(file,"-- index registers --");
    $fdisplay(file,"%08X - %08X - %08X - %08X", xreg(64), xreg(68),
                                          xreg(72), xreg(76) );
    $fdisplay(file,"SR = %02X",{ dmp_buf[80], dmp_buf[81]} );
    $fclose(file);
`ifndef NODUMP
    // Dump the memory too
    file=$fopen("mem.bin","wb");
    for( cnt=0; cnt<2**AW; cnt=cnt+2) begin
        $fwrite(file,"%u",{mem[cnt+1],mem[cnt]});
    end
    $fclose(file);
`endif
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

always @* begin
    simctrl_cs = &ram_addr[15:1];
    intctrl_cs = ram_addr[15:1]=='h7ff8;
end

always @(posedge uut.u_ctrl.dec_err ) begin
    $display("Decode error detected. Simulation will be interrupted.");
    #100 $finish;
end

// always @(posedge uut.u_ctrl.halted ) begin
//     $display("CPU Halted");
// end

// always @(negedge uut.u_ctrl.halted ) begin
//     if( !rst ) $display("Halt released");
// end

always @(posedge clk) begin
    // `ifdef USECEN
    cen<=~cen;
    // `endif
    // update the interrupt register after a certain count
    if( !intcnt[8] ) begin
        intcnt <= intcnt - 1'd1;
        if( intcnt==0 ) begin
            irq <= 1;
        end
    end
    if( irq_ack ) begin
        irq <= 0;
    end
    if( ram_we !=0 ) begin
        mem[ ram_a>>1 ] <= ram_win;
        case( ram_we )
            2'b01: $display("RAM: %02X written to %X low  (%X)",ram_win[7:0],  ram_addr&24'hffffe, ram_a>>1 );
            2'b10: $display("RAM: %02X written to %X high (%X)",ram_win[15:8], ram_addr&24'hffffe, ram_a>>1 );
            2'b11: $display("RAM: %04X written to %X word (%X)",ram_win, ram_addr&24'hffffe, ram_a>>1 );
        endcase
        // trigger interrupts in the test bench
        if( intctrl_cs && ram_we[0] ) begin
            // write 0 to $fff0 to clear the interrupt
            // write $aa0n to cause interrupt level n after aa cycles
            intcnt  <= {1'd0, ram_din[15:8]};
            int_lvl <= ram_din[2:0];
            irq     <= 0;
        end

        if( simctrl_cs && ram_we[0] ) begin
            if( ram_din[0] )
                $display("Test self-evaluation: PASS");
            else
                $display("Test self-evaluation: FAIL");
        end
        if( simctrl_cs && ram_we[1] ) begin
            $display("The CPU sent the stop signal");
            dump_rdout <= 1;
        end
    end

    if (/*ram_addr>=`END_RAM ||*/ dump_rdout ) begin
        dmp_addr <= dmp_addr+1'd1;
        dmp_buf[ dmp_addr ] <= dmp_dout;
        cen <= 0;
        if( dmp_addr==84 ) begin
            dump_2file<=1;
        end
    end
end

assign ram_addr[0]=0;

jt900h uut(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cen       ),

    .addr       ( ram_addr[23:1]  ),
    .din        ( ram_dout  ),
    .dout       ( ram_din   ),
    .we         ( ram_we    ),
    .rd         (           ),
    .busy       ( 1'b0      ),

    .irq        ( irq       ),
    .irq_ack    ( irq_ack   ),
    .int_lvl    ( int_lvl   ),
    .int_addr   ({ 3'd1, int_lvl, 2'd0 }), // interrupt vectors at 0xffff20 upwards

    .dec_err    (           ),
    .dmp_addr   ( dmp_addr  ),
    .dmp_dout   ( dmp_dout  )
);

endmodule