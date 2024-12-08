`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2024 01:56:22 PM
// Design Name: 
// Module Name: singlepulser
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
module singlepulser(
    input clk,
    input en,
    output reg enable
    );
    
    reg en_d;

    always @(posedge clk) begin
        en_d <= en;                   // Register the input `en`
        enable <= en & ~en_d;          // Generate pulse on rising edge of `en`
    end 
    
endmodule
