`default_nettype none

module int8_matmul_accel (
    input  logic                    clk,
    input  logic                    rst,

    // Input matrix write interface
    input  logic                    wr_en,
    input  logic [6:0]              wr_addr,
    input  logic [7:0]              wr_data,

    // Computation control
    input  logic                    start,
    output logic                    busy,
    output logic                    done,

    // Output matrix read interface
    input  logic [5:0]              rd_addr,
    output logic signed [31:0]      rd_data
);

    localparam integer DATA_W = 8;
    localparam integer ACC_W  = 32;
    localparam integer LANES  = 8;

    // Input and output matrix storage.
    // Arrays are intentionally not reset.
    logic signed [7:0]  a_mem [0:63];
    logic signed [7:0]  b_mem [0:63];
    logic signed [31:0] c_mem [0:63];

    // Controller outputs.
    logic [2:0] row_idx;
    logic [2:0] k_idx;

    logic mac_en;
    logic mac_first;
    logic out_row_we;

    // Datapath interconnects.
    logic signed [7:0] a_operand;
    logic [LANES*DATA_W-1:0] b_bus;

    logic [LANES*ACC_W-1:0] acc_next_bus;


    // Input writes:
    // 0..63   -> matrix A
    // 64..127 -> matrix B
    // Writes are ignored while busy or during reset.
    always_ff @(posedge clk) begin
        if (!rst && wr_en && !busy) begin
            if (wr_addr[6]) begin
                b_mem[wr_addr[5:0]] <= $signed(wr_data);
            end else begin
                a_mem[wr_addr[5:0]] <= $signed(wr_data);
            end
        end
    end

    // Select A[row_idx][k_idx] and B[k_idx][j].
    always_comb begin
        a_operand = a_mem[(row_idx * 8) + k_idx];

        for (int lane = 0; lane < LANES; lane++) begin
            b_bus[lane*DATA_W +: DATA_W] =
                b_mem[(k_idx * 8) + lane];
        end
    end

    // Controller.
    matmul_controller u_controller (
        .clk        (clk),
        .rst        (rst),
        .start      (start),

        .row_idx    (row_idx),
        .k_idx      (k_idx),

        .mac_en     (mac_en),
        .mac_first  (mac_first),
        .out_row_we (out_row_we),

        .busy       (busy),
        .done       (done)
    );

    // Eight parallel signed MAC lanes.
    // Gate enable during reset to abort an active computation.
    mac_array #(
        .LANES  (LANES),
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) u_mac_array (
        .clk          (clk),
        .en           (mac_en && !rst),
        .first        (mac_first),
        .a_in         (a_operand),
        .b_bus        (b_bus),
        .acc_next_bus (acc_next_bus)
    );

    // At k_idx == 7, capture acc_next_bus so that the eighth
    // product is included in each completed output element.
    always_ff @(posedge clk) begin
        if (!rst && out_row_we) begin
            for (int lane = 0; lane < LANES; lane++) begin
                c_mem[(row_idx * 8) + lane] <=
                    $signed(acc_next_bus[lane*ACC_W +: ACC_W]);
            end
        end
    end

    // Combinational output read.
    always_comb begin
        rd_data = c_mem[rd_addr];
    end

endmodule

`default_nettype wire
