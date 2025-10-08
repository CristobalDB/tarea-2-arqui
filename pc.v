// pc.v — PC con carga (jump)
module pc #(parameter N=8)(
  input              clk,
  input              load,       // nuevo: cargar PC
  input      [N-1:0] din,        // nuevo: valor a cargar
  output reg [N-1:0] pc
);
  initial pc = {N{1'b0}};
  always @(posedge clk) begin
    if (load) pc <= din;
    else      pc <= pc + 1'b1;
  end
endmodule
