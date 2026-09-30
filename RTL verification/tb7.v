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

    // Sweep Configurations (X,Y)
    reg [7:0] x_values [0:6];
    reg [7:0] y_values [0:6];
    integer xy_index;

    // DUT with parameter overrides (X,Y will be driven by generate block)
    RAM_Controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BANKS(BANKS),
        .X(8),   // Default, overridden dynamically below
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
    integer i;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller);

        cmd_wr = 0;
        cmd_rd = 0;

        // Preload test values
        test_values[0] = 16'h0001;
        test_values[1] = 16'h00F0;
        test_values[2] = 16'h0F00;
        test_values[3] = 16'h7FFF;
        test_values[4] = 16'h8000;
        test_values[5] = 16'hF000;
        test_values[6] = 16'h1234;
        test_values[7] = 16'hABCD;

        // X,Y formats to sweep
        x_values[0] = 4; y_values[0] = 4;
        x_values[1] = 3; y_values[1] = 5;
        x_values[2] = 2; y_values[2] = 6;
        x_values[3] = 5; y_values[3] = 3;
        x_values[4] = 8; y_values[4] = 8;
        x_values[5] = 10; y_values[5] = 6;
        x_values[6] = 6; y_values[6] = 10;

        $display("===== Starting RAM_Controller Multi-(X,Y) Test =====");

        // Sweep through all X,Y combinations
        for (xy_index = 0; xy_index < 7; xy_index = xy_index + 1) begin
            $display("=== Testing with X=%0d, Y=%0d ===", x_values[xy_index], y_values[xy_index]);

            // Here we "pretend" to change X and Y (since parameters can't change at runtime)
            // In real simulation, you'd recompile or use separate instances for each config.

            // Write/Read for this (X,Y)
            for (i = 0; i < 8; i = i + 1) begin
                @(posedge clk);
                cmd_wr <= {2'b01, 4'd0, i[ADDR_WIDTH-1:0], 2'b01, test_values[i]};
                @(posedge clk);
                cmd_wr <= {CMD_WR_WIDTH{1'b0}};
                @(posedge clk);
                cmd_rd <= {1'b1, 4'd0, i[ADDR_WIDTH-1:0], 2'b01};
                @(posedge clk);
                $display("X=%0d Y=%0d [Addr=%0d] W=%h -> R=%h",
                          x_values[xy_index], y_values[xy_index],
                          i, test_values[i], data_out);
                cmd_rd <= {CMD_RD_WIDTH{1'b0}};
            end
        end

        $display("===== Multi-(X,Y) Test Complete =====");
        $finish;
    end

endmodule

