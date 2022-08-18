module MD_out(
    input [127:0] P_QR_i,
    input [1:0] signs_i,
    input [3:0] md_op_i,
    output [63:0] md_result_o
    );
    
    // division signals
    wire [63:0] Q, R, Q_2C, R_2C, out_Rs, out_Qs, out_Q, out_R, d_result;   
    
    // multiplication signals
    wire [127:0] P_2C, P_s, P_su;
    wire [63:0] m_result;
   
    // division output assignment w.r.t. current instruction
    assign Q = P_QR_i[127:64];
    assign R = P_QR_i[63:0];
    
    assign Q_2C = ~Q + 1;
    assign R_2C = ~R + 1;

    assign out_Qs = signs_i[1] ? (signs_i[0] ? Q : Q_2C) : (signs_i[0] ? Q_2C : Q);
    assign out_Q = md_op_i[0] ? Q : out_Qs;

    assign out_Rs = signs_i[0] ? R_2C : R;
    assign out_R = md_op_i[0] ? R : out_Rs;

    assign d_result = md_op_i[1] ? (md_op_i[3] ? {{32{out_R[31]}}, out_R[31:0]}: out_R) : (md_op_i[3] ? {{32{out_Q[31]}}, out_Q[31:0]} : out_Q);
      
    // multiplication output assignment w.r.t. current instruction
    assign P_2C = ~P_QR_i + 1;

    assign P_s = signs_i[1] ? (signs_i[0] ? P_QR_i : P_2C) : (signs_i[0] ? P_2C : P_QR_i);
    assign P_su = signs_i[1] ? P_2C : P_QR_i;

    assign m_result = md_op_i[1] ? (md_op_i[0] ? P_QR_i[127:64] : P_su[127:64]) : (md_op_i[0] ? P_s[127:64] : (md_op_i[3] ? {{32{P_s[31]}}, P_s[31:0]} : P_s[63:0]));

    // final output assignment
    assign md_result_o = md_op_i[2] ? d_result : m_result;

endmodule
