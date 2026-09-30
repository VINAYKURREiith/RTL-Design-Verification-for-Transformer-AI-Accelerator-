`timescale 1fs/1fs

module tb_RAM_Controller_CmdBus_XY_16bit;

    parameter DATA_WIDTH = 16;
    parameter ADDR_WIDTH = 15;
    parameter BANKS      = 16;
    parameter CMD_WIDTH  = 41;

    reg                     clk;
    reg  [CMD_WIDTH-1:0]    cmd;
    wire [DATA_WIDTH-1:0]   data_out;

    RAM_Controller_CmdBus_XY_16bit dut (
        .clk(clk),
        .cmd(cmd),
        .data_out(data_out)
    );

    // Clock generation: 2fs period → 500THz
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // Task to send command
    task send_cmd;
        input [1:0] operation;
        input [3:0] bank_sel;
        input [ADDR_WIDTH-1:0] addr;
        input [1:0] data_type;
        input [1:0] read_format;
        input [15:0] data_in;
        begin
            cmd = {operation, bank_sel, addr, data_type, read_format, data_in};
            @(posedge clk);
            if(operation == 2'b10) begin
                if(read_format == 2'b00)
                    $display("Read fixed-point from bank%0d[%0d] = %f", bank_sel, addr, data_out / 256.0);
                else
                    $display("Read integer from bank%0d[%0d] = %d", bank_sel, addr, data_out);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller_CmdBus_XY_16bit);

        cmd = 0;
        @(posedge clk);

        // Reset all memory
        $display("Resetting memory...");
        send_cmd(2'b00, 4'd0, 15'd0, 2'b00, 2'b00, 16'd0);

        // Write integer values (converted to fixed internally)
        $display("Writing integer 45 to bank0[10]...");
        send_cmd(2'b01, 4'd0, 15'd10, 2'b01, 2'b00, 16'd45);  // integer input, store as Q8.8

        $display("Writing integer 34 to bank1[20]...");
        send_cmd(2'b01, 4'd1, 15'd20, 2'b01, 2'b00, 16'd34);

        // Write fixed-point values directly
        $display("Writing fixed-point 45.432 (Q8.8 = 11629) to bank0[11]...");
        send_cmd(2'b01, 4'd0, 15'd11, 2'b00, 2'b00, 16'd11629); // fixed-point input

        $display("Writing fixed-point 34.122 (Q8.8 = 8720) to bank1[21]...");
        send_cmd(2'b01, 4'd1, 15'd21, 2'b00, 2'b00, 16'd8720);

        // Read values as fixed-point
        $display("Reading bank0[10] as fixed-point...");
        send_cmd(2'b10, 4'd0, 15'd10, 2'b01, 2'b00, 16'd0);

        $display("Reading bank1[20] as fixed-point...");
        send_cmd(2'b10, 4'd1, 15'd20, 2'b01, 2'b00, 16'd0);

        $display("Reading bank0[11] as fixed-point...");
        send_cmd(2'b10, 4'd0, 15'd11, 2'b00, 2'b00, 16'd0);

        $display("Reading bank1[21] as fixed-point...");
        send_cmd(2'b10, 4'd1, 15'd21, 2'b00, 2'b00, 16'd0);

        // Read values as integer
        $display("Reading bank0[10] as integer...");
        send_cmd(2'b10, 4'd0, 15'd10, 2'b01, 2'b01, 16'd0);

        $display("Reading bank1[20] as integer...");
        send_cmd(2'b10, 4'd1, 15'd20, 2'b01, 2'b01, 16'd0);

        $display("Reading bank0[11] as integer...");
        send_cmd(2'b10, 4'd0, 15'd11, 2'b00, 2'b01, 16'd0);

        $display("Reading bank1[21] as integer...");
        send_cmd(2'b10, 4'd1, 15'd21, 2'b00, 2'b01, 16'd0);

        // Clear bank0[10] and read
        $display("Clearing bank0[10]...");
        send_cmd(2'b11, 4'd0, 15'd10, 2'b01, 2'b00, 16'd0);
        $display("Reading cleared bank0[10] as integer...");
        send_cmd(2'b10, 4'd0, 15'd10, 2'b01, 2'b01, 16'd0);

        $finish;
    end

endmodule

