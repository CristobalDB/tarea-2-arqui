module instruction_memory #(parameter AW=8, parameter DW=15)(
  input      [AW-1:0] address,
  output     [DW-1:0] out
);
  reg [DW-1:0] mem [0:(1<<AW)-1];
  assign out = mem[address];
endmodule

