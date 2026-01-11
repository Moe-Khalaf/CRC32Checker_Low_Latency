`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mohammedali Khalaf
// 
// Create Date: 01/07/2026 10:39:48 AM
// Design Name: Top_Level
// Module Name: Top_Level
// Project Name: CRC32Checker
// Target Devices: Basys3 Artix-7 Board
// Tool Versions: Vivado 2023.2
// Description: Top Level Module for Low-Latency CRC32 Checker Algorithm
// This design will be revision 0.01 where I will recieve 32 bits per clock cycle
// and gather the bits until I have a full 256 bit word. This will take 8 clock cycles.
// The next three clock cycles will be used to calculate the 32 bit CRC of the batch.

// In the next revision the CRC check will be complete in two clock cycles.

// The aim is to make a design that meets timing closure while running on the 200MHz Basys3 Clock
// 
// Dependencies: 
// 
// Revision: 0.01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top_Level(
    input wire clk_i,               // Input 200MHz Clock
    input wire rst_i,               // System Reset
    input wire [31:0] data_i,       // Input Data Bus
    input wire data_valid_i,        // Input Data Bus Valid Flag
    input wire data_last_i,         // Input Data Bus Last Word Flag
    input wire [31:0] polynomial_i, // Generator Polynomial Sequence
    output reg [31:0] crc_o,       // Output CRC Data
    output reg crc_valid_o         // Output CRC Valid Flag

    );
    
    reg [255:0] message_shift;       // Shift Reg to recieve full message
    reg [255:0] message_buffer;     // Buffer to store full message
    reg         compute_flag;
    reg [2:0]   word_count;         // Counter to track words recieved
    reg         crc_engine_en;      // CRC Engine Enable Flag
    reg [31:0]  state_reg = 32'hFFFFFFFF;
    wire [31:0]  crc_w;              // CRC Output Wire
    
    // Stage 1: Data Reception
    always @(posedge clk_i) begin
        if(rst_i) begin
            word_count <= 0;
            message_shift <= 0;
            crc_engine_en <= 0;
        end
        else if (data_valid_i) begin
            message_shift[word_count*32 +: 32] <= data_i;
            word_count <= word_count +1;
            if (data_last_i) begin
                crc_engine_en <= 1; // Trigger CRC Compute
            end else begin
                crc_engine_en <= 0;
            end
        end
    end
    
    always @(posedge clk_i) begin
        if(rst_i) begin
            message_buffer <= 0;
        end else begin
            if(crc_engine_en) begin
                message_buffer <= message_shift;
                compute_flag <= 1;
            end else begin
                compute_flag <= 0;
                message_buffer <= 0;
            end
        end
    end
    
    // Stage 2: CRC Compute
    lfsr #(
        .LFSR_WIDTH(32),
        .LFSR_POLY(32'h04c11db7),
        .LFSR_CONFIG("GALOIS"),
        .LFSR_FEED_FORWARD(0),
        .REVERSE(1),
        .DATA_WIDTH(256),
        .STYLE("AUTO")  
    ) crc32_engine(
        .data_in(message_buffer),
        .state_in(state_reg),
        .data_out(),
        .state_out(crc_w)
    );
    
    // Stage 3: Output Control
    always @(posedge clk_i) begin
        if(rst_i) begin
            crc_o <= 0;
            crc_valid_o <= 0;
        end else begin
            if(compute_flag) begin
                crc_o <= crc_w;
                crc_valid_o <= 1;
            end else begin
                crc_o <= 0;
                crc_valid_o <= 0;
            end
       end
    end
    
endmodule
