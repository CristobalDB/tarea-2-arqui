`timescale 1ns/1ps
module test;
    reg           clk = 0;
    wire [7:0]    regA_out;
    wire [7:0]    regB_out;

    reg           mov_test_failed      = 1'b0;
    reg           reg_mov_test_failed  = 1'b0;
    reg           add_test_failed      = 1'b0;
    reg           sub_test_failed      = 1'b0;
    reg           and_test_failed      = 1'b0;
    reg           or_test_failed       = 1'b0;
    reg           not_test_failed      = 1'b0;
    reg           xor_test_failed      = 1'b0;
    reg           shl_test_failed      = 1'b0;
    reg           shr_test_failed      = 1'b0;
    reg           inc_test_failed      = 1'b0;

    // ------------------------------------------------------------
    // Instancia de tu computador (NO CAMBIAR nombres internos)
    // ------------------------------------------------------------
    computer Comp(.clk(clk));
    // ------------------------------------------------------------

    // ------------------------------------------------------------
    // Exponer las salidas de tus registros para el TB
    // ------------------------------------------------------------
    assign regA_out = Comp.regA.out;
    assign regB_out = Comp.regB.out;
    // ------------------------------------------------------------

    // ====== TAREAS para sincronizar con la latencia de 1 ciclo ======
    // 1 flanco para “precargar” la instrucción 0 al IR
    task prefetch_first; begin
        @(posedge clk); #1;
    end endtask

    // Avanza EXACTAMENTE una instrucción (ejecuta la que ya estaba en el IR)
    task step; begin
        @(posedge clk); #1;  // tras este flanco ya ocurrió el write-back
    end endtask
    // ================================================================

    initial begin
        $dumpfile("out/dump.vcd");
        $dumpvars(0, test);
        $readmemb("im.dat", Comp.IM.mem);

        // --- Test 0: MOV Literal Instructions ---
        $display("\n----- STARTING TEST 0: MOV A,Lit & MOV B,Lit -----");

        // Reemplaza el #3 inicial por: prefetch + ejecutar 1 instrucción
        prefetch_first();
        step(); // ejecuta: MOV A, 42
        $display("CHECK @ t=%0t: After MOV A, 42 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd42) begin
            $error("FAIL: regA expected 42, got %d", regA_out);
            mov_test_failed = 1'b1;
        end

        step(); // ejecuta: MOV B, 123
        $display("CHECK @ t=%0t: After MOV B, 123 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd123) begin
            $error("FAIL: regB expected 123, got %d", regB_out);
            mov_test_failed = 1'b1;
        end

        if (!mov_test_failed) $display(">>>>> MOV TEST PASSED! <<<<< ");
        else                  $display(">>>>> MOV TEST FAILED! <<<<< ");

        // --- Test 1: Register-to-Register MOV Instructions ---
        $display("\n----- STARTING TEST 1: MOV A,B & MOV B,A -----");

        step(); // MOV B, 85
        $display("CHECK @ t=%0t: After MOV B, 85 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd85) begin
            $error("FAIL: regB expected 85, got %d", regB_out);
            reg_mov_test_failed = 1'b1;
        end

        step(); // MOV A, 170
        $display("CHECK @ t=%0t: After MOV A, 170 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd170) begin
            $error("FAIL: regA expected 170, got %d", regA_out);
            reg_mov_test_failed = 1'b1;
        end

        step(); // MOV A, B
        $display("CHECK @ t=%0t: After MOV A, B -> regA = %d, regB = %d", $time, regA_out, regB_out);
        if (regA_out !== 8'd85) begin
            $error("FAIL: regA expected 85 (value from B), got %d", regA_out);
            reg_mov_test_failed = 1'b1;
        end
        if (regB_out !== 8'd85) begin
            $error("FAIL: Source regB should not change. Expected 85, got %d", regB_out);
            reg_mov_test_failed = 1'b1;
        end

        step(); // MOV A, 99
        $display("CHECK @ t=%0t: After MOV A, 99 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd99) begin
            $error("FAIL: regA expected 99, got %d", regA_out);
            reg_mov_test_failed = 1'b1;
        end

        step(); // MOV B, A
        $display("CHECK @ t=%0t: After MOV B, A -> regA = %d, regB = %d", $time, regA_out, regB_out);
        if (regB_out !== 8'd99) begin
            $error("FAIL: regB expected 99 (value from A), got %d", regB_out);
            reg_mov_test_failed = 1'b1;
        end
        if (regA_out !== 8'd99) begin
            $error("FAIL: Source regA should not change. Expected 99, got %d", regA_out);
            reg_mov_test_failed = 1'b1;
        end

        if (!reg_mov_test_failed) $display(">>>>> REGISTER MOV TEST PASSED! <<<<< ");
        else                      $display(">>>>> REGISTER MOV TEST FAILED! <<<<< ");

        // --- Test 2: ADD Instructions (Register and Literal) ---
        $display("\n----- STARTING TEST 2: ADD Instructions -----");

        step(); // MOV A, 2
        $display("CHECK @ t=%0t: After MOV A, 2 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd2) begin
            $error("FAIL: regA expected 2, got %d", regA_out);
            add_test_failed = 1'b1;
        end

        step(); // MOV B, 3
        $display("CHECK @ t=%0t: After MOV B, 3 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd3) begin
            $error("FAIL: regB expected 3, got %d", regB_out);
            add_test_failed = 1'b1;
        end

        step(); // ADD A, B
        $display("CHECK @ t=%0t: After ADD A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd5) begin
            $error("FAIL: regA expected 5 (2+3), got %d", regA_out);
            add_test_failed = 1'b1;
        end

        step(); // ADD A, 10
        $display("CHECK @ t=%0t: After ADD A, 10 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd15) begin
            $error("FAIL: regA expected 15 (5+10), got %d", regA_out);
            add_test_failed = 1'b1;
        end

        step(); // ADD B, 20
        $display("CHECK @ t=%0t: After ADD B, 20 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd23) begin
            $error("FAIL: regB expected 23 (3+20), got %d", regB_out);
            add_test_failed = 1'b1;
        end

        if (!add_test_failed) $display(">>>>> ALL ADD TESTS PASSED! <<<<< ");
        else                  $display(">>>>> ADD TEST FAILED! <<<<< ");

        // --- Test 3: SUB Instructions ---
        $display("\n----- STARTING TEST 3: All SUB Instructions -----");

        step(); // MOV A, 20
        $display("CHECK @ t=%0t: After MOV A, 20 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd20) begin
            $error("FAIL: regA expected 20, got %d", regA_out);
            sub_test_failed = 1'b1;
        end

        step(); // MOV B, 5
        $display("CHECK @ t=%0t: After MOV B, 5 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd5) begin
            $error("FAIL: regB expected 5, got %d", regB_out);
            sub_test_failed = 1'b1;
        end

        step(); // SUB A, B
        $display("CHECK @ t=%0t: After SUB A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd15) begin
            $error("FAIL: regA expected 15 (20-5), got %d", regA_out);
            sub_test_failed = 1'b1;
        end

        step(); // SUB B, A
        $display("CHECK @ t=%0t: After SUB B, A -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd10) begin
            $error("FAIL: regB expected 10 (15-5), got %d", regB_out);
            sub_test_failed = 1'b1;
        end

        step(); // SUB A, 7
        $display("CHECK @ t=%0t: After SUB A, 7 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd8) begin
            $error("FAIL: regA expected 8 (15-7), got %d", regA_out);
            sub_test_failed = 1'b1;
        end

        step(); // SUB B, 10
        $display("CHECK @ t=%0t: After SUB B, 10 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd0) begin
            $error("FAIL: regB expected 0 (10-10 = 0), got %d", regB_out);
            sub_test_failed = 1'b1;
        end

        if (!sub_test_failed) $display(">>>>> ALL SUB TESTS PASSED! <<<<< ");
        else                  $display(">>>>> SUB TEST FAILED! <<<<< ");

        // --- Test 4: AND Instructions ---
        $display("\n----- STARTING TEST 4: All AND Instructions -----");

        step(); // MOV A, 202
        $display("CHECK @ t=%0t: After MOV A, 202 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd202) begin
            $error("FAIL: regA expected 202, got %d", regA_out);
            and_test_failed = 1'b1;
        end

        step(); // MOV B, 174
        $display("CHECK @ t=%0t: After MOV B, 174 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd174) begin
            $error("FAIL: regB expected 174, got %d", regB_out);
            and_test_failed = 1'b1;
        end

        step(); // AND A, B
        $display("CHECK @ t=%0t: After AND A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd138) begin
            $error("FAIL: regA expected 138 (202 & 174), got %d", regA_out);
            and_test_failed = 1'b1;
        end

        step(); // AND B, A
        $display("CHECK @ t=%0t: After AND B, A -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd138) begin
            $error("FAIL: regB expected 138 (174 & 138), got %d", regB_out);
            and_test_failed = 1'b1;
        end

        step(); // MOV A, 240
        $display("CHECK @ t=%0t: After MOV A, 240 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd240) begin
            $error("FAIL: regA expected 240, got %d", regA_out);
            and_test_failed = 1'b1;
        end

        step(); // AND A, 85
        $display("CHECK @ t=%0t: After AND A, 85 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd80) begin
            $error("FAIL: regA expected 80 (240 & 85), got %d", regA_out);
            and_test_failed = 1'b1;
        end

        step(); // MOV B, 204
        $display("CHECK @ t=%0t: After MOV B, 204 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd204) begin
            $error("FAIL: regB expected 204, got %d", regB_out);
            and_test_failed = 1'b1;
        end

        step(); // AND B, 170
        $display("CHECK @ t=%0t: After AND B, 170 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd136) begin
            $error("FAIL: regB expected 136 (204 & 170), got %d", regB_out);
            and_test_failed = 1'b1;
        end

        if (!and_test_failed) $display(">>>>> ALL AND TESTS PASSED! <<<<< ");
        else                  $display(">>>>> AND TEST FAILED! <<<<< ");

        // --- Test 5: OR Instructions ---
        $display("\n----- STARTING TEST 5: All OR Instructions -----");

        step(); // MOV A, 202
        $display("CHECK @ t=%0t: After MOV A, 202 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd202) begin
            $error("FAIL: regA expected 202, got %d", regA_out);
            or_test_failed = 1'b1;
        end

        step(); // MOV B, 174
        $display("CHECK @ t=%0t: After MOV B, 174 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd174) begin
            $error("FAIL: regB expected 174, got %d", regB_out);
            or_test_failed = 1'b1;
        end

        step(); // OR A, B
        $display("CHECK @ t=%0t: After OR A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd238) begin
            $error("FAIL: regA expected 238 (202 | 174), got %d", regA_out);
            or_test_failed = 1'b1;
        end

        step(); // OR B, A
        $display("CHECK @ t=%0t: After OR B, A -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd238) begin
            $error("FAIL: regB expected 238 (174 | 238), got %d", regB_out);
            or_test_failed = 1'b1;
        end

        step(); // MOV A, 51
        $display("CHECK @ t=%0t: After MOV A, 51 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd51) begin
            $error("FAIL: regA expected 51, got %d", regA_out);
            or_test_failed = 1'b1;
        end

        step(); // OR A, 240
        $display("CHECK @ t=%0t: After OR A, 240 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd243) begin
            $error("FAIL: regA expected 243 (51 | 240), got %d", regA_out);
            or_test_failed = 1'b1;
        end

        step(); // MOV B, 165
        $display("CHECK @ t=%0t: After MOV B, 165 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd165) begin
            $error("FAIL: regB expected 165, got %d", regB_out);
            or_test_failed = 1'b1;
        end

        step(); // OR B, 90
        $display("CHECK @ t=%0t: After OR B, 90 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd255) begin
            $error("FAIL: regB expected 255 (165 | 90), got %d", regB_out);
            or_test_failed = 1'b1;
        end

        if (!or_test_failed) $display(">>>>> ALL OR TESTS PASSED! <<<<< ");
        else                  $display(">>>>> OR TEST FAILED! <<<<< ");

        // --- Test 6: NOT Instructions ---
        $display("\n----- STARTING TEST 6: All NOT Instructions -----");

        step(); // MOV A, 170
        $display("CHECK @ t=%0t: After MOV A, 170 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd170) begin
            $error("FAIL: regA expected 170, got %d", regA_out);
            not_test_failed = 1'b1;
        end

        step(); // NOT A, A
        $display("CHECK @ t=%0t: After NOT A, A -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd85) begin
            $error("FAIL: regA expected 85 (~170), got %d", regA_out);
            not_test_failed = 1'b1;
        end

        step(); // MOV B, 204
        $display("CHECK @ t=%0t: After MOV B, 204 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd204) begin
            $error("FAIL: regB expected 204, got %d", regB_out);
            not_test_failed = 1'b1;
        end

        step(); // NOT B, B
        $display("CHECK @ t=%0t: After NOT B, B -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd51) begin
            $error("FAIL: regB expected 51 (~204), got %d", regB_out);
            not_test_failed = 1'b1;
        end

        // Test NOT A, B
        step(); // MOV A, 255
        step(); // MOV B, 240
        step(); // NOT A, B
        $display("CHECK @ t=%0t: After NOT A, B -> regA = %d, regB = %d", $time, regA_out, regB_out);
        if (regA_out !== 8'd15) begin
            $error("FAIL: regA expected 15 (~240), got %d", regA_out);
            not_test_failed = 1'b1;
        end
        if (regB_out !== 8'd240) begin
            $error("FAIL: Source regB should not change. Expected 240, got %d", regB_out);
            not_test_failed = 1'b1;
        end

        // Test NOT B, A
        step(); // MOV A, 15
        step(); // MOV B, 255
        step(); // NOT B, A
        $display("CHECK @ t=%0t: After NOT B, A -> regB = %d, regA = %d", $time, regB_out, regA_out);
        if (regB_out !== 8'd240) begin
            $error("FAIL: regB expected 240 (~15), got %d", regB_out);
            not_test_failed = 1'b1;
        end
        if (regA_out !== 8'd15) begin
            $error("FAIL: Source regA should not change. Expected 15, got %d", regA_out);
            not_test_failed = 1'b1;
        end

        if (!not_test_failed) $display(">>>>> ALL NOT TESTS PASSED! <<<<< ");
        else                  $display(">>>>> NOT TEST FAILED! <<<<< ");

        // --- Test 7: XOR Instructions ---
        $display("\n----- STARTING TEST 7: All XOR Instructions -----");

        step(); // MOV A, 202
        step(); // MOV B, 174

        step(); // XOR A, B (1)
        $display("CHECK @ t=%0t: After first XOR A, B -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd100) begin
            $error("FAIL: regA expected 100 (202 ^ 174), got %d", regA_out);
            xor_test_failed = 1'b1;
        end

        step(); // XOR A, B (2)
        $display("CHECK @ t=%0t: After second XOR A, B -> regA = %d (should restore)", $time, regA_out);
        if (regA_out !== 8'd202) begin
            $error("FAIL: regA expected 202 (100 ^ 174), got %d", regA_out);
            xor_test_failed = 1'b1;
        end

        step(); // MOV A, 240
        step(); // MOV B, 170

        step(); // XOR B, A
        $display("CHECK @ t=%0t: After XOR B, A -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd90) begin
            $error("FAIL: regB expected 90 (170 ^ 240), got %d", regB_out);
            xor_test_failed = 1'b1;
        end

        step(); // MOV A, 60
        step(); // XOR A, 255
        $display("CHECK @ t=%0t: After XOR A, 255 -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd195) begin
            $error("FAIL: regA expected 195 (60 ^ 255), got %d", regA_out);
            xor_test_failed = 1'b1;
        end

        step(); // MOV B, 146
        step(); // XOR B, 102
        $display("CHECK @ t=%0t: After XOR B, 102 -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd244) begin
            $error("FAIL: regB expected 244 (146 ^ 102), got %d", regB_out);
            xor_test_failed = 1'b1;
        end

        if (!xor_test_failed) $display(">>>>> ALL XOR TESTS PASSED! <<<<< ");
        else                  $display(">>>>> XOR TEST FAILED! <<<<< ");

        // --- Test 8: SHL Instructions  ---
        $display("\n----- STARTING TEST 8: All SHL Instructions -----");

        step(); // MOV A, 5
        step(); // SHL A, A
        $display("CHECK @ t=%0t: After SHL A, A (A=5<<1) -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd10) begin
            $error("FAIL: regA expected 10, got %d", regA_out);
            shl_test_failed = 1'b1;
        end

        step(); // MOV B, 12
        step(); // SHL B, B
        $display("CHECK @ t=%0t: After SHL B, B (B=12<<1) -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd24) begin
            $error("FAIL: regB expected 24, got %d", regB_out);
            shl_test_failed = 1'b1;
        end

        step(); // MOV A, 99
        step(); // MOV B, 21
        step(); // SHL A, B
        $display("CHECK @ t=%0t: After SHL A, B (A=21<<1) -> regA = %d, regB = %d", $time, regA_out, regB_out);
        if (regA_out !== 8'd42) begin
            $error("FAIL: regA expected 42, got %d", regA_out);
            shl_test_failed = 1'b1;
        end
        if (regB_out !== 8'd21) begin
            $error("FAIL: Source regB should not change. Expected 21, got %d", regB_out);
            shl_test_failed = 1'b1;
        end

        step(); // MOV B, 88
        step(); // MOV A, 30
        step(); // SHL B, A
        $display("CHECK @ t=%0t: After SHL B, A (B=30<<1) -> regB = %d, regA = %d", $time, regB_out, regA_out);
        if (regB_out !== 8'd60) begin
            $error("FAIL: regB expected 60, got %d", regB_out);
            shl_test_failed = 1'b1;
        end
        if (regA_out !== 8'd30) begin
            $error("FAIL: Source regA should not change. Expected 30, got %d", regA_out);
            shl_test_failed = 1'b1;
        end

        step(); // MOV B, 0
        step(); // MOV A, 192
        step(); // SHL B, A
        $display("CHECK @ t=%0t: After SHL B, A (B=192<<1, overflow) -> regB = %d, regA = %d", $time, regB_out, regA_out);
        if (regB_out !== 8'd128) begin
            $error("FAIL: regB expected 128 (due to overflow), got %d", regB_out);
            shl_test_failed = 1'b1;
        end
        if (regA_out !== 8'd192) begin
            $error("FAIL: Source regA should not change. Expected 192, got %d", regA_out);
            shl_test_failed = 1'b1;
        end

        if (!shl_test_failed) $display(">>>>> ALL SHL TESTS PASSED! <<<<< ");
        else                  $display(">>>>> SHL TEST FAILED! <<<<< ");

        // --- Test 9: SHR Instructions ---
        $display("\n----- STARTING TEST 9: All SHR Instructions -----");

        step(); // MOV A, 10
        step(); // SHR A, A
        $display("CHECK @ t=%0t: After SHR A, A (A=10>>1) -> regA = %d", $time, regA_out);
        if (regA_out !== 8'd5) begin
            $error("FAIL: regA expected 5, got %d", regA_out);
            shr_test_failed = 1'b1;
        end

        step(); // MOV B, 24
        step(); // SHR B, B
        $display("CHECK @ t=%0t: After SHR B, B (B=24>>1) -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd12) begin
            $error("FAIL: regB expected 12, got %d", regB_out);
            shr_test_failed = 1'b1;
        end

        step(); // MOV A, 99
        step(); // MOV B, 42
        step(); // SHR A, B
        $display("CHECK @ t=%0t: After SHR A, B (A=42>>1) -> regA = %d, regB = %d", $time, regA_out, regB_out);
        if (regA_out !== 8'd21) begin
            $error("FAIL: regA expected 21, got %d", regA_out);
            shr_test_failed = 1'b1;
        end
        if (regB_out !== 8'd42) begin
            $error("FAIL: Source regB should not change. Expected 42, got %d", regB_out);
            shr_test_failed = 1'b1;
        end

        step(); // MOV B, 88
        step(); // MOV A, 60
        step(); // SHR B, A
        $display("CHECK @ t=%0t: After SHR B, A (B=60>>1) -> regB = %d, regA = %d", $time, regB_out, regA_out);
        if (regB_out !== 8'd30) begin
            $error("FAIL: regB expected 30, got %d", regB_out);
            shr_test_failed = 1'b1;
        end
        if (regA_out !== 8'd60) begin
            $error("FAIL: Source regA should not change. Expected 60, got %d", regA_out);
            shr_test_failed = 1'b1;
        end

        step(); // MOV B, 0
        step(); // MOV A, 13
        step(); // SHR B, A
        $display("CHECK @ t=%0t: After SHR B, A (B=13>>1, LSB discard) -> regB = %d, regA = %d", $time, regB_out, regA_out);
        if (regB_out !== 8'd6) begin
            $error("FAIL: regB expected 6 (LSB discarded), got %d", regB_out);
            shr_test_failed = 1'b1;
        end
        if (regA_out !== 8'd13) begin
            $error("FAIL: Source regA should not change. Expected 13, got %d", regA_out);
            shr_test_failed = 1'b1;
        end

        if (!shr_test_failed) $display(">>>>> ALL SHR TESTS PASSED! <<<<< ");
        else                  $display(">>>>> SHR TEST FAILED! <<<<< ");

        // --- Test 10: INC B Instruction ---
        $display("\n----- STARTING TEST 10: INC B Instruction -----");

        step(); // MOV B, 50
        step(); // INC B
        $display("CHECK @ t=%0t: After INC B (B=50+1) -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd51) begin
            $error("FAIL: regB expected 51, got %d", regB_out);
            inc_test_failed = 1'b1;
        end

        step(); // MOV B, 0
        step(); // INC B
        $display("CHECK @ t=%0t: After INC B (B=0+1) -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd1) begin
            $error("FAIL: regB expected 1, got %d", regB_out);
            inc_test_failed = 1'b1;
        end

        step(); // MOV B, 255
        step(); // INC B
        $display("CHECK @ t=%0t: After INC B (B=255+1, overflow) -> regB = %d", $time, regB_out);
        if (regB_out !== 8'd0) begin
            $error("FAIL: regB expected 0 (due to 8-bit rollover), got %d", regB_out);
            inc_test_failed = 1'b1;
        end

        if (!inc_test_failed) $display(">>>>> ALL INC TESTS PASSED! <<<<< ");
        else                  $display(">>>>> INC TEST FAILED! <<<<< ");

        // Fin
        step(); // por si queda alguna instrucción "de cierre"
        $finish;
    end

    // Generador de clock (periodo 2)
    always #1 clk = ~clk;

endmodule
