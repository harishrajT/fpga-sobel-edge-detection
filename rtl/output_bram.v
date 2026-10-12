
`timescale 1ns / 1ps

module output_bram #(
    parameter DEPTH  = 512*512,
    parameter ADDR_W = 19
)(
    input                    clk,

    input                    we,
    input      [ADDR_W-1:0]  waddr,
    input      [7:0]         din,

    input      [ADDR_W-1:0]  raddr,
    output reg [7:0]         dout
);

    reg [7:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 8'd0;
    end

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= din;
        dout <= mem[raddr];
    end

endmodule
