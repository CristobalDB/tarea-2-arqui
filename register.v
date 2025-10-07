module register #(parameter N=8)(
  input              clk,
  input      [N-1:0] data,
  input              load,
  output reg [N-1:0] out
);
  initial out = {N{1'b0}};
  always @(posedge clk) if (load) out <= data;
endmodule

