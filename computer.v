// computer.v — toplevel 8 bits + IR + control_unit + data_memory + saltos

module computer(
  input              clk,
  output      [7:0]  alu_out_bus   // expuesto para waveform
);
  // --- Buses internos visibles en el TB ---
  wire [7:0]  pc_out_bus;          // PC (8b)
  wire [14:0] im_out_bus;          // [14:8]=opcode(7), [7:0]=literal(8)

  // Instruction Register — combinacional (sin latencia)
  wire [14:0] IR = im_out_bus;

  // Decodificación
  wire [6:0]  opcode  = IR[14:8];
  wire [7:0]  literal = IR[7:0];

  // Registros A y B
  wire [7:0]  regA_out_bus, regB_out_bus;

  // Señales de control (desde control_unit)
  wire        LA, LB;        // enable de carga A/B
  wire [1:0]  SA, SB;        // selects de fuentes a la ALU
  wire [3:0]  S;             // operación ALU

  // Señales de control de memoria de datos (desde control_unit)
  wire        MW;            // ≡ DW: write enable data memory
  wire        MA;            // ≡ SD0: 0: addr=literal, 1: addr=B
  wire [1:0]  WSEL;          // 00=ALU, 01=A, 10=B, 11=ZERO

  // Señal de salto (desde control_unit)
  wire        LP;            // load PC

  // Fuentes hacia la ALU
  wire [7:0]  srcA, srcB;

  // --------- Data memory wires ---------
  wire [7:0] mem_out_bus;
  wire [7:0] mem_addr;
  wire [7:0] mem_din;

  // Valor a cargar al PC en saltos (usamos el literal)
  wire [7:0] pc_load_val = literal;

  // ----------------- Instancias -----------------

  // PC de 8 bits con salto (load/din)
  pc #(.N(8)) PC (
    .clk (clk),
    .load(LP),
    .din (pc_load_val),
    .pc  (pc_out_bus)
  );

  // Memoria de instrucciones 15b (opcode+literal)
  instruction_memory #(.AW(8), .DW(15)) IM (
    .address(pc_out_bus),
    .out(im_out_bus)
  );

  // --- Flags: ALU (combinacionales) -> STATUS (latcheados) ---
  wire z_alu, n_alu, c_alu, v_alu;  // salida directa de la ALU
  wire Z, N, C, V;                  // flags latcheados (reales del CPU)

  // Habilitación: NO actualizar flags durante un salto puro (LP=1)
  wire STATUS_EN = ~LP;

  status STATUS (
    .clk  (clk),
    .en   (STATUS_EN),
    .z_in (z_alu), .n_in(n_alu), .c_in(c_alu), .v_in(v_alu),
    .Z(Z), .N(N), .C(C), .V(V)
  );

  // Unidad de control: decodifica opcode -> señales de control (incluye memoria y saltos)
  control_unit CTRL (
    .opcode(opcode),
    // flags latcheados
    .Z(Z), .N(N), .C(C), .V(V),
    // registros y ALU
    .LA(LA), .LB(LB),
    .SA(SA), .SB(SB),
    .S(S),
    // memoria de datos
    .MW(MW), .MA(MA), .WSEL(WSEL),
    // saltos
    .LP(LP)
  );

  // Registros A y B (8b) con enable — sin gateo de primer ciclo
  register #(.N(8)) regA (
    .clk(clk), .data(alu_out_bus), .load(LA), .out(regA_out_bus)
  );

  register #(.N(8)) regB (
    .clk(clk), .data(alu_out_bus), .load(LB), .out(regB_out_bus)
  );

  // ----------------- Data Memory -----------------
  // Dirección: literal o B según MA
  assign mem_addr = (MA) ? regB_out_bus : literal;

  // Dato a escribir en Mem según WSEL
  assign mem_din  = (WSEL==2'b00) ? alu_out_bus   // ALU
                   : (WSEL==2'b01) ? regA_out_bus // A
                   : (WSEL==2'b10) ? regB_out_bus // B
                   : 8'h00;                       // ZERO

  data_memory #(.AW(8)) DM (
    .clk (clk),
    .addr(mem_addr),
    .din (mem_din),
    .we  (MW),              // sin gateo
    .dout(mem_out_bus)
  );

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
                              mem_out_bus; // Mem cuando SB==11

  // ALU 8 bits
  alu ALU (
    .a   (srcA),
    .b   (srcB),
    .s   (S),
    .out (alu_out_bus),
    .z   (z_alu), .n(n_alu), .c(c_alu), .v(v_alu)
  );

endmodule
