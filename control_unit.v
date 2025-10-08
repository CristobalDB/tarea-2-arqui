// control_unit.v — básicas + memoria (Dir)/(B) + CMP + Jumps
module control_unit(
  input  [6:0] opcode,
  input        Z, N, C, V,        // flags desde la ALU
  output reg       LA, LB,        // load de A/B
  output reg [1:0] SA, SB,        // selects hacia ALU (a/b)
  output reg [3:0] S,             // operación ALU
  // control RAM de datos
  output reg       MW,            // write enable memoria
  output reg       MA,            // 0: addr = literal ; 1: addr = B
  output reg [1:0] WSEL,          // 00=ALU, 01=A, 10=B, 11=ZERO
  // saltos
  output reg       LP             // load PC (PC := literal) cuando 1
);
  // SA: 00->0x00(Z), 01->A, 10->B, 11->0x01
  localparam SA_Z=2'b00, SA_A=2'b01, SA_B=2'b10, SA_U=2'b11;
  // SB: 00->B, 01->Lit, 10->A, 11->Mem
  localparam SB_B=2'b00, SB_L=2'b01, SB_A=2'b10, SB_M=2'b11;

  // ALU ops (debe calzar con alu.v)
  localparam ADD=4'd0, SUB=4'd1, AND_=4'd2, OR_=4'd3, NOT_=4'd4,
             XOR_=4'd5, SHL=4'd6, SHR=4'd7, INC=4'd8;

  // WSEL: dato a escribir en Mem
  localparam W_ALU=2'b00, W_A=2'b01, W_B=2'b10, W_Z=2'b11;

  always @* begin
    // Defaults (NOP)
    LA=0; LB=0;
    SA=SA_Z; SB=SB_B; S=ADD;
    MW=0; MA=0; WSEL=W_ALU;
    LP=0;

    case (opcode)

      // ======== INSTRUCCIONES BÁSICAS ========
      // MOV
      7'b0000000: begin LA=1; SA=SA_Z; SB=SB_B; S=ADD; end // MOV A,B  -> A=0+B
      7'b0000001: begin LB=1; SA=SA_Z; SB=SB_A; S=ADD; end // MOV B,A  -> B=0+A
      7'b0000010: begin LA=1; SA=SA_Z; SB=SB_L; S=ADD; end // MOV A, Lit
      7'b0000011: begin LB=1; SA=SA_Z; SB=SB_L; S=ADD; end // MOV B, Lit

      // ADD
      7'b0000100: begin LA=1; SA=SA_A; SB=SB_B; S=ADD; end // ADD A,B
      7'b0000101: begin LB=1; SA=SA_B; SB=SB_A; S=ADD; end // ADD B,A
      7'b0000110: begin LA=1; SA=SA_A; SB=SB_L; S=ADD; end // ADD A,Lit
      7'b0000111: begin LB=1; SA=SA_B; SB=SB_L; S=ADD; end // ADD B,Lit

      // SUB (tu test usa SUB B,A => B = A - B)
      7'b0001000: begin LA=1; SA=SA_A; SB=SB_B; S=SUB; end // SUB A,B
      7'b0001001: begin LB=1; SA=SA_A; SB=SB_B; S=SUB; end // SUB B,A  (B=A-B)
      7'b0001010: begin LA=1; SA=SA_A; SB=SB_L; S=SUB; end // SUB A,Lit
      7'b0001011: begin LB=1; SA=SA_B; SB=SB_L; S=SUB; end // SUB B,Lit

      // AND
      7'b0001100: begin LA=1; SA=SA_A; SB=SB_B; S=AND_; end
      7'b0001101: begin LB=1; SA=SA_B; SB=SB_A; S=AND_; end
      7'b0001110: begin LA=1; SA=SA_A; SB=SB_L; S=AND_; end
      7'b0001111: begin LB=1; SA=SA_B; SB=SB_L; S=AND_; end

      // OR
      7'b0010000: begin LA=1; SA=SA_A; SB=SB_B; S=OR_; end
      7'b0010001: begin LB=1; SA=SA_B; SB=SB_A; S=OR_; end
      7'b0010010: begin LA=1; SA=SA_A; SB=SB_L; S=OR_; end
      7'b0010011: begin LB=1; SA=SA_B; SB=SB_L; S=OR_; end

      // NOT (unaria sobre 'a')
      7'b0010100: begin LA=1; SA=SA_A;            S=NOT_; end // NOT A,A
      7'b0010101: begin LA=1; SA=SA_B;            S=NOT_; end // NOT A,B
      7'b0010110: begin LB=1; SA=SA_A;            S=NOT_; end // NOT B,A
      7'b0010111: begin LB=1; SA=SA_B;            S=NOT_; end // NOT B,B

      // XOR
      7'b0011000: begin LA=1; SA=SA_A; SB=SB_B; S=XOR_; end
      7'b0011001: begin LB=1; SA=SA_B; SB=SB_A; S=XOR_; end
      7'b0011010: begin LA=1; SA=SA_A; SB=SB_L; S=XOR_; end
      7'b0011011: begin LB=1; SA=SA_B; SB=SB_L; S=XOR_; end

      // SHL/SHR (unarias sobre 'a')
      7'b0011100: begin LA=1; SA=SA_A; S=SHL; end // SHL A,A
      7'b0011101: begin LA=1; SA=SA_B; S=SHL; end // SHL A,B
      7'b0011110: begin LB=1; SA=SA_A; S=SHL; end // SHL B,A
      7'b0011111: begin LB=1; SA=SA_B; S=SHL; end // SHL B,B

      7'b0100000: begin LA=1; SA=SA_A; S=SHR; end // SHR A,A
      7'b0100001: begin LA=1; SA=SA_B; S=SHR; end // SHR A,B
      7'b0100010: begin LB=1; SA=SA_A; S=SHR; end // SHR B,A
      7'b0100011: begin LB=1; SA=SA_B; S=SHR; end // SHR B,B

      // INC B (usado por tu test)
      7'b0100100: begin LB=1; SA=SA_U; SB=SB_B; S=ADD; end // B = 1 + B

      // ======== INSTRUCCIONES CON MEMORIA ========
      // MOV desde Mem
      7'b0100101: begin LA=1; MA=0; SA=SA_Z; SB=SB_M; S=ADD; end // MOV A,(Dir)
      7'b0100110: begin LB=1; MA=0; SA=SA_Z; SB=SB_M; S=ADD; end // MOV B,(Dir)
      7'b0101001: begin LA=1; MA=1; SA=SA_Z; SB=SB_M; S=ADD; end // MOV A,(B)
      7'b0101010: begin LB=1; MA=1; SA=SA_Z; SB=SB_M; S=ADD; end // MOV B,(B)
      // MOV hacia Mem
      7'b0100111: begin MW=1; MA=0; WSEL=W_A; end // (Dir),A
      7'b0101000: begin MW=1; MA=0; WSEL=W_B; end // (Dir),B
      7'b0101011: begin MW=1; MA=1; WSEL=W_A; end // (B),A

      // ADD con Mem y a Mem
      7'b0101100: begin LA=1; MA=0; SA=SA_A; SB=SB_M; S=ADD; end // ADD A,(Dir)
      7'b0101101: begin LB=1; MA=0; SA=SA_B; SB=SB_M; S=ADD; end // ADD B,(Dir)
      7'b0101110: begin LA=1; MA=1; SA=SA_A; SB=SB_M; S=ADD; end // ADD A,(B)
      7'b0101111: begin MW=1; MA=0; SA=SA_A; SB=SB_B; S=ADD; WSEL=W_ALU; end // (Dir)=A+B

      // SUB con Mem y a Mem
      7'b0110000: begin LA=1; MA=0; SA=SA_A; SB=SB_M; S=SUB; end // SUB A,(Dir)
      7'b0110001: begin LB=1; MA=0; SA=SA_B; SB=SB_M; S=SUB; end // SUB B,(Dir)
      7'b0110010: begin LA=1; MA=1; SA=SA_A; SB=SB_M; S=SUB; end // SUB A,(B)
      7'b0110011: begin MW=1; MA=0; SA=SA_A; SB=SB_B; S=SUB; WSEL=W_ALU; end // (Dir)=A-B

      // AND con Mem y a Mem
      7'b0110100: begin LA=1; MA=0; SA=SA_A; SB=SB_M; S=AND_; end
      7'b0110101: begin LB=1; MA=0; SA=SA_B; SB=SB_M; S=AND_; end
      7'b0110110: begin LA=1; MA=1; SA=SA_A; SB=SB_M; S=AND_; end
      7'b0110111: begin MW=1; MA=0; SA=SA_A; SB=SB_B; S=AND_; WSEL=W_ALU; end

      // OR con Mem y a Mem
      7'b0111000: begin LA=1; MA=0; SA=SA_A; SB=SB_M; S=OR_;  end
      7'b0111001: begin LB=1; MA=0; SA=SA_B; SB=SB_M; S=OR_;  end
      7'b0111010: begin LA=1; MA=1; SA=SA_A; SB=SB_M; S=OR_;  end
      7'b0111011: begin MW=1; MA=0; SA=SA_A; SB=SB_B; S=OR_;  WSEL=W_ALU; end

      // NOT hacia Mem (unaria sobre 'a')
      7'b0111100: begin MW=1; MA=0; SA=SA_A; S=NOT_; WSEL=W_ALU; end // NOT (Dir),A
      7'b0111101: begin MW=1; MA=0; SA=SA_B; S=NOT_; WSEL=W_ALU; end // NOT (Dir),B
      7'b0111110: begin MW=1; MA=1; SA=SA_A; S=NOT_; WSEL=W_ALU; end // NOT (B) = ~A

      // XOR con Mem y a Mem
      7'b0111111: begin LA=1; MA=0; SA=SA_A; SB=SB_M; S=XOR_; end // XOR A,(Dir)
      7'b1000000: begin LB=1; MA=0; SA=SA_B; SB=SB_M; S=XOR_; end // XOR B,(Dir)
      7'b1000001: begin LA=1; MA=1; SA=SA_A; SB=SB_M; S=XOR_; end // XOR A,(B)
      7'b1000010: begin MW=1; MA=0; SA=SA_A; SB=SB_B; S=XOR_; WSEL=W_ALU; end // (Dir)=A^B

      // SHL/SHR hacia Mem
      7'b1000011: begin MW=1; MA=0; SA=SA_A; S=SHL; WSEL=W_ALU; end // SHL (Dir),A
      7'b1000100: begin MW=1; MA=0; SA=SA_B; S=SHL; WSEL=W_ALU; end // SHL (Dir),B
      7'b1000101: begin MW=1; MA=1; SA=SA_A; S=SHL; WSEL=W_ALU; end // SHL (B)=A<<1

      7'b1000110: begin MW=1; MA=0; SA=SA_A; S=SHR; WSEL=W_ALU; end // SHR (Dir),A
      7'b1000111: begin MW=1; MA=0; SA=SA_B; S=SHR; WSEL=W_ALU; end // SHR (Dir),B
      7'b1001000: begin MW=1; MA=1; SA=SA_A; S=SHR; WSEL=W_ALU; end // SHR (B)=A>>1

      // INC/RST en Mem (INC: 1 + Mem)
      7'b1001001: begin MW=1; MA=0; SA=SA_U; SB=SB_M; S=ADD; WSEL=W_ALU; end // INC (Dir)
      7'b1001010: begin MW=1; MA=1; SA=SA_U; SB=SB_M; S=ADD; WSEL=W_ALU; end // INC (B)
      7'b1001011: begin MW=1; MA=0; WSEL=W_Z; end // RST (Dir)
      7'b1001100: begin MW=1; MA=1; WSEL=W_Z; end // RST (B)

      // ======== CMP (setean flags con SUB; no escriben A/B/Mem) ========
      7'b1001101: begin /* CMP A,B    */ SA=SA_A; SB=SB_B; S=SUB; end
      7'b1001110: begin /* CMP A,Lit  */ SA=SA_A; SB=SB_L; S=SUB; end
      7'b1001111: begin /* CMP B,Lit  */ SA=SA_B; SB=SB_L; S=SUB; end
      7'b1010000: begin /* CMP A,(Dir)*/ MA=0; SA=SA_A; SB=SB_M; S=SUB; end
      7'b1010001: begin /* CMP B,(Dir)*/ MA=0; SA=SA_B; SB=SB_M; S=SUB; end
      7'b1010010: begin /* CMP A,(B)  */ MA=1; SA=SA_A; SB=SB_M; S=SUB; end

      // ======== JUMPS (PC := literal si se cumple la condición) ========
      7'b1010011: begin                    LP = 1'b1; end            // JMP
      7'b1010100: begin if ( Z     )       LP = 1'b1; end            // JEQ
      7'b1010101: begin if (!Z     )       LP = 1'b1; end            // JNE
      7'b1010110: begin if (!N && !Z)      LP = 1'b1; end            // JGT
      7'b1010111: begin if ( N     )       LP = 1'b1; end            // JLT
      7'b1011000: begin if (!N     )       LP = 1'b1; end            // JGE
      7'b1011001: begin if ( N || Z)       LP = 1'b1; end            // JLE
      7'b1011010: begin if ( C     )       LP = 1'b1; end            // JCR
      7'b1011011: begin if ( V     )       LP = 1'b1; end            // JOV

      default: ; // NOP
    endcase
  end
endmodule
