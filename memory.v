module allocate_memory(enable, clock, addr_found, out_address, ram_address, ram_clock, ram_data, ram_wren, ram_q);
    input enable; // Finds a new memory address
    input clock; // A clock to run
    output reg addr_found; // If the current address was free the last time enable was run
    output reg [9:0] out_address; // The first free memory address found

    output reg [9:0] ram_address; // The input address of the ram module
    output ram_clock; // The input clock of the ram module
    output [31:0] ram_data; // The input data of the ram module
    output reg ram_wren; // The input write enable of the ram module
    input [31:0] ram_q; // The output data of the ram module
 
    assign ram_clock = clock;
    assign ram_data = {1, 31'b0}; // Allocate the block by putting 1 in the most significant bit

    always @(posedge enable) begin
        addr_found <= 0;
    end

    always @(posedge clock) begin
        if(addr_found == 0) begin
          if(current_addr != 0 && ram_address[31] == 0) begin
              out_address <= ram_address;
              addr_found <= 1;
              ram_wren <= 1;
          end
          else begin
              ram_address <= ram_address + 32;
              ram_wren <= 0;
          end
        end
        else begin
            ram_wren <= 0;
        end
    end
endmodule

module ram_controller(load, address, clock, data, wren, q);
    input [9:0] address;
    input clock;
    input [31:0] data;
    input wren;
    output [31:0] q;

    reg [9:0] cur_address;
    reg [31:0] cur_data;
    reg cur_wren;
 
    always @(posedge load) begin
        cur_address <= address;
        cur_data <= data;
        cur_wren <= wren;
    end
 
    ram1024x32 ram(
        .address(address),
        .clock(clock),
        .data({1, 31'b0}),
        .wren(ram_write),
        .q(q)
    );
endmodule

module ram_logic_unit(
    input enable,
    input clock,
    input load_op,
    input select_op,
    input load_reg,
    input [$clog2(MAX_ARGS) - 1:0] select_reg;
    );

    parameter MAX_ARGS = 10;

    reg [7:0] arg_array [MAX_ARGS - 1:0]; // The arguments that will be passed to the operation

    reg current_op;

    wire [9:0] ram_address; // The address of the ram unit
    remove_nth_card rnc(
        .enable
        .clock,
        .card,
        .n,
        .out_card,
        .finished_removing,
        .ram_address,
        .ram_clock,
        .ram_data,
        .ram_wren,
        .ram_q
    );

    ram_controller rc(load, address, clock, data, wren, q);
endmodule

