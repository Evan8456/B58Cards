module allocate_memory(clock, enable, addr_found, address, data);
    input clock; // A clock to run
    input enable; // Finds a new memory address
    output adr_found; // If the current address was free the last time enable was run
    output reg [9:0] address; // The first free memory address found

    reg addr_found;
    reg ram_write;
    reg [9:0] current_addr;
    wire [31:0] mem_info;

    assign adr_found = addr_found;

    always @(posedge enable) begin
        addr_found <= 0;
    end

    always @(posedge clock) begin
        if(addr_found == 0) begin
            if(current_addr != 0 && current_addr[31] == 0) begin
                address <= current_addr;
                addr_found <= 1;
                ram_write <= 1;
            end
            else begin
                current_addr <= current_addr + 32;
                ram_write = 0;
            end
        end
    end

    ram1024x32 ram(
		.address(address),
		.clock(clock),
		.data({1, 31'b0}),
		.wren(ram_write),
		.q(mem_info)
	);
endmodule