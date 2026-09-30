`timescale 1ns / 1ps

module tb_RAM_Controller;

    localparam DATA_WIDTH = 16;
    localparam ADDR_WIDTH = 4;
    localparam BANKS      = 2;

    localparam CMD_WR_WIDTH = 2 + 4 + ADDR_WIDTH + 2 + DATA_WIDTH;
    localparam CMD_RD_WIDTH = 1 + 4 + ADDR_WIDTH + 2;

    reg clk;
    reg [CMD_WR_WIDTH-1:0] cmd_wr;
    reg [CMD_RD_WIDTH-1:0] cmd_rd;
    wire [DATA_WIDTH-1:0] data_out;

    // Instantiate DUT with default X,Y = 8,8
    RAM_Controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BANKS(BANKS),
        .X(8),
        .Y(8)
    ) DUT (
        .clk(clk),
        .cmd_wr(cmd_wr),
        .cmd_rd(cmd_rd),
        .data_out(data_out)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    reg [15:0] test_values [0:7];
    reg [15:0] fp4_values [0:3];
    reg [15:0] fp8_values [0:3];
    reg [15:0] fp16_values [0:3];
    integer i;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller);

        cmd_wr = 0;
        cmd_rd = 0;

        // Initialize integer/fixed-point test values
        test_values[0] = 16'h0001;
        test_values[1] = 16'h00F0;
        test_values[2] = 16'h0F00;
        test_values[3] = 16'h7FFF;
        test_values[4] = 16'h8000;
        test_values[5] = 16'hF000;
        test_values[6] = 16'h1234;
        test_values[7] = 16'hABCD;

        // Example FP4 (1 sign, 2 exp, 1 mant) stored in 16 bits (top bits used)
        // Format: [15] sign | [14:13] exp | [12] mant | rest 0
        fp4_values[0] = 16'b0_01_1_000000000000; // small positive number
        fp4_values[1] = 16'b0_10_0_000000000000; // ~2.0
        fp4_values[2] = 16'b1_10_0_000000000000; // -2.0
        fp4_values[3] = 16'b0_11_1_000000000000; // near max FP4 value

        // Example FP8 (1 sign, 4 exp, 3 mant) stored in 16 bits
        // Format: [15] sign | [14:11] exp | [10:8] mant
        fp8_values[0] = 16'b0_0111_000_00000000; // +1.0 approx
        fp8_values[1] = 16'b1_0111_000_00000000; // -1.0 approx
        fp8_values[2] = 16'b0_1000_000_00000000; // +2.0 approx
        fp8_values[3] = 16'b0_1001_000_00000000; // +4.0 approx

        // FP16 examples (IEEE 754 half precision)
        fp16_values[0] = 16'b0_0111110_00000000; // +0.5
        fp16_values[1] = 16'b0_0111111_00000000; // +1.0
        fp16_values[2] = 16'b1_0111111_00000000; // -1.0
        fp16_values[3] = 16'b0_1000000_00000000; // +2.0

        $display("===== Starting RAM_Controller Test (FP4, FP8, FP16) =====");

        // === Integer / Fixed-Point ===
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b01, test_values[i]};
            @(posedge clk);
            cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b01};
            @(posedge clk);
            $display("[INT/Q] Addr=%0d Write=%h Read=%h", i, test_values[i], data_out);
            cmd_rd <= 0;
        end

        // === FP4 ===
        $display("===== Testing FP4 Conversion =====");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp4_values[i]};
            @(posedge clk);
            cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            $display("[FP4] Addr=%0d Write=%b ReadBack=%b", i, fp4_values[i], data_out);
            cmd_rd <= 0;
        end

        // === FP8 ===
        $display("===== Testing FP8 Conversion =====");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp8_values[i]};
            @(posedge clk);
            cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            $display("[FP8] Addr=%0d Write=%b ReadBack=%b", i, fp8_values[i], data_out);
            cmd_rd <= 0;
        end

        // === FP16 ===
        $display("===== Testing FP16 Conversion =====");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp16_values[i]};
            @(posedge clk);
            cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            $display("[FP16] Addr=%0d Write=%b ReadBack=%b", i, fp16_values[i], data_out);
            cmd_rd <= 0;
        end

        $display("===== All Tests Completed Successfully =====");
        $finish;
    end

endmodule

