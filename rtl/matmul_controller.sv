`default_nettype none

module matmul_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,

    output logic [2:0] row_idx,
    output logic [2:0] k_idx,

    output logic       mac_en,
    output logic       mac_first,
    output logic       out_row_we,

    output logic       busy,
    output logic       done
);

    // Three states are sufficient for the initial controller.
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        DONE
    } state_t;

    state_t state, next_state;

    // State and counter registers.
    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            row_idx <= 3'd0;
            k_idx   <= 3'd0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (start) begin
                        row_idx <= 3'd0;
                        k_idx   <= 3'd0;
                    end
                end

                COMPUTE: begin
                    if (k_idx == 3'd7) begin
                        k_idx <= 3'd0;

                        if (row_idx == 3'd7) begin
                            // The final row is written on this edge.
                            // The state becomes DONE after the edge.
                            row_idx <= row_idx;
                        end else begin
                            row_idx <= row_idx + 3'd1;
                        end
                    end else begin
                        k_idx <= k_idx + 3'd1;
                    end
                end

                DONE: begin
                    // Counters hold their values.
                end

                default: begin
                    row_idx <= 3'd0;
                    k_idx   <= 3'd0;
                end
            endcase
        end
    end

    // Next-state logic.
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = COMPUTE;
            end

            COMPUTE: begin
                if ((row_idx == 3'd7) && (k_idx == 3'd7))
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Control outputs.
    always_comb begin
        mac_en     = 1'b0;
        mac_first  = 1'b0;
        out_row_we = 1'b0;
        busy       = 1'b0;
        done       = 1'b0;

        case (state)
            IDLE: begin
                // All outputs remain inactive.
            end

            COMPUTE: begin
                mac_en = 1'b1;
                busy   = 1'b1;

                // Overwrite the accumulator for the first product.
                mac_first = (k_idx == 3'd0);

                // Commit the completed row, including product 8.
                out_row_we = (k_idx == 3'd7);
            end

            DONE: begin
                done = 1'b1;
            end

            default: begin
                // Safe inactive outputs.
            end
        endcase
    end

endmodule

`default_nettype wire
