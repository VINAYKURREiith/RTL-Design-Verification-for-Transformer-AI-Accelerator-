`timescale 1fs/1fs

module tb_RAM_Controller;

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 15;
    parameter BANKS      = 16;
    parameter X = 8;
    parameter Y = 8;

    localparam CMD_WR_WIDTH = 2 + 4 + ADDR_WIDTH + 1 + DATA_WIDTH;
    localparam CMD_RD_WIDTH = 1 + 4 + ADDR_WIDTH + 1;

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

   
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 500 THz
    end

   
    task wr_cmd;
        input [1:0] operation;
        input [3:0] bank_sel;
        input [ADDR_WIDTH-1:0] addr;
        input dtype;
        input [DATA_WIDTH-1:0] data_in;
        begin
            cmd_wr = {operation, bank_sel, addr, dtype, data_in};
            @(posedge clk);
        end
    endtask

   
    task rd_cmd;
    	input op_rd;
        input [3:0] bank_sel;
        input [ADDR_WIDTH-1:0] addr;
        input format;
        begin
            cmd_rd = {op_rd, bank_sel, addr, format}; // op_rd = 1
            @(posedge clk);
            $display("Read from bank%0d[%0d] = %0d (0x%0h)", bank_sel, addr, data_out, data_out);
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller);

        cmd_wr = {CMD_WR_WIDTH{1'b0}};
        cmd_rd = {CMD_RD_WIDTH{1'b0}};
        @(negedge clk);
        
        $display("Resetting memory...");
        wr_cmd(2'b00, 4'd0, 15'd0, 1'b0, 16'd0);

        $display("Writing integer 45 to bank0[10]...");
        wr_cmd(2'b01, 4'd0, 15'd10, 1'b1, 16'h000A);

        $display("Writing integer 34 to bank1[20]...");
        wr_cmd(2'b01, 4'd1, 15'd20, 1'b1, 16'd34);

        $display("Writing fixed-point 45.432 (Q8.8 = 11629) to bank0[11]...");
        wr_cmd(2'b01, 4'd0, 15'd11, 1'b1, 16'hAAAA);

        $display("Writing fixed-point 34.122 (Q8.8 = 8720) to bank1[21]...");
        wr_cmd(2'b01, 4'd1, 15'd21, 1'b0, 16'd8720);

        $display("Reading bank0[10]...");
        rd_cmd(1'b1,4'd0, 15'd10, 1'b0);

        $display("Reading bank1[20]...");
        rd_cmd(1'b1, 4'd1, 15'd20, 1'b0);

        $display("Reading bank0[11]...");
        rd_cmd(1'b1, 4'd0, 15'd11, 1'b0);

        $display("Reading bank1[21]...");
        rd_cmd(1'b1, 4'd1, 15'd21, 1'b0);

        $display("Reading bank0[10] as integer...");
        rd_cmd(1'b1, 4'd0, 15'd10, 1'b1);

        $display("Reading bank1[20] as integer...");
        rd_cmd(1'b1, 4'd1, 15'd20, 1'b1);

        $display("Reading bank0[11] as integer...");
        rd_cmd(1'b1, 4'd0, 15'd11, 1'b1);

        $display("Reading bank1[21] as integer...");
        rd_cmd(1'b1, 4'd1, 15'd21, 1'b1);

        $display("Clearing bank0[10]...");
        wr_cmd(2'b11, 4'd0, 15'd10, 1'b0, 16'd0);

        $display("Reading cleared bank0[10]...");
        rd_cmd(1'b1, 4'd0, 15'd10, 1'b1);

        $finish;
    end

endmodule

