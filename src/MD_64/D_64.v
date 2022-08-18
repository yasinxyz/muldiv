module D_64(
	input clk_i,	
	input reset_i,
	input start_i,
	input [63:0] X_i,
	input [63:0] Y_i,
	output rdy_o,
	output [127:0] QR_o);

	wire [63:0] Q64;
	wire rdy;

	//DividerBlock Signals
	wire X_1;
	wire [63:0] Rin, Rout, R;
	wire Q;

	//Control Signals
	wire [4:0] mux_A_sel;
	wire mux_Rin_sel;
	wire reg_Rin_en;
	wire reg_Q_en;
	wire mux_smaller_X;


	//Registers
	reg [63:0] reg_R, reg_Q;
	
	// first_one signals
    wire [6:0] first_one_X, first_one_Y;
    wire [6:0] div_count;
    
    // first one
    first_one inst_first_one_X(X_i, first_one_X);
    first_one inst_first_one_Y(Y_i, first_one_Y);
    
    assign div_count = first_one_X - first_one_Y;


	div_control div_control(start_i, clk_i, reset_i, div_count, mux_A_sel, mux_Rin_sel, mux_smaller_X, reg_Rin_en, reg_Q_en, rdy);

	divider_block_64 divider_block(X_1, Y_i, Rin, Rout, Q);

	assign X_1 = X_i[mux_A_sel];
	
	assign Rin = mux_Rin_sel ? reg_R : (X_i >> (div_count + 1));

	assign Q64 = reg_Q;

	assign R = reg_R;

	assign QR_o = mux_smaller_X ? {64'd0, Y_i} : {Q64, R};
	
	assign rdy_o = mux_smaller_X ? 1'b1 : rdy;

	always @ (posedge clk_i) begin

	   if(!reset_i) begin
	       reg_R <= 64'd0;
           reg_Q <= 64'd0;
	   end

	   else begin
            if (start_i == 0) begin
                reg_R <= 64'd0;
                reg_Q <= 64'd0;
            end

            else begin
                if (reg_Rin_en == 1)
                    reg_R <= Rout;
                else
                	reg_R <= reg_R;

                if (reg_Q_en == 1) begin
                    reg_Q[63:1] <= reg_Q[62:0];
                    reg_Q[0] <= Q;
                end else
                    reg_Q <= reg_Q;
            end
        end
	end

endmodule


module divider_array(
	input [63:0] x,
	input [63:0] y,
	output [63:0] r,
	output q);

	wire [64:0] r_temp;
	wire q_temp;

	assign r_temp = x - y;

	assign q_temp = ~r_temp[64];

	assign r = q_temp ? r_temp[63:0] : x;

	assign q = q_temp;

endmodule

module divider_block_64(
	input X,
	input [63:0] Y,
	input [63:0] Rin,
	output [63:0] Rout,
	output Q);

    divider_array row_0({Rin[62:0], X}, Y, Rout, Q);

endmodule


module div_control(
	input start,
	input clk,
	input reset,
	input [6:0] div_count,
	output reg [4:0] mux_A_sel,
	output reg mux_Rin_sel,
	output reg mux_smaller_X,
	output reg reg_Rin_en,
	output reg reg_Q_en,
	output reg rdy);

	parameter R1 = 1'b0, Rounds = 1'b1;

	reg state_reg, state_next;
	reg [6:0] counter_reg, counter_next;
	reg rdy_next;
	
       
	always @ (posedge clk) begin
		if(!reset) begin
			state_reg <= 1'b0;
			rdy <= 1'b0;
			counter_reg <= 7'd0;
		end
		else begin
			state_reg <= state_next;
			rdy <= rdy_next;
			counter_reg <= counter_next;			
		end
	end


	always @* begin
    	case(state_reg)
	    	R1: begin
	       		mux_A_sel = div_count;
	           	mux_Rin_sel = 1'b0;	           	
	    		if(start == 1'b1) begin
                    if(div_count[6] == 1'b1) begin
                        counter_next = 7'd0;
                        rdy_next = 1'b1;
                        reg_Rin_en = 1'b0;
	               	    reg_Q_en = 1'b0;
                        mux_smaller_X = 1'b1;
                        state_next = R1;     
                    end
                    else begin
                        rdy_next = 1'b0;
                        counter_next = div_count - 1;
                        reg_Rin_en = 1'b1;
                        reg_Q_en = 1'b1;
                        mux_smaller_X = 1'b0;
                        state_next = Rounds;
	               	end
	           	end
	           	else begin
    	           	counter_next = 7'd0;
	           	    rdy_next = 1'b0;                  
	               	reg_Rin_en = 1'b0;
	               	reg_Q_en = 1'b0;
	               	mux_smaller_X = 1'b0;
	               	state_next = R1;
	           	end
	       	end

	       	Rounds: begin
	       		if(counter_reg != 7'd0) begin
			   		mux_A_sel = counter_reg;
			   		counter_next = counter_next - 1;
			   		rdy_next = 1'b0;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;		       	
			       	mux_smaller_X = 1'b0;
			       	state_next = Rounds;
	           	end

	           	else begin
	           		mux_A_sel = counter_reg;
                    counter_next = 7'd0;
                    rdy_next = 1'b1;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;			       	
			       	mux_smaller_X = 1'b0;
			       	state_next = R1;
	           	end
	       	end


	       	default: begin
	           	counter_next = 7'd0;
	           	mux_A_sel = 5'b0;
	           	rdy_next = 0;
	           	mux_Rin_sel = 0;
	           	reg_Rin_en = 0;
	           	reg_Q_en = 0;
	           	mux_smaller_X = 1'b0;
	           	state_next = R1;
	       	end

        endcase
	end
endmodule
