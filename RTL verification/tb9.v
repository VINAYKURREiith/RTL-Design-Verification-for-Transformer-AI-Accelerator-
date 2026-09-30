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

    // Instantiate DUT
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

    // Test vectors
    reg [15:0] fp4_values [0:3];
    reg [15:0] fp8_values [0:3];
    reg [15:0] fp16_values [0:3];
    integer i;
    integer int_out;
    reg [15:0] fp16_15_16;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller);

        cmd_wr = 0;
        cmd_rd = 0;

        // --- FP4 (1 sign, 2 exp, 1 mantissa) ---
        fp4_values[0] = 16'b0011000000000000; // ~1
        fp4_values[1] = 16'b0100000000000000; // ~2
        fp4_values[2] = 16'b1100000000000000; // ~-2
        fp4_values[3] = 16'b0111000000000000; // ~3

        // --- FP8 (1 sign, 4 exp, 3 mantissa) ---
        fp8_values[0] = 16'b0011100000000000; // ~1
        fp8_values[1] = 16'b1011100000000000; // ~-1
        fp8_values[2] = 16'b0100000000000000; // ~2
        fp8_values[3] = 16'b0100100000000000; // ~4

        // --- FP16 (half precision example) ---
        fp16_values[0] = 16'b0011111000000000; // ~0.5
        fp16_values[1] = 16'b0011111100000000; // ~1
        fp16_values[2] = 16'b1011111100000000; // ~-1
        fp16_values[3] = 16'b0100000000000000; // ~2

        $display("===== Starting FP to Integer Tests =====");

        // --- FP4 to Integer ---
        $display("=== FP4 to Integer ===");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp4_values[i]};
            @(posedge clk); cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            int_out = data_out >> 12; // take top 4 bits (sign+exp+mant) as integer
            $display("[FP4] Addr=%0d Input=%b -> Integer Output=%0d", i, fp4_values[i], int_out);
            cmd_rd <= 0;
        end

        // --- FP8 to Integer ---
        $display("=== FP8 to Integer ===");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp8_values[i]};
            @(posedge clk); cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            int_out = data_out >> 8; // take top 8 bits as integer part
            $display("[FP8] Addr=%0d Input=%b -> Integer Output=%0d", i, fp8_values[i], int_out);
            cmd_rd <= 0;
        end

        // --- FP16 to Integer ---
        $display("=== FP16 to Integer ===");
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b10, fp16_values[i]};
            @(posedge clk); cmd_wr <= 0;
            @(posedge clk);
            cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b10};
            @(posedge clk);
            int_out = data_out >> 8; // integer extraction for FP16
            $display("[FP16] Addr=%0d Input=%b -> Integer Output=%0d", i, fp16_values[i], int_out);
            cmd_rd <= 0;
        end

        // --- FP16 15.16 Input Test ---
        $display("=== FP16 -> Integer Test Case 15.16 ===");
        
        fp16_15_16 = 16'b0100111100101000; // example encoding
        @(posedge clk);
        cmd_wr <= {2'b01, 4'd0, 4'd0, 2'b10, fp16_15_16};
        @(posedge clk); cmd_wr <= 0;
        @(posedge clk);
        cmd_rd <= {1'b1, 4'd0, 4'd0, 2'b10};
        @(posedge clk);
        int_out = data_out >> 8;
        $display("FP16 Input ~15.16 = %b -> Integer Output: %0d", fp16_15_16, int_out);
        cmd_rd <= 0;

        $display("===== All FP to Integer Tests Completed =====");
        $finish;
    end

endmodule

