`timescale 1fs/1fs

module tb_RAM_Controller;

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 15;
    parameter BANKS      = 16;
    parameter X = 8;
    parameter Y = 8;

    localparam CMD_WR_WIDTH = 2 + 4 + ADDR_WIDTH + 2 + DATA_WIDTH;
    localparam CMD_RD_WIDTH = 1 + 4 + ADDR_WIDTH + 2;

    reg clk;
    reg [CMD_WR_WIDTH-1:0] cmd_wr;
    reg [CMD_RD_WIDTH-1:0] cmd_rd;
    wire [DATA_WIDTH-1:0] data_out;

    RAM_Controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BANKS(BANKS),
        .X(X),
        .Y(Y)
    ) dut (
        .clk(clk),
        .cmd_wr(cmd_wr),
        .cmd_rd(cmd_rd),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 500 THz simulation clock
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller);

        cmd_wr = 0;
        cmd_rd = 0;

        $display("===== Starting RAM_Controller Test =====");

        // ---- Reset memory ----
        @(posedge clk);
        cmd_wr <= {2'b10, 4'd0, 15'd0, 2'b00, 16'd0};
        @(posedge clk);
        cmd_wr <= 0;

        // ---- Write operations ----
        @(posedge clk);
        cmd_wr <= {2'b01, 4'd0, 15'd10, 2'b01, 16'h000A};
        @(posedge clk);
        cmd_wr <= 0;

        @(posedge clk);
        cmd_wr <= {2'b01, 4'd1, 15'd20, 2'b01, 16'h0AA};
        @(posedge clk);
        cmd_wr <= 0;

        @(posedge clk);
        cmd_wr <= {2'b01, 4'd0, 15'd11, 2'b01, 16'h0AAA};
        @(posedge clk);
        cmd_wr <= 0;

        @(posedge clk);
        cmd_wr <= {2'b01, 4'd1, 15'd21, 2'b01, 16'hAAAA};
        @(posedge clk);
        cmd_wr <= 0;

        // ---- Read operations ----
        @(posedge clk);
        cmd_rd <= {1'b1, 4'd0, 15'd10, 2'b01};
        @(posedge clk);
        $display("Read bank0[10] = %0d (0x%0h)", data_out, data_out);
        cmd_rd <= 0;

        @(posedge clk);
        cmd_rd <= {1'b1, 4'd1, 15'd20, 2'b01};
        @(posedge clk);
        $display("Read bank1[20] = %0d (0x%0h)", data_out, data_out);
        cmd_rd <= 0;

        @(posedge clk);
        cmd_rd <= {1'b1, 4'd0, 15'd11, 2'b01};
        @(posedge clk);
        $display("Read bank0[11] = %0d (0x%0h)", data_out, data_out);
        cmd_rd <= 0;

        @(posedge clk);
        cmd_rd <= {1'b1, 4'd1, 15'd21, 2'b01};
        @(posedge clk);
        $display("Read bank1[21] = %0d (0x%0h)", data_out, data_out);
        cmd_rd <= 0;

        $display("===== RAM_Controller Test Complete =====");
        $finish;
    end

endmodule

