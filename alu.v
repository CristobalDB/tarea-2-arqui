// alu.v — ALU de 8 bits con flags Z, N, C, V
// Mapa de operaciones (s):
// 0: ADD   1: SUB   2: AND   3: OR   4: NOT   5: XOR
// 6: SHL   7: SHR   8: INC

module alu(
  input      [7:0] a,
  input      [7:0] b,
  input      [3:0] s,          // selector de operación
  output reg [7:0] out,
  output            z,         // Zero
  output            n,         // Negative (MSB)
  output reg        c,         // Carry (o bit desplazado)
  output reg        v          // Overflow aritmético
);

  reg [8:0] sum_ext, diff_ext; // extensiones para carry/borrow

  always @* begin
    out = 8'h00;
    c   = 1'b0;
    v   = 1'b0;
    sum_ext  = 9'd0;
    diff_ext = 9'd0;

    case (s)
      4'd0: begin // ADD
        sum_ext = {1'b0, a} + {1'b0, b};
        out = sum_ext[7:0];
        c   = sum_ext[8];
        v   = (~(a[7]^b[7])) & (out[7]^a[7]); // overflow suma
      end
      4'd1: begin // SUB
        diff_ext = {1'b0, a} - {1'b0, b};
        out = diff_ext[7:0];
        c   = ~diff_ext[8];                   // carry = ~borrow  ✅
        v   = (a[7]^b[7]) & (out[7]^a[7]);    // overflow resta
      end
      4'd2: out = a & b;                      // AND
      4'd3: out = a | b;                      // OR
      4'd4: begin                             // NOT (unaria sobre 'a')
        out = ~a;
        c   = 1'b0;
        v   = 1'b0;
      end
      4'd5: out = a ^ b;                      // XOR
      4'd6: begin                             // SHL (lógico) de 'a'
        out = a << 1;
        c   = a[7];                           // bit que se “va” por la izquierda
      end
      4'd7: begin                             // SHR (lógico) de 'a'
        out = a >> 1;
        c   = a[0];                           // bit que se “va” por la derecha
      end
      4'd8: begin                             // INC: a + 1
        sum_ext = {1'b0, a} + 9'd1;
        out = sum_ext[7:0];
        c   = sum_ext[8];
        v   = (~(a[7]^1'b0)) & (out[7]^a[7]); // overflow en +1
      end
      default: begin
        out = 8'h00;
        c   = 1'b0;
        v   = 1'b0;
      end
    endcase
  end

  assign z = (out == 8'h00);
  assign n = out[7];

endmodule
