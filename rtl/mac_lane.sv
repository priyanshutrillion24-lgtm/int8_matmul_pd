`default_nettype none

module mac_lane #(
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  logic                         clk,
    input  logic                         en,
    input  logic                         first,

    input  logic signed [DATA_W-1:0]     a_in,
    input  logic signed [DATA_W-1:0]     b_in,

    output logic signed [ACC_W-1:0]      acc_next
);

    // ACC_W must be >= 2*DATA_W.
    localparam integer PROD_W = 2 * DATA_W;

    // Internal accumulator register; no external read port needed.
    logic signed [ACC_W-1:0] acc_value;

    logic signed [PROD_W-1:0] a_ext;
    logic signed [PROD_W-1:0] b_ext;
    logic signed [PROD_W-1:0] product;

    logic signed [ACC_W-1:0] product_ext;

    // Sign-extend each operand before multiplication.
    // This ensures the complete signed product is preserved.
    always_comb begin
        a_ext = {{DATA_W{a_in[DATA_W-1]}}, a_in};
        b_ext = {{DATA_W{b_in[DATA_W-1]}}, b_in};

        product = a_ext * b_ext;

        // Extend the signed product to accumulator width.
        product_ext = {
            {(ACC_W-PROD_W){product[PROD_W-1]}},
            product
        };

        // Start a new dot product or accumulate the next term.
        if (first) begin
            acc_next = product_ext;
        end else begin
            acc_next = acc_value + product_ext;
        end
    end

    // The accumulator is overwritten at the first MAC step.
    // It does not require a reset value for correct operation,
    // provided first is asserted on the initial enabled step.
    always_ff @(posedge clk) begin
        if (en) begin
            acc_value <= acc_next;
        end
    end

endmodule

`default_nettype wire
