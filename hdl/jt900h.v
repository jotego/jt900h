module jt900h(
    input           rst,
    input           clk,
    input           cen,
    output          cpu_cen,

    input    [15:0] din,
    output   [15:0] dout,
    output   [23:0] addr,
    output          rd,
    output          wr,
    output   [ 1:0] dsn,    // active low
);



endmodule