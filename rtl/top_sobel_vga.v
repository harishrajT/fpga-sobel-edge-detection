// top_sobel_vga.v
// Milestone 2 top level.
//

`timescale 1ns / 1ps

module top_sobel_vga #(
    parameter IMG_WIDTH  = 200,
    parameter IMG_HEIGHT = 300,
    parameter MEM_FILE   = "image.mem"
)(
    input        clk100,     
    input        btnC,       
    output       vga_hsync,
    output       vga_vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b
);

    localparam DEPTH  = IMG_WIDTH * IMG_HEIGHT;
    localparam ADDR_W = $clog2(DEPTH);

    wire rst = btnC;

    wire pixel_en;
    pixel_clk_en u_pixel_en (
        .clk      (clk100),
        .rst      (rst),
        .pixel_en (pixel_en)
    );


    reg [ADDR_W-1:0] addr_cnt;
    reg              feeding;
    reg              valid_in_d;
    reg              compute_done;

    wire [7:0] rom_dout;

    image_rom #(
        .DEPTH    (DEPTH),
        .ADDR_W   (ADDR_W),
        .MEM_FILE (MEM_FILE)
    ) u_image_rom (
        .clk  (clk100),
        .addr (addr_cnt),
        .dout (rom_dout)
    );

    always @(posedge clk100) begin
        if (rst) begin
            addr_cnt     <= 0;
            feeding      <= 1'b1;
            valid_in_d   <= 1'b0;
            compute_done <= 1'b0;
        end
        else begin
            valid_in_d <= feeding;

            if (feeding) begin
                if (addr_cnt == DEPTH-1) begin
                    feeding <= 1'b0;
       
                end
                else begin
                    addr_cnt <= addr_cnt + 1'b1;
                end
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
        .clk       (clk100),
        .rst       (rst),
        .pixel_in  (rom_dout),
        .valid_in  (valid_in_d),
        .pixel_out (sobel_pixel_out),
        .valid_out (sobel_valid_out),
        .row_out   (sobel_row_out),
        .col_out   (sobel_col_out)
    );


    wire [ADDR_W-1:0] waddr = sobel_row_out * IMG_WIDTH + sobel_col_out;
    wire [ADDR_W-1:0] raddr;
    wire [7:0]        rdata;

    output_bram #(
        .DEPTH  (DEPTH),
        .ADDR_W (ADDR_W)
    ) u_output_bram (
        .clk    (clk100),
        .we     (sobel_valid_out),
        .waddr  (waddr),
        .din    (sobel_pixel_out),
        .raddr  (raddr),
        .dout   (rdata)
    );

 
    wire [9:0] hcount, vcount;
    wire       video_on;

    vga_timing u_vga_timing (
        .clk      (clk100),
        .rst      (rst),
        .pixel_en (pixel_en),
        .hcount   (hcount),
        .vcount   (vcount),
        .hsync    (vga_hsync),
        .vsync    (vga_vsync),
        .video_on (video_on)
    );

  
    localparam [9:0] OFFSET_X = (640 - IMG_WIDTH)  / 2;
    localparam [9:0] OFFSET_Y = (480 - IMG_HEIGHT) / 2;

    wire in_image_x = (hcount >= OFFSET_X) && (hcount < OFFSET_X + IMG_WIDTH);
    wire in_image_y = (vcount >= OFFSET_Y) && (vcount < OFFSET_Y + IMG_HEIGHT);
    wire image_active = video_on && compute_done && in_image_x && in_image_y;

    assign raddr = image_active
                   ? ((vcount - OFFSET_Y) * IMG_WIDTH + (hcount - OFFSET_X))
                   : {ADDR_W{1'b0}};

    

    reg [3:0] r_reg, g_reg, b_reg;

    always @(posedge clk100) begin
        if (pixel_en) begin
            if (image_active) begin
                r_reg <= rdata[7:4];
                g_reg <= rdata[7:4];
                b_reg <= rdata[7:4];
            end
            else begin
                r_reg <= 4'd0;
                g_reg <= 4'd0;
                b_reg <= 4'd0;
            end
        end
    end

    assign vga_r = video_on ? r_reg : 4'd0;
    assign vga_g = video_on ? g_reg : 4'd0;
    assign vga_b = video_on ? b_reg : 4'd0;

endmodule
