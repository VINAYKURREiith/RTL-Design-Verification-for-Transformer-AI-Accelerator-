`timescale 1ns/1ns

module tb_RAM_Controller_CmdBus_XY;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 15;
    parameter CMD_WIDTH  = 64;

    // DUT signals
    reg                     clk;
    reg  [CMD_WIDTH-1:0]    cmd;
    wire [DATA_WIDTH-1:0]   data_out;

    // Instantiate DUT
    RAM_Controller_CmdBus_XY dut (
        .clk(clk),
        .cmd(cmd),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;   // 100 MHz clock (10 ns period)
    end

    // Task: Send a command
    task send_cmd;
        input [1:0] operation;
        input [1:0] bank_sel;
        input [14:0] addr;
        input [1:0] data_type;
        input [1:0] read_format;
        input [31:0] data_in;
        input clear_flag;
        input reset_flag;
        begin
            cmd = {operation, bank_sel, addr, data_type, read_format,
                   data_in, clear_flag, reset_flag, 7'b0};
            @(posedge clk);
        end
    endtask

    // Stimulus
    initial begin
        $dumpfile("waveform.vcd");   // VCD file for GTKWave
        $dumpvars(0, tb_RAM_Controller_CmdBus_XY);

        cmd = 0;
        @(posedge clk);

        // Reset all memory
        $display("Resetting memory...");
        send_cmd(2'b00, 2'b00, 15'd0, 2'b00, 2'b00, 32'd0, 1'b0, 1'b1);

        // Write data 1234 to bank0[10]
        $display("Writing data 1234 to bank0[10]...");
        send_cmd(2'b01, 2'b00, 15'd10, 2'b00, 2'b00, 32'd1234, 1'b0, 1'b0);

        // Write data 5678 to bank1[20]
        $display("Writing data 5678 to bank1[20]...");
        send_cmd(2'b01, 2'b01, 15'd20, 2'b00, 2'b00, 32'd3456, 1'b0, 1'b0);

        // Read back from bank0[10]
        $display("Reading from bank0[10]...");
        send_cmd(2'b10, 2'b00, 15'd10, 2'b00, 2'b00, 32'd0, 1'b0, 1'b0);
        @(posedge clk);
        $display("Data_out = %d", data_out);

        // Read back from bank1[20]
        $display("Reading from bank1[20]...");
        send_cmd(2'b10, 2'b01, 15'd20, 2'b00, 2'b00, 32'd0, 1'b0, 1'b0);
        @(posedge clk);
        $display("Data_out = %d", data_out);

        // Clear location bank0[10]
        $display("Clearing bank0[10]...");
        send_cmd(2'b00, 2'b00, 15'd10, 2'b00, 2'b00, 32'd0, 1'b1, 1'b0);

        // Read cleared location
        $display("Reading cleared bank0[10]...");
        send_cmd(2'b10, 2'b00, 15'd10, 2'b00, 2'b00, 32'd0, 1'b0, 1'b0);
        @(posedge clk);
        $display("Data_out = %d", data_out);

        $finish;
    end

endmodule
