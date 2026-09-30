`timescale 1fs/1fs

module tb_RAM_Controller_CmdBus_XY_Dual;

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 15;
    parameter BANKS      = 16;

    reg                     clk;
    reg  [38:0] cmd_wr;
    reg  [22:0] cmd_rd;
    wire [DATA_WIDTH-1:0]   data_out;

    RAM_Controller_CmdBus_XY_Dual dut (
        .clk(clk),
        .cmd_wr(cmd_wr),
        .cmd_rd(cmd_rd),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    task wr_cmd;
        input [1:0] operation;
        input [3:0] bank_sel;
        input [ADDR_WIDTH-1:0] addr;
        input [1:0] data_type;
        input [15:0] data_in;
        begin
            cmd_wr = {operation, bank_sel, addr, data_type, data_in};
            @(posedge clk);
        end
    endtask

    task rd_cmd;
        input [3:0] bank_sel;
        input [ADDR_WIDTH-1:0] addr;
        input [1:0] format;
        begin
            cmd_rd = {2'b10, bank_sel, addr, format};
            @(posedge clk);
            $display("Read raw data_out from bank%0d[%0d] = %0d (0x%0h)", 
                     bank_sel, addr, data_out, data_out);
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller_CmdBus_XY_Dual);

        cmd_wr = 0;
        cmd_rd = 0;
        @(posedge clk);

        $display("Resetting memory...");
        wr_cmd(2'b00, 4'd0, 15'd0, 2'b00, 16'd0);

        $display("Writing integer 45 to bank0[10]...");
        wr_cmd(2'b01, 4'd0, 15'd10, 2'b01, 16'd45);

        $display("Writing integer 34 to bank1[20]...");
        wr_cmd(2'b01, 4'd1, 15'd20, 2'b01, 16'd34);

        $display("Writing fixed-point 45.432 (Q8.8 = 11629) to bank0[11]...");
        wr_cmd(2'b01, 4'd0, 15'd11, 2'b00, 16'd11629);

        $display("Writing fixed-point 34.122 (Q8.8 = 8720) to bank1[21]...");
        wr_cmd(2'b01, 4'd1, 15'd21, 2'b00, 16'd8720);

        $display("Reading bank0[10]...");
        rd_cmd(4'd0, 15'd10, 2'b00);

        $display("Reading bank1[20]...");
        rd_cmd(4'd1, 15'd20, 2'b00);

        $display("Reading bank0[11]...");
        rd_cmd(4'd0, 15'd11, 2'b00);

        $display("Reading bank1[21]...");
        rd_cmd(4'd1, 15'd21, 2'b00);

        $display("Reading bank0[10] as integer...");
        rd_cmd(4'd0, 15'd10, 2'b01);

        $display("Reading bank1[20] as integer...");
        rd_cmd(4'd1, 15'd20, 2'b01);

        $display("Reading bank0[11] as integer...");
        rd_cmd(4'd0, 15'd11, 2'b01);

        $display("Reading bank1[21] as integer...");
        rd_cmd(4'd1, 15'd21, 2'b01);

        $display("Clearing bank0[10]...");
        wr_cmd(2'b11, 4'd0, 15'd10, 2'b00, 16'd0);

        $display("Reading cleared bank0[10]...");
        rd_cmd(4'd0, 15'd10, 2'b01);

        $finish;
    end

endmodule

