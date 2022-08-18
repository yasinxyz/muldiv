`timescale 1ns / 1ps

module MD_in(
    input [63:0] X_i,
    input [63:0] Y_i,
    input [3:0] md_op_i,
   
    output [63:0] X_o,
    output [63:0] Y_o,
    
    output reg [63:0] d_exception_result_o,
    output reg d_exception_o
	);

    
    wire [63:0] X_2C, Y_2C;           // 2's complemented operands
    wire [63:0] X_US, Y_US;           // unsigned version of the signed operands
    wire [31:0] X_32, Y_32;           // 32-bit operands for the *W instructions
    
    
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    
    // 2's Complemented operands assignemnt
    assign X_2C = ~X_i + 1;
    assign Y_2C = ~Y_i + 1;

    // unsigned Operands
    assign X_US = X_i[63] ? X_2C : X_i;
    assign Y_US = Y_i[63] ? X_2C : Y_i;

    // output assignment w.r.t. current instruction
    assign X_o = md_op_i[3] ?
    (md_op_i[2] ? (md_op_i[0] ? {32'd0, X_i[31:0]} : {32'd0, X_US[31:0]}) : {32'd0, X_US[31:0]}) :
    (md_op_i[2] ? (md_op_i[0] ? X_i : X_US) : 
    (md_op_i[1] ? (md_op_i[0] ? X_US : X_US) : (md_op_i[0] ? X_US: X_i)));
    
    assign Y_o = md_op_i[3] ?
    (md_op_i[2] ? (md_op_i[0] ? {32'd0, Y_i[31:0]} : {32'd0, Y_US[31:0]}) : {32'd0, Y_US[31:0]}) :
    (md_op_i[2] ? (md_op_i[0] ? Y_i : Y_US) : 
    (md_op_i[1] ? Y_US : Y_i));
	
	always @* begin	
        if(Y_i == 64'd0) begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 2'b1)
                d_exception_result_o = X_i;
            else if(md_op_i[1:0] == 2'b00)
                d_exception_result_o <= -64'd1;
            else if(md_op_i[1:0] == 2'b01) begin
                if(md_op_i[3] == 1'b1) begin
                    d_exception_result_o = 64'h00000000ffffffff;
                end else begin
                    d_exception_result_o = -64'd1;            
                end
            end
            else begin
                d_exception_result_o = 64'd0;
            end                                  
        end
        else if((md_op_i[3] == 1'b0) && (X_i == 64'h8000000000000000) && (Y_i == -64'd1)) begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 1'b0)
                d_exception_result_o = 64'h8000000000000000; 
            else begin
                d_exception_result_o = 64'd0;  
            end
        end
        else if((md_op_i[3] == 1'b1) && (X_i[31:0] == 32'h80000000) && (Y_i[31:0] == -32'd1)) begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 1'b0)
                d_exception_result_o = 64'hffffffff80000000; 
            else 
                d_exception_result_o = 64'd0; 
        end
        else begin
            d_exception_o = 1'b0;
            d_exception_result_o = 63'd0;    
        end
    end                                                 
endmodule