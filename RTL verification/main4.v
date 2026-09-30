module RAM_Controller #(
    parameter DATA_WIDTH = 16,   // Q8.8
    parameter ADDR_WIDTH = 15,
    parameter BANKS      = 16,
    parameter X = 8,
    parameter Y = 8
)(
    input  wire clk,              
    input  wire [38:0] cmd_wr,    // Write/Control command bus
    input  wire [22:0] cmd_rd,    // Read command bus
    output reg [DATA_WIDTH-1:0] data_out
);

    integer i, b;

    // --- Write/Control command decode (39-bit) ---
    wire [1:0]  op_wr       = cmd_wr[38:37]; 
    wire [3:0]  bank_wr     = cmd_wr[36:33];
    wire [ADDR_WIDTH-1:0] addr_wr = cmd_wr[32:18];
    wire [1:0]  dtype_wr    = cmd_wr[17:16];
    wire [DATA_WIDTH-1:0] din = cmd_wr[15:0];

    // --- Read command decode (23-bit) ---
    wire [1:0]  op_rd       = cmd_rd[22:21]; 
    wire [3:0]  bank_rd     = cmd_rd[20:17];
    wire [ADDR_WIDTH-1:0] addr_rd = cmd_rd[16:2];
    wire [1:0]  format_rd   = cmd_rd[1:0];

    // Memory banks
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] mem [0:BANKS-1][0:(1<<ADDR_WIDTH)-1];

    // Conversion functions
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

    // --- WRITE / CONTROL commands ---
    always @(negedge clk) begin
        case(op_wr)
            2'b00: begin // Reset all
                for (b=0; b<BANKS; b=b+1)
                    for (i=0; i<(1<<ADDR_WIDTH); i=i+1)
                        mem[b][i] <= 16'd0;
            end
            2'b11: begin // Clear
                if (bank_wr < BANKS)
                    mem[bank_wr][addr_wr] <= 16'd0;
            end
            2'b01: begin // Write
                if (bank_wr < BANKS)
                    mem[bank_wr][addr_wr] <= convert_input(din, dtype_wr);
            end
        endcase
    end

    // --- READ commands ---
    always @(negedge clk) begin
        if (op_rd == 2'b10 && bank_rd < BANKS)
            data_out <= convert_output(mem[bank_rd][addr_rd], format_rd);
    end

endmodule

