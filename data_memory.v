// data_memory.v — RAM de datos: 2^AW x 8 bits
module data_memory #(parameter AW=8)(
  input              clk,
  input      [AW-1:0] addr,
  input       [7:0]  din,
  input              we,      // write enable
  output      [7:0]  dout
);
  reg [7:0] mem [0:(1<<AW)-1];

  // Lectura combinacional
  assign dout = mem[addr];

  // Escritura síncrona
  always @(posedge clk) begin
    if (we) mem[addr] <= din;
  end
endmodule
