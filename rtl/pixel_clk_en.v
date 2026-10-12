`timescale 1ns / 1ps

module pixel_clk_en (
    input        clk,
    input        rst,
    output       pixel_en
);

    reg [1:0] div;

    always @(posedge clk) begin
        if (rst)
            div <= 2'd0;
        else
            div <= div + 2'd1;
    end

    assign pixel_en = (div == 2'd0);

endmodule
