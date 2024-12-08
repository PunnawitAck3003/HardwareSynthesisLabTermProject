`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2024 03:34:23 PM
// Design Name: 
// Module Name: displayClock
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module displayClock(
        input clk,
        output targetClk
    );
    
    wire [18:0] tclk;
    assign tclk[0] = clk;
    
    genvar c;
    generate for(c=0;c<18;c=c+1)
    begin
        clockDiv div(tclk[c+1], tclk[c]);
    end
    endgenerate
    wire targetClk;
    clockDiv ffdiv(targetClk, tclk[18]);
    
endmodule
