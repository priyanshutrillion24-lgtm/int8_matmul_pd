`timescale 1ns/1ps

module tb_int8_matmul_accel;

    logic clk;
    logic rst;

    logic       wr_en;
    logic [6:0] wr_addr;
    logic [7:0] wr_data;

    logic start;
    logic busy;
    logic done;

    logic [5:0] rd_addr;
    logic signed [31:0] rd_data;

    logic signed [7:0] test_a [0:63];
    logic signed [7:0] test_b [0:63];
    integer expected_result [0:63];

    integer error_count;

// Device under test (DUT).
int8_matmul_accel dut (
    .clk     (clk),
    .rst     (rst),

    .wr_en   (wr_en),
    .wr_addr (wr_addr),
    .wr_data (wr_data),

    .start   (start),
    .busy    (busy),
    .done    (done),

    .rd_addr (rd_addr),
    .rd_data (rd_data)
);

    // 10 ns clock period.
    always #5 clk <= ~clk;

    // Convert a signed integer into an INT8 bit pattern.
    task automatic apply_reset;
        begin
            @(negedge clk);
            rst     = 1'b1;
            start   = 1'b0;
            wr_en   = 1'b0;
            wr_addr = 7'd0;
            wr_data = 8'd0;
            rd_addr = 6'd0;

            repeat (2) @(negedge clk);

            rst = 1'b0;
            @(negedge clk);

            if ((busy !== 1'b0) || (done !== 1'b0)) begin
                error_count = error_count + 1;
                $display("FAIL: reset did not return the controller to IDLE");
            end
        end
    endtask

    // Perform one input-byte write.
    task automatic write_byte(
        input logic [6:0] address,
        input logic [7:0] data_byte
    );
        begin
            @(negedge clk);
            wr_en   = 1'b1;
            wr_addr = address;
            wr_data = data_byte;

            // The DUT captures the byte at the intervening posedge.
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task automatic run_matrix_test(input integer pattern_id);
        integer idx;
        integer r;
        integer c;
        integer k;
        integer sum;
        integer av;
        integer bv;
        integer compute_cycles;
        integer wait_cycles;
        integer errors_before;

        logic [31:0] rng_state;

        begin
            errors_before = error_count;

            // -----------------------------------------------
            // 1. Generate input matrices.
            // -----------------------------------------------
            if (pattern_id == 0) begin
                // Directed boundary-value test.
                for (idx = 0; idx < 64; idx = idx + 1) begin
                    case (idx)
                        0: test_a[idx] = -128;
                        1: test_a[idx] =  127;
                        2: test_a[idx] =   -1;
                        3: test_a[idx] =    0;
                        4: test_a[idx] =    1;
                        default:
                            test_a[idx] =
                                8'(((idx * 37 + 11) % 256) - 128);
                    endcase

                    case (idx)
                        0: test_b[idx] =  127;
                        1: test_b[idx] = -128;
                        2: test_b[idx] =    1;
                        3: test_b[idx] =   -1;
                        4: test_b[idx] =    0;
                        default:
                            test_b[idx] =
                                8'(((idx * 19 + 7) % 256) - 128);
                    endcase
                end

            end else if (pattern_id == 1) begin
                // Reproducible pseudorandom INT8 values.
                // The fixed seed makes failures repeatable.
                rng_state = 32'h1ACE_B00C;

                for (idx = 0; idx < 64; idx = idx + 1) begin
                    rng_state =
                        rng_state * 32'd1664525 + 32'd1013904223;
                    test_a[idx] = $signed(rng_state[7:0]);
                end

                for (idx = 0; idx < 64; idx = idx + 1) begin
                    rng_state =
                        rng_state * 32'd1664525 + 32'd1013904223;
                    test_b[idx] = $signed(rng_state[7:0]);
                end

            end else begin
                // Zero-matrix test. This also checks that old
                // accumulator values are overwritten on first=1.
                for (idx = 0; idx < 64; idx = idx + 1) begin
                    test_a[idx] = 8'sd0;
                    test_b[idx] = 8'sd0;
                end
            end

            // -----------------------------------------------
            // 2. Compute an independent software reference.
            // -----------------------------------------------
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    sum = 0;

                    for (k = 0; k < 8; k = k + 1) begin
                        av = int'($signed(test_a[r*8 + k]));
bv = int'($signed(test_b[k*8 + c]));



                        sum = sum + (av * bv);
                    end

                    expected_result[r*8 + c] = sum;
                end
            end

            // -----------------------------------------------
            // 3. Load all 128 input bytes.
            // -----------------------------------------------
            for (idx = 0; idx < 64; idx = idx + 1)
                write_byte(7'(idx), test_a[idx]);

            for (idx = 0; idx < 64; idx = idx + 1)
                write_byte(7'(64 + idx), test_b[idx]);

            $display("");
            $display("Running matrix test %0d", pattern_id);

            // -----------------------------------------------
            // 4. Start the operation and count MAC cycles.
            // -----------------------------------------------
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            compute_cycles = 0;
            wait_cycles    = 0;

            // The timeout prevents a broken controller from
            // hanging the simulation indefinitely.
            while ((done !== 1'b1) && (wait_cycles < 80)) begin
                @(posedge clk);

                // Sample busy before the nonblocking state update.
                if (busy === 1'b1)
                    compute_cycles = compute_cycles + 1;

                #1;
                wait_cycles = wait_cycles + 1;
            end

            if (done !== 1'b1) begin
                error_count = error_count + 1;
                $display("FAIL: timeout waiting for done");
            end else begin
                if (compute_cycles != 64) begin
                    error_count = error_count + 1;
                    $display(
                        "FAIL: expected 64 MAC cycles, observed %0d",
                        compute_cycles
                    );
                end else begin
                    $display("PASS: observed exactly 64 MAC cycles");
                end

                if (busy !== 1'b0) begin
                    error_count = error_count + 1;
                    $display("FAIL: busy should be low when done is asserted");
                end

                // done should deassert one clock later.
                @(posedge clk);
                #1;

                if (done !== 1'b0) begin
                    error_count = error_count + 1;
                    $display("FAIL: done was not a one-cycle pulse");
                end

                // -------------------------------------------
                // 5. Compare all 64 DUT outputs.
                // -------------------------------------------
                for (idx = 0; idx < 64; idx = idx + 1) begin
                    @(negedge clk);
                    rd_addr = idx[5:0];
                    #1;

                    if (rd_data !== expected_result[idx]) begin
                        error_count = error_count + 1;

                        $display(
                            "FAIL: C[%0d][%0d], expected %0d, got %0d",
                            idx / 8,
                            idx % 8,
                            expected_result[idx],
                            $signed(rd_data)
                        );
                    end
                end
            end

            if (error_count == errors_before)
                $display("PASS: matrix test %0d", pattern_id);
            else
                $display("FAIL: matrix test %0d", pattern_id);
        end
    endtask

    initial begin
        $dumpfile("results/day5/tb_int8_matmul_accel.vcd");
        $dumpvars(0, tb_int8_matmul_accel);

        clk        = 1'b0;
        rst        = 1'b0;
        wr_en      = 1'b0;
        wr_addr    = 7'd0;
        wr_data    = 8'd0;
        start      = 1'b0;
        rd_addr    = 6'd0;
        error_count = 0;

        apply_reset();

        run_matrix_test(0);
        run_matrix_test(1);
        run_matrix_test(2);

        $display("");
        $display("======================================");

        if (error_count == 0) begin
            $display("ALL TESTS PASSED");
            $display("Matrices tested: 3");
            $display("Output elements checked: 192");
            $display("Expected MAC cycles per operation: 64");
            $display("======================================");
            $finish;
        end else begin
            $display("TOTAL FAILURES: %0d", error_count);
            $display("======================================");
            $fatal(1, "Functional verification failed");
        end
    end

endmodule
