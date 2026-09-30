module RAM_Controller_CmdBus_XY_16bit #(
    parameter DATA_WIDTH = 16,   // Use 16-bit for Q8.8
    parameter ADDR_WIDTH = 15,
    parameter BANKS      = 16,
    parameter X = 8,  // Integer bits
    parameter Y = 8   // Fractional bits
)(
    input  wire clk,
    input  wire [40:0] cmd,       // Compact 41-bit command bus
    output reg [DATA_WIDTH-1:0] data_out
);
      initial begin
        data_out = 16'd0;
    end
    integer i, b;

    wire [1:0]  operation   = cmd[40:39];      // 00=reset,01=write,10=read,11=clear
    wire [3:0]  bank_sel    = cmd[38:35];    
    wire [ADDR_WIDTH-1:0] addr = cmd[34:20];  
    wire [1:0]  data_type   = cmd[19:18];     
    wire [1:0]  read_format = cmd[17:16];     
    wire [DATA_WIDTH-1:0] data_in = cmd[15:0]; 

    (* ram_style="block" *) reg [DATA_WIDTH-1:0] mem [0:BANKS-1][0:(1<<ADDR_WIDTH)-1];

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
                    mem[bank_sel][addr] <= data_in;  
            end
        endcase
    end

    always @(negedge clk) begin
        if (operation == 2'b10 && bank_sel < BANKS)
            data_out <= mem[bank_sel][addr]; 
    end

endmodule

