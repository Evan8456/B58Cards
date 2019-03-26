module store_card(
	input [9:0] address, // The address to store the card at
	input [3:0] value, // The card value
	input [1:0] suit, // The card suit
	input [9:0] next_card, // The memory address of the next card
	input clock, // Stores to memory on this clock tick
	input enable, // If the module should store
	input load, // If the module should load the address, value and suit
	output [31:0] card_data // The data at the current address of the module
	);

	reg [3:0] current_value; // The current value of the module
	reg [1:0] current_suit; // The current suit of the module
	reg [9:0] current_addr; // The current address of the module
	reg wren; // If the ram module should write

	wire next_addr_found; // If memory for the next card has been allocated
	wire [9:0] next_card_addr; // Allocates memory for a new card
	wire [31:0] card_info; // The information to be written to ram

	assign card_info = {1, 9'b0, suit, value, 6'b0, next_card_addr}; // Fill the remaining positions with 0's

	always @(posedge next_addr_found) begin
		wren <= 1;
	end

	always @(posedge enable) begin
		wren <= 0;
	end

	always @(posedge load) begin
		if(load && enable == 0) begin
			current_value <= value;
			current_suit <= suit;
			current_addr <= address;
			wren <= 0;
		end
	end

	allocate_memory alloc(
		.clock(clock),
		.enable(alloc_enable),
		.adr_found(next_addr_found),
		.address(next_card_addr)
	);

	ram1024x32 ram(
		.address(address),
		.clock(clock),
		.data(card_info),
		.wren(wren),
		.q(card_data)
	);
endmodule

module remove_card(
	input [9:0] address, // The address of the card to remove
	input load, // If the new address should be loaded
	input clock, // The clocked of the circuit
	output reg [9:0] last_card // The address of the last card
	);

    reg [9:0] ram_addr;
    reg [31:0] write_data, read_data, next_card;

    reg [9:0] current_addr;
 	reg wren;

 	reg [31:0] empty_card;
 	reg [2:0] current_state;

 	initial begin
 		empty_card = {1, 31'b0};
 	end

	localparam LOAD_ADDRESS = 3'd0, // First load the address
			   GET_NEXT_CARD_ADDR = 3'd1, // Get the address for the next card in the list
 			   GET_NEXT_CARD = 3'd2, // Get the data of the next card
 			   DELETE_NEXT_CARD = 3'd3, // Remove the data for the next card
 			   DISABLE_WREN = 3'd4, // Stop write enable
 			   SET_RAM_ADDR = 3'd5, // Set the address to the given one
 			   COPY_DATA = 3'd6; // Copy the next card's data to this one, effectively removing it

 	always @(posedge clock) begin
 		case (current_state)
 			LOAD_ADDRESS:   begin
 							    wren <= 0;
 							    if(load) begin
	 							    current_addr = address;
	 						  	    ram_addr = address;
	 						  	    current_state <= GET_NEXT_CARD_ADDR;
	 						    end
 						    end
 			GET_NEXT_CARD_ADDR: begin
 									ram_addr = read_data[9:0];
 									current_state <= GET_NEXT_CARD;
 								end
 			GET_NEXT_CARD: begin
 						       next_card = read_data;
 						       write_data <= empty_card;
 						       current_state = DELETE_NEXT_CARD;
 						   end
 			DELETE_NEXT_CARD: begin
 							      wren <= 1;
 							      current_state <= DISABLE_WREN;
 							  end
 			DISABLE_WREN: begin
 						      wren <= 0;
 						      current_state <= SET_RAM_ADDR;
 						  end
 			SET_RAM_ADDR: begin
 						      ram_addr = address;
 						      write_data = next_card;
 						      current_state <= COPY_DATA;
 						  end
 			COPY_DATA: begin
 					       wren <= 1;
 					   end
 			default: current_state <= LOAD_ADDRESS;
 		endcase
 	end

	ram1024x32 ram(
		.address(ram_addr),
		.clock(clock),
		.data(write_data),
		.wren(wren),
		.q(read_data)
	);
endmodule

// removes and outputs the nth card in a linked list of cards
module nth_card(
	input [9:0] card, // The address of the head of the linked list
	input load_cards, //If the next card should be removed
	input [5:0] n, // The nth card is outputted
	input clock,
	output reg[5:0] out_card //data for the chosen cards
	);
	
	reg [15:0] current_card;
	reg [15:0] next_card;
	reg remove_card;
	
	always@(posedge clock)begin
		if(load_cards) begin
			current_card[9:0] <= card;
			remove_card <= 0;
		end
		else if(next_card != 16'b0)
			current_card <= next_card;
		else
			out_card <= current_card[15:10];
			remove_card <= 1;
	end
	
	remove_card remover(
		.card(current_card[9:0]),
		.load_cards(remove_card),
		.clock(clock),
		.last_card()
	);
	
	ram1024x32 ram(
		.address(current_card),
		.clock(clock),
		.data({suit, value}),
		.wren(load_cards),
		.q(next_card)
	);
endmodule

