module test;

wire        cen = 1;
reg         clk, rst;
reg  [31:0] op0;
reg  [15:0] op1;
wire [15:0] quot, rem;
reg         len, start;
wire        busy, v;

wire [31:0] vq = op0/op1;
wire [31:0] vr = op0 - op1*vq;

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
    for( k=0; k<1024; k=k+1) begin
        #50 start = 1;
        #60 start = 0;
        wait( !busy );
        $display("#%4d (len=%d, v=%d) %d/%d  | %d <> %3d ; %d <> %3d",
            k, len, v, op0, op1, quot,vq, rem, vr);
        if( !v && (quot!= vq || rem != vr) ||
             v && (vq<(len ? 32'h10000 : 32'h100)) ) begin
            $display("Error: results diverged");
            #10 $finish;
        end
        op0 = $random;
        op1 = $random;
        len = $random;
        if( !len ) begin
            op0[31:16] = 0;
            op1[ 15:8] = 0;
        end
    end
    $display("PASS");
    #20 $finish;
end

jt900h_div i_jt900h_div (
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
    .sign (1'b0 ),
    .v    (v    )
);


endmodule