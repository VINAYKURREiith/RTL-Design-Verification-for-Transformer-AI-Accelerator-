module RAM_Controller_CmdBus_XY_16bit #(
    parameter DATA_WIDTH = 16,   // 16-bit for Q8.8
    parameter ADDR_WIDTH = 15,
    parameter BANKS      = 16,
    parameter X = 8,  // Integer bits
    parameter Y = 8   // Fractional bits
)(
    input  wire clk, // 2fs,500THz clk cycle
    input  wire [40:0] cmd,       // 41-bit command bus
    output reg [DATA_WIDTH-1:0] data_out
);
    initial data_out = 16'd0;
    integer i, b;

    wire [1:0]  operation   = cmd[40:39];  // 00 - reset,01-write,10-read,11-clear
    wire [3:0]  bank_sel    = cmd[38:35];    //4-bit memory location
    wire [ADDR_WIDTH-1:0] addr = cmd[34:20];  // 15 bit address
    wire [1:0]  data_type   = cmd[19:18];    // 00=fixed input, 01=integer input
    wire [1:0]  read_format = cmd[17:16];    
    wire [DATA_WIDTH-1:0] data_in = cmd[15:0]; // 16 bit input data

    (* ram_style="block" *) reg [DATA_WIDTH-1:0] mem [0:BANKS-1][0:(1<<ADDR_WIDTH)-1]; // assigning of 16 memory locations

    function [DATA_WIDTH-1:0] convert_input;
        input [DATA_WIDTH-1:0] value;
        input [1:0] type;
        begin
            case(type)
                2'b00: convert_input = value;         
                2'b01: convert_input = value << Y;    
                default: convert_input = value;
            endcase
        end
    endfunction
    function [DATA_WIDTH-1:0] convert_output;
        input [DATA_WIDTH-1:0] value;
        input [1:0] format;
        begin
            case(format)
                2'b00: convert_output = value;        
                2'b01: convert_output = value >> Y;  
                default: convert_output = value;
            endcase
        end
    endfunction

    always @(negedge clk) begin
        case(operation)
            2'b00: begin 
                for (b=0; b<BANKS; b=b+1)
                    for (i=0; i<(1<<ADDR_WIDTH); i=i+1)
                        mem[b][i] <= 16'd0;
            end
            2'b11: begin 
                if (bank_sel < BANKS)
                    mem[bank_sel][addr] <= 16'd0;
            end
            2'b01: begin
                if (bank_sel < BANKS)
                    mem[bank_sel][addr] <= convert_input(data_in, data_type);
            end
        endcase
    end

    always @(negedge clk) begin
        if (operation == 2'b10 && bank_sel < BANKS)
            data_out <= convert_output(mem[bank_sel][addr], read_format);
    end

endmodule

