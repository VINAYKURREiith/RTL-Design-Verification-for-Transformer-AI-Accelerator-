module RAM_Controller #(
    parameter DATA_WIDTH = 16, // to maintain 
    parameter ADDR_WIDTH = 15, // address width as per no.of blocks
    parameter BANKS      = 16, // max no. of memory location that supported this code is 16  
    parameter X = 8,
    parameter Y = 8
)(
    input  wire clk,
    input  wire [CMD_WR_WIDTH-1:0] cmd_wr,
    input  wire [CMD_RD_WIDTH-1:0] cmd_rd,
    output reg [DATA_WIDTH-1:0] data_out
);

    localparam CMD_WR_WIDTH = 2 + 4 + ADDR_WIDTH + 2 + DATA_WIDTH;
    localparam CMD_RD_WIDTH = 1 + 4 + ADDR_WIDTH + 2;

    integer i, b;

    wire [1:0] op_wr = cmd_wr[CMD_WR_WIDTH-1 : CMD_WR_WIDTH-2];
    wire [3:0] bank_wr = cmd_wr[CMD_WR_WIDTH-3 : CMD_WR_WIDTH-6]; // 4-bits represent the memory number
    wire [ADDR_WIDTH-1:0] addr_wr = cmd_wr[DATA_WIDTH+ADDR_WIDTH+1 : DATA_WIDTH+2]; // address location
    wire [1:0]dtype_wr = cmd_wr[DATA_WIDTH+1:DATA_WIDTH]; // datain 
    wire [DATA_WIDTH-1:0] din = cmd_wr[DATA_WIDTH-1:0]; // data in format

    wire op_rd = cmd_rd[CMD_RD_WIDTH-1];
    wire [3:0] bank_rd = cmd_rd[CMD_RD_WIDTH-2 : CMD_RD_WIDTH-5]; 
    wire [ADDR_WIDTH-1:0] addr_rd = cmd_rd[ADDR_WIDTH +1:2]; // required format
    wire [1:0]format_rd = cmd_rd[1:0];
    (* ram_style="block" *) reg [DATA_WIDTH+Y-1:0] mem [0:BANKS-1][0:(1<<ADDR_WIDTH)-1];
  initial begin
    data_out = {DATA_WIDTH{1'b0}};
end


    function [DATA_WIDTH+Y-1:0] convert_input;
    input [DATA_WIDTH-1:0] value;
    input [1:0] dtype;
    reg sign;
    reg [6:0] exp;
    reg [7:0] mant;
    reg [8:0] mant_full;
    integer unbiased_exp;
    integer shifted_value;
    integer scaled;
    begin
        case (dtype)
            2'b00: begin
                convert_input = {{Y{1'b0}}, value};
            end
            2'b01: begin
                convert_input = {value, {Y{1'b0}}};
            end
            2'b10: begin
                sign       = value[15];
                exp        = value[14:8];
                mant       = value[7:0];
                mant_full  = (exp == 0) ? {1'b0, mant} : {1'b1, mant};
                unbiased_exp = exp - 63;
                shifted_value = mant_full << (Y + unbiased_exp);
                shifted_value = shifted_value >> 8;
                if (sign)
                    scaled = -shifted_value;
                else
                    scaled = shifted_value;
                if (scaled > ((1 << (DATA_WIDTH+Y-1)) - 1))
                    scaled = ((1 << (DATA_WIDTH+Y-1)) - 1);
                else if (scaled < -(1 << (DATA_WIDTH+Y-1)))
                    scaled = -(1 << (DATA_WIDTH+Y-1));
                convert_input = scaled[DATA_WIDTH+Y-1:0];
            end
            default: begin
                convert_input = {{(DATA_WIDTH+Y){1'b0}}};
            end
        endcase
    end
endfunction

    function [DATA_WIDTH-1:0] convert_output;
    input signed [DATA_WIDTH+Y-1:0] value;
    input [1:0] format;
    reg sign;
    reg [DATA_WIDTH+Y-1:0] abs_value;
    integer exp_unbiased;
    integer leading_bit_pos;
    reg [7:0] mantissa;
    reg [6:0] exponent;
    integer i;
    begin
        case (format)
            2'b00: begin
                convert_output = value[DATA_WIDTH-1:0];
            end
            2'b01: begin
                convert_output = value >> Y;
            end
            2'b10: begin
                sign = value[DATA_WIDTH+Y-1];
                abs_value = (sign) ? -value : value;

                leading_bit_pos = -1;
                for (i = DATA_WIDTH+Y-1; i >= 0; i = i - 1)
                    if (abs_value[i] && leading_bit_pos < 0)
                        leading_bit_pos = i;

                if (leading_bit_pos >= 0) begin
                    exp_unbiased = leading_bit_pos - Y;
                    exponent = exp_unbiased + 63;
                    if (leading_bit_pos > 8)
                        mantissa = (abs_value >> (leading_bit_pos - 8)) & 8'hFF;
                    else
                        mantissa = (abs_value << (8 - leading_bit_pos)) & 8'hFF;
                    convert_output = {sign, exponent, mantissa};
                end else begin
                    convert_output = 16'b0;
                end
            end
            default: begin
                convert_output = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
endfunction


    always @(negedge clk) begin
        case(op_wr)
            2'b10: begin
                for (b=0; b<BANKS; b=b+1)
                    for (i=0; i<(1<<ADDR_WIDTH); i=i+1)
                        mem[b][i] <= 16'd0;
            end
            2'b11: begin
                if (bank_wr < BANKS)
                    mem[bank_wr][addr_wr] <= 16'd0;
            end
            2'b01: begin
                if (bank_wr < BANKS)
                    mem[bank_wr][addr_wr] <= convert_input(din, dtype_wr);
            end
        endcase
    end

    always @(negedge clk) begin
        if (op_rd == 1'b1 && bank_rd < BANKS)
            data_out <= convert_output(mem[bank_rd][addr_rd], format_rd);
    end

endmodule

