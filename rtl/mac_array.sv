`default_nettype none

module mac_array #(
    parameter integer LANES  = 8,
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  logic                         clk,
    input  logic                         en,
    input  logic                         first,

    input  logic signed [DATA_W-1:0]     a_in,

    // Lane 0 uses the lowest DATA_W bits.
    input  logic [LANES*DATA_W-1:0]       b_bus,

    // Current and next accumulator values for every lane.
    output logic [LANES*ACC_W-1:0]        acc_bus,
    output logic [LANES*ACC_W-1:0]        acc_next_bus
);

    genvar lane;

    generate
        for (lane = 0; lane < LANES; lane = lane + 1) begin : gen_mac

            logic signed [DATA_W-1:0] b_lane;
            logic signed [ACC_W-1:0]  acc_value_lane;
            logic signed [ACC_W-1:0]  acc_next_lane;

            // Extract this lane's signed B operand.
            assign b_lane =
                $signed(b_bus[lane*DATA_W +: DATA_W]);

            mac_lane #(
                .DATA_W(DATA_W),
                .ACC_W (ACC_W)
            ) u_mac_lane (
                .clk       (clk),
                .en        (en),
                .first     (first),
                .a_in      (a_in),
                .b_in      (b_lane),
                .acc_value (acc_value_lane),
                .acc_next  (acc_next_lane)
            );

            // Pack each result into the corresponding bus slice.
            assign acc_bus[lane*ACC_W +: ACC_W] =
                acc_value_lane;

            assign acc_next_bus[lane*ACC_W +: ACC_W] =
                acc_next_lane;

        end
    endgenerate

endmodule

`default_nettype wire
