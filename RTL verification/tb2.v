`timescale 1ns/1ns

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
    // Clock generation: 2ns period
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

  
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
            if( operation == 2'b10)begin
             $display("Data_out = %f", data_out / 256.0);
            end
        end
    endtask

    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_RAM_Controller_CmdBus_XY_16bit);

        cmd = 0;
        @(posedge clk);

        
        $display("Resetting memory...");
        send_cmd(2'b00, 4'd0, 15'd0, 2'b00, 2'b00, 16'd0);

     
        $display("Writing 45.432 to bank0[10]...");
        send_cmd(2'b01, 4'd0, 15'd10, 2'b00, 2'b00, 16'd11629);

        $display("Writing 34.122 to bank1[20]...");
        send_cmd(2'b01, 4'd1, 15'd20, 2'b00, 2'b00, 16'd8720);
        
        $display("Reading from bank0[10]...");
        send_cmd(2'b10, 4'd0, 15'd10, 2'b00, 2'b00, 16'd0);
      
        $display("Reading from bank1[20]...");
        send_cmd(2'b10, 4'd1, 15'd20, 2'b00, 2'b00, 16'd0);
        
        $finish;
    end

endmodule

