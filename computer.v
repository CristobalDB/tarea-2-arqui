module computer(
  input              clk,
  output      [7:0]  alu_out_bus
);
  // --- Buses internos visibles en el TB ---
  wire [7:0]  pc_out_bus;
  wire [14:0] im_out_bus;
  reg  [14:0] IR;

  // Decodificación
  wire [6:0]  opcode  = IR[14:8];
  wire [7:0]  literal = IR[7:0];

  // Registros A y B
  wire [7:0]  regA_out_bus, regB_out_bus;

  // Señales de control (desde control_unit)
  wire        LA, LB;
  wire [1:0]  SA, SB;
  wire [3:0]  S;

  // >>> NUEVAS señales de control para Memoria de Datos <<<
  wire        MW;          // write enable a data_memory
  wire        MA;          // 0 = address = literal ; 1 = address = B
  wire [1:0]  WSEL;        // qué dato escribimos en memoria:
                           // 00=ALU, 01=A, 10=B, 11=ZERO

  // ALU sources
  wire [7:0]  srcA, srcB;

  // Flags
  wire Z, N, C, V;

  // ----------------- Instancias -----------------

  // PC
  pc #(.N(8)) PC (.clk(clk), .pc(pc_out_bus));

  // Instruction Memory
  instruction_memory #(.AW(8), .DW(15)) IM (
    .address(pc_out_bus),
    .out(im_out_bus)
  );

  // IR
  always @(posedge clk) IR <= im_out_bus;

  // >>> Data Memory <<<
  wire [7:0] mem_out_bus;
  wire [7:0] mem_addr = (MA) ? regB_out_bus : literal;

  // Dato a escribir en Mem según WSEL
  wire [7:0] mem_din =
      (WSEL==2'b00) ? alu_out_bus :
      (WSEL==2'b01) ? regA_out_bus :
      (WSEL==2'b10) ? regB_out_bus :
                      8'h00; // 2'b11 => ZERO

  data_memory #(.AW(8)) DM (
    .clk (clk),
    .addr(mem_addr),
    .din (mem_din),
    .we  (MW),
    .dout(mem_out_bus)
  );

  // Control Unit (ahora con señales de memoria)
  control_unit CTRL (
    .opcode(opcode),
    .LA(LA), .LB(LB),
    .SA(SA), .SB(SB),
    .S(S),
    .MW(MW), .MA(MA), .WSEL(WSEL)
  );

  // Registros A/B
  register #(.N(8)) regA (.clk(clk), .data(alu_out_bus), .load(LA), .out(regA_out_bus));
  register #(.N(8)) regB (.clk(clk), .data(alu_out_bus), .load(LB), .out(regB_out_bus));

  // Selección de fuentes para la ALU
  // SA: 00->0x00, 01->A, 10->B, 11->0x01
  // SB: 00->B,   01->Lit, 10->A, 11->Mem
  assign srcA = (SA==2'b00) ? 8'h00 :
                (SA==2'b01) ? regA_out_bus :
                (SA==2'b10) ? regB_out_bus :
                              8'h01;

  assign srcB = (SB==2'b00) ? regB_out_bus :
                (SB==2'b01) ? literal :
                (SB==2'b10) ? regA_out_bus :
                              mem_out_bus; // <<< ahora SB==11 es Mem[...]

  // ALU
  alu ALU (.a(srcA), .b(srcB), .s(S), .out(alu_out_bus), .z(Z), .n(N), .c(C), .v(V));
endmodule
