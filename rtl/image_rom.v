
`timescale 1ns / 1ps

module image_rom #(
    parameter DEPTH    = 512*512,
    parameter ADDR_W   = 19,
    parameter MEM_FILE = "image.mem"
)(
    input                     clk,
    input      [ADDR_W-1:0]   addr,
    output reg [7:0]          dout
);

    reg [7:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(MEM_FILE, mem);
    end

    always @(posedge clk) begin
        dout <= mem[addr];
    end

endmodule
