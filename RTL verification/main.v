module RAM_Controller_CmdBus_XY #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 15,
    parameter X = 2,
    parameter Y = 14
)(
    input  wire                     clk,
    input  wire [63:0]              cmd,    
    output reg  [DATA_WIDTH-1:0]    data_out
);
    initial begin
      data_out = 32'd0;
      end
      
    // Command fields
    wire [1:0]  operation   = cmd[63:62];    
    wire [1:0]  bank_sel    = cmd[61:60];
    wire [ADDR_WIDTH-1:0] addr = cmd[59:45];
    wire [1:0]  data_type   = cmd[44:43];    
    wire [1:0]  read_format = cmd[42:41];    
    wire [DATA_WIDTH-1:0] data_in = cmd[40:9];
    wire        clear_flag  = cmd[8];
    wire        reset_flag  = cmd[7];

    // Memory banks
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] memA [0:(1<<ADDR_WIDTH)-1];
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] memB [0:(1<<ADDR_WIDTH)-1];
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] memC [0:(1<<ADDR_WIDTH)-1];
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] memD [0:(1<<ADDR_WIDTH)-1];

    reg [DATA_WIDTH-1:0] mem_data_r;
    integer i;

    // Input conversion (data_in → memory format)
    function [DATA_WIDTH-1:0] convert_input;
        input [DATA_WIDTH-1:0] value;
        input [1:0] type;
        begin
            case (type)
                2'b00: convert_input = value << Y;  // Q(X,Y) scaling
                default: convert_input = value;
            endcase
        end
    endfunction

    // Output conversion (memory → data_out)
    function [DATA_WIDTH-1:0] convert_output;
        input [DATA_WIDTH-1:0] value;
        input [1:0] from_type;
        input [1:0] to_type;
        begin
            case (to_type)
                2'b00: convert_output = (from_type==2'b00) ? (value >>> Y) : value;
                default: convert_output = value;
            endcase
        end
    endfunction

    // Reset / Clear
    always @(posedge clk) begin
        if (reset_flag) begin
            
            for (i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
                memA[i] <= 0;
                memB[i] <= 0;
                memC[i] <= 0;
                memD[i] <= 0;
            end
        end else if (clear_flag) begin
            case (bank_sel)
                2'b00: memA[addr] <= 0;
                2'b01: memB[addr] <= 0;
                2'b10: memC[addr] <= 0;
                2'b11: memD[addr] <= 0;
            endcase
        end
    end

    // Write port
    always @(posedge clk) begin
        if (operation == 2'b01) begin
            case (bank_sel)
                2'b00: memA[addr] <= convert_input(data_in, data_type);
                2'b01: memB[addr] <= convert_input(data_in, data_type);
                2'b10: memC[addr] <= convert_input(data_in, data_type);
                2'b11: memD[addr] <= convert_input(data_in, data_type);
            endcase
        end
    end

   // Read + Output Conversion (same cycle)
always @(posedge clk) begin
    if (operation == 2'b10) begin
        case (bank_sel)
            2'b00: data_out <= convert_output(memA[addr], data_type, read_format);
            2'b01: data_out <= convert_output(memB[addr], data_type, read_format);
            2'b10: data_out <= convert_output(memC[addr], data_type, read_format);
            2'b11: data_out <= convert_output(memD[addr], data_type, read_format);
        endcase
    end
end


endmodule

