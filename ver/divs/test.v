module test;

wire        cen = 1;
reg         clk, rst;
reg  signed [31:0] op0;
reg  signed [15:0] op1;
wire signed [15:0] quot, rem;
reg         len, start;
wire        busy, v;

wire signed [31:0] vq = op0/op1;
wire signed [31:0] vr = op0 - op1*vq;

integer k;

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    $dumpon;
end

initial begin
    rst = 1;
    op0 = 125;
    op1 = 7;
    len = 0;
    start = 0;
    #30 rst=0;
    $display("                                                     uut <> ref");
    for( k=0; k<1024*8; k=k+1) begin
        #50 start = 1;
        #60 start = 0;
        wait( !busy );
        $display("#%4d (len=%d, v=%d) %d/%d  | %d <> %3d ; %d <> %3d",
                     k, len,      v, op0, op1, quot,vq, rem, vr);
        if( !v && (quot!= vq || rem != vr) ) begin // asserted v not tested (!)
            $display("Error: results diverged");
            #40 $finish;
        end
        op0 = $random;
        op1 = $random;
        len = $random;
        if( !len ) begin
            op0[31:16] = {16{op0[15]}};
            op1[ 15:8] = { 8{op1[ 7]}};
        end
    end
    $display("PASS");
    #20 $finish;
end

jt900h_div uut (
    .rst  (rst  ),
    .clk  (clk  ),
    .cen  (cen  ),
    .op0  (op0  ),
    .op1  (op1  ),
    .len  (len  ),
    .start(start),
    .quot (quot ),
    .rem  (rem  ),
    .busy (busy ),
    .sign (1'b1 ),
    .v    (v    )
);


endmodule