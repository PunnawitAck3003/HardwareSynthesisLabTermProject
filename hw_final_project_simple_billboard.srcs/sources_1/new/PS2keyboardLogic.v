`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2024 12:23:19 PM
// Design Name: 
// Module Name: PS2keyboardLogic
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


module PS2keyboardLogic(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    output [7:0] dataPS2,
    output        PS2en,
    input tsent
);
    wire        tready;
    wire        ready;
    wire        tstart;
    reg         start=0;
    reg         CLK50MHZ=0;
    wire [31:0] tbuf;
    reg  [15:0] keycodev=0;
    wire [15:0] keycode;
    wire [ 7:0] tbus;
    reg  [ 2:0] bcount=0;
    wire        flag;
    reg         cn=0;
    
    always @(posedge(clk))begin
        CLK50MHZ<=~CLK50MHZ;
    end
    
    PS2Receiver uut (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );
    
    always@(keycode)
        if (keycode[7:0] == 8'hf0) begin
            cn <= 1'b0;
            bcount <= 3'd0;
        end else if (keycode[15:8] == 8'hf0) begin
            cn <= keycode != keycodev;
            bcount <= 3'd5;
        end else begin
            cn <= keycode[7:0] != keycodev[7:0] || keycodev[15:8] == 8'hf0;
            bcount <= 3'd2;
        end
    
    always@(posedge clk)
        if (flag == 1'b1 && cn == 1'b1) begin
            start <= 1'b1;
            keycodev <= keycode;
        end else
            start <= 1'b0;
            
    bin2ascii #(
        .NBYTES(2)
    ) conv (
        .I(keycodev),
        .O(tbuf)
    );
    
    uart_buf_con tx_con (
        .clk    (clk   ), // input ok
        .bcount (bcount), // input ok
        .tbuf   (tbuf  ),  // input ok
        .start  (start ), // input ok
        .ready  (ready ), // output
        .tstart (tstart), // output
        .tready (tsent), // input 
        .tbus   (tbus  ) // output
    );
    assign PS2en = tstart;
    assign dataPS2 = tbus;
    
//    uart_tx_PS2 get_tx (
//        .clk    (clk),
//        .start  (tstart),
//        .tbus   (tbus),
//        .tx     (tx),
//        .ready  (tready)
//    );
    
endmodule
