module pc #(parameter N=8)(
  input              clk,
  output reg [N-1:0] pc
);
  initial pc = {N{1'b0}};
  always @(posedge clk) pc <= pc + 1'b1;
endmodule

