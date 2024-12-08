`timescale 1ns / 1ps

module ps2_keyboard (
    input wire clk,                // System clock
    input wire PS2Clk,            // PS/2 Clock line
    input wire PS2Data,           // PS/2 Data line
    output reg [15:0] keycode      // Last received keycode
);
    
    reg CLK50MHZ = 0, unpress = 0;
    always @(posedge(clk))begin
        CLK50MHZ<=~CLK50MHZ;
    end
    
    wire [15:0] keycode;
    wire flag;
    PS2Receiver uut (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );
    
endmodule


