`timescale 1ns / 1ps

module M_64(
    input clk,
    input reset,
    input [63:0] X,
    input [63:0] Y,
    output [127:0] P
    );
    
    wire [63:0] PP64LL, PP64LH, PP64HL, PP64HH;
    wire [31:0] XL, XH, YL, YH;
    reg [63:0] PP64LL_reg, PP64LH_reg, PP64HL_reg, PP64HH_reg;
    
    assign XL = X[31:0];
    assign XH = X[63:32];
    assign YL = Y[31:0];
    assign YH = Y[63:32];
    
    multiplier_32 LL(XL, YL, PP64LL);
    multiplier_32 LH(XL, YH, PP64LH);
    multiplier_32 HL(XH, YL, PP64HL);
    multiplier_32 HH(XH, YH, PP64HH);      
    
    assign P = (PP64HH_reg << 64) + ((PP64LH_reg + PP64HL_reg) << 32) + PP64LL_reg;
    
    always @ (posedge clk)
    begin
        if (reset == 0) begin
            PP64LL_reg <= 64'd0;
            PP64LH_reg <= 64'd0;
            PP64HL_reg <= 64'd0;
            PP64HH_reg <= 64'd0;
        end
        else begin
            PP64LL_reg <= PP64LL;
            PP64LH_reg <= PP64LH;
            PP64HL_reg <= PP64HL;
            PP64HH_reg <= PP64HH;          
        end
    end
    
endmodule

module M_64_1(
    input [63:0] X_i,
    input [63:0] Y_i,
    output [255:0] PPs_o
    );
    
    wire [63:0] PP64LL, PP64LH, PP64HL, PP64HH;
    wire [31:0] XL, XH, YL, YH;
    
    assign XL = X_i[31:0];
    assign XH = X_i[63:32];
    assign YL = Y_i[31:0];
    assign YH = Y_i[63:32];
    
    multiplier_32 LL(XL, YL, PP64LL);
    multiplier_32 LH(XL, YH, PP64LH);
    multiplier_32 HL(XH, YL, PP64HL);
    multiplier_32 HH(XH, YH, PP64HH);  
    
    assign PPs_o = {PP64HH, PP64HL, PP64LH, PP64LL};
    
endmodule

module M_64_2(
    input [255:0] PPs_i,
    output [127:0] P_o
    );
    
    wire [63:0] PP64LL, PP64LH, PP64HL, PP64HH;
    
    assign PP64LL = PPs_i[63:0];
    assign PP64LH = PPs_i[127:64];
    assign PP64HL = PPs_i[195:128];
    assign PP64HH = PPs_i[255:196];
    
    assign P_o = (PP64HH << 64) + ((PP64LH + PP64HL) << 32) + PP64LL;
    
endmodule