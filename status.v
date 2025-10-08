// status.v — latch de flags de la ALU (se actualizan al flanco si en=1)
module status(
  input      clk,
  input      en,          // habilita actualizar flags este ciclo
  input      z_in, n_in, c_in, v_in,
  output reg Z, N, C, V
);
  always @(posedge clk) begin
    if (en) begin
      Z <= z_in;
      N <= n_in;
      C <= c_in;
      V <= v_in;
    end
  end
endmodule
