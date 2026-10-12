// tb_top_sim.v
// Simulation-only harness: instantiates just the compute path
// (image_rom -> sobel_core -> output_bram), runs it to completion,
// and dumps output_bram's contents to a .mem file with $writememh.
// Convert that file to a viewable PNG with scripts/mem_to_image.py.
//
// This does NOT exercise vga_timing / top_sobel_vga's I/O pins --
// it's here purely to let you verify the Sobel + frame-buffer logic
// behaviorally before synthesizing for the Basys3.
`timescale 1ns / 1ps

module tb_top_sim;

    localparam IMG_WIDTH  = 200;
    localparam IMG_HEIGHT = 300;
    localparam DEPTH      = IMG_WIDTH * IMG_HEIGHT;
    localparam ADDR_W     = $clog2(DEPTH);
    localparam MEM_FILE   = "image.mem";
    localparam OUT_FILE   = "output_full.mem";

    reg clk = 0;
    reg rst;

    always #5 clk = ~clk; // 100 MHz

    // ---- compute path, mirrors top_sobel_vga.v minus the VGA side ----
    reg  [ADDR_W-1:0] addr_cnt;
    reg               feeding;
    reg               valid_in_d;
    reg               compute_done;

    wire [7:0] rom_dout;

    image_rom #(
        .DEPTH    (DEPTH),
        .ADDR_W   (ADDR_W),
        .MEM_FILE (MEM_FILE)
    ) u_image_rom (
        .clk  (clk),
        .addr (addr_cnt),
        .dout (rom_dout)
    );

    always @(posedge clk) begin
        if (rst) begin
            addr_cnt     <= 0;
            feeding      <= 1'b1;
            valid_in_d   <= 1'b0;
            compute_done <= 1'b0;
        end
        else begin
            valid_in_d <= feeding;
            if (feeding) begin
                if (addr_cnt == DEPTH-1)
                    feeding <= 1'b0;
                else
                    addr_cnt <= addr_cnt + 1'b1;
            end
            if (!feeding && !valid_in_d)
                compute_done <= 1'b1;
        end
    end

    wire [7:0]  sobel_pixel_out;
    wire        sobel_valid_out;
    wire [31:0] sobel_row_out;
    wire [31:0] sobel_col_out;

    sobel_core #(
        .WIDTH (IMG_WIDTH)
    ) u_sobel_core (
        .clk       (clk),
        .rst       (rst),
        .pixel_in  (rom_dout),
        .valid_in  (valid_in_d),
        .pixel_out (sobel_pixel_out),
        .valid_out (sobel_valid_out),
        .row_out   (sobel_row_out),
        .col_out   (sobel_col_out)
    );

    wire [ADDR_W-1:0] waddr = sobel_row_out * IMG_WIDTH + sobel_col_out;

    output_bram #(
        .DEPTH  (DEPTH),
        .ADDR_W (ADDR_W)
    ) u_output_bram (
        .clk    (clk),
        .we     (sobel_valid_out),
        .waddr  (waddr),
        .din    (sobel_pixel_out),
        .raddr  ({ADDR_W{1'b0}}),
        .dout   ()
    );

    initial begin
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;

        wait (compute_done == 1'b1);
        repeat (5) @(posedge clk);

        $writememh(OUT_FILE, u_output_bram.mem);
        $display("Wrote frame buffer contents to %s (%0dx%0d)", OUT_FILE, IMG_WIDTH, IMG_HEIGHT);
        $finish;
    end

endmodule
