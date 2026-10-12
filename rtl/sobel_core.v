
`timescale 1ns / 1ps

module sobel_core #(
    parameter WIDTH = 512
)(
    input                  clk,
    input                  rst,
    input      [7:0]       pixel_in,
    input                  valid_in,
    output reg [7:0]       pixel_out,
    output reg             valid_out,
    output reg [31:0]      row_out,   
    output reg [31:0]      col_out   
);

    reg [7:0] r1 [0:WIDTH-1];
    reg [7:0] r2 [0:WIDTH-1];
    reg [7:0] r3 [0:WIDTH-1];

    reg [31:0] col;
    reg [31:0] row;

    wire [7:0] r1_now = r1[col];
    wire [7:0] r2_now = r2[col];
    wire [7:0] r3_now = r3[col];

    reg [7:0] r1_t1, r1_t2;
    reg [7:0] r2_t1, r2_t2;
    reg [7:0] r3_t1, r3_t2;

    integer Gx, Gy, G;

    always @(posedge clk) begin
        if (rst) begin
            col       <= 0;
            row       <= 0;
            pixel_out <= 8'd0;
            valid_out <= 1'b0;
            row_out   <= 0;
            col_out   <= 0;
            r1_t1 <= 0; r1_t2 <= 0;
            r2_t1 <= 0; r2_t2 <= 0;
            r3_t1 <= 0; r3_t2 <= 0;
        end
        else if (valid_in) begin
            r3[col] <= r2[col];
            r2[col] <= r1[col];
            r1[col] <= pixel_in;

            r1_t2 <= r1_t1; r1_t1 <= r1_now;
            r2_t2 <= r2_t1; r2_t1 <= r2_now;
            r3_t2 <= r3_t1; r3_t1 <= r3_now;

            row_out <= row;
            col_out <= col;

            if (row > 2 && col > 1) begin
                Gx = ($signed({1'b0, r3_now}) - $signed({1'b0, r3_t2}))
                   + (($signed({1'b0, r2_now}) - $signed({1'b0, r2_t2})) <<< 1)
                   + ($signed({1'b0, r1_now}) - $signed({1'b0, r1_t2}));

                Gy = ($signed({1'b0, r3_now}) + ($signed({1'b0, r3_t1}) <<< 1) + $signed({1'b0, r3_t2}))
                   - ($signed({1'b0, r1_now}) + ($signed({1'b0, r1_t1}) <<< 1) + $signed({1'b0, r1_t2}));

                if (Gx < 0) Gx = -Gx;
                if (Gy < 0) Gy = -Gy;
                G = Gx + Gy;

                pixel_out <= (G > 255) ? 8'd255 : G[7:0];
                valid_out <= 1'b1;
            end
            else begin
                pixel_out <= 8'd0;
                valid_out <= 1'b0;
            end

            if (col == WIDTH-1) begin
                col <= 0;
                row <= row + 1;
            end
            else begin
                col <= col + 1;
            end
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule
