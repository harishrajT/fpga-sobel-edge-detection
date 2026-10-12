
`timescale 1ns / 1ps

module vga_timing (
    input             clk,       
    input             rst,
    input             pixel_en,  
    output reg [9:0]  hcount,    
    output reg [9:0]  vcount,    
    output            hsync,    
    output            vsync,    
    output            video_on 
);

    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; 

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;

    always @(posedge clk) begin
        if (rst) begin
            hcount <= 0;
            vcount <= 0;
        end
        else if (pixel_en) begin
            if (hcount == H_TOTAL-1) begin
                hcount <= 0;
                vcount <= (vcount == V_TOTAL-1) ? 0 : vcount + 1;
            end
            else begin
                hcount <= hcount + 1;
            end
        end
    end

    assign hsync    = ~(hcount >= H_DISPLAY + H_FRONT && hcount < H_DISPLAY + H_FRONT + H_SYNC);
    assign vsync    = ~(vcount >= V_DISPLAY + V_FRONT && vcount < V_DISPLAY + V_FRONT + V_SYNC);
    assign video_on = (hcount < H_DISPLAY) && (vcount < V_DISPLAY);

endmodule
