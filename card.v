module store_card(
    input enable, // If the module should store
    input clock, // Stores to memory on this clock tick
    input [9:0] address, // The address to store the card at
    input [5:0] value, // The number and suit of the card
    output reg [9:0] next_card, // The memory address of the next card
    output reg finished_storing, // If the module is finished storing a card after enable is triggered

    output reg [9:0] ram_address, // The input address of the ram module
    output reg ram_clock, // The input clock of the ram module
    output reg [31:0] ram_data, // The input data of the ram module
    output reg ram_wren, // The input write enable of the ram module
    input [31:0] ram_q // The output data of the ram module
    );

    reg [9:0] current_addr;
    reg [5:0] current_value;

    wire [9:0] alloc_address;
    wire alloc_clock;
    wire [31:0] alloc_data;
    wire alloc_wren;

    wire alloc_enable;
    wire next_addr_found; // If memory for the next card has been allocated
    wire [9:0] next_card_addr; // Allocates memory for a new card

    assign card_info = {1, 9'b0, current_value, 6'b0, next_card_addr}; // Fill the remaining positions with 0's

    reg [2:0] current_state;

    localparam DO_NOTHING = 3'd0, // Wait until enable is triggered
    		       LOAD = 3'd1, // Load the address, value and suit
               STORE_CARD = 3'd2, // Store the value and suit of the card
               STORE_CARD_WAIT = 3'd3, // Disable write enable
               ALLOC = 3'd4, // Allocate memory for the next card
               ALLOC_WAIT = 3'd5, // Disable write enable
               STORE_NEXT = 3'd6, // Store the memory address of the next card
               SET_DONE = 3'd7; // Sets the module to have been finished

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: current_state = enable ? LOAD : DO_NOTHING;
            LOAD: current_state = STORE_CARD;
            STORE_CARD: current_state = STORE_CARD_WAIT;
            STORE_CARD_WAIT: current_state = ALLOC;
            ALLOC: current_state = next_addr_found ? ALLOC_WAIT : ALLOC;
            ALLOC_WAIT: current_state = STORE_NEXT;
            STORE_NEXT: current_state = SET_DONE;
            SET_DONE: current_state = DO_NOTHING;
            default: current_state = DO_NOTHING;
        endcase
    end

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: begin
            				        finished_storing = 0;
                            ram_wren = 0;
                            alloc_enable = 0;
                        end
            LOAD:	begin
                      current_addr = address;
                      current_value = value;

                      ram_clock = clock;
                      ram_address = current_addr;
                      ram_data = card_info;
            		end
            STORE_CARD: begin
            				finished_storing = 0;
                            ram_wren <= 1;
                        end
            STORE_CARD_WAIT: begin
                                 ram_wren <= 0;
                             end
            ALLOC: begin
            	   		ram_address = alloc_address;
            	   		ram_clock = alloc_clock;
            	   		ram_data = alloc_data;
            	   		ram_wren = alloc_wren;
            	   		alloc_enable = 1;
            	   end
           	ALLOC_WAIT: begin
           					next_card = next_card_addr;
           					ram_wren = 0;
           					alloc_enable = 0;
           				end
            STORE_NEXT: begin
            				        ram_address = address;
                            ram_clock = clock;
                            ram_data = card_info;
                            ram_wren = 1;
            			      end
            SET_DONE: begin
                        finished_storing = 1;
                      end
        endcase
    end

    allocate_memory alloc(
        .enable(alloc_enable),
        .clock(clock),
        .addr_found(next_addr_found),
        .out_address(next_card_addr),
        .ram_address(alloc_address),
        .ram_clock(alloc_clock),
        .ram_data(alloc_data),
        .ram_wren(alloc_wren),
        .ram_q(ram_q)
    );
endmodule

// Adds the card to the linked list at the address given
module add_card(
    input enable,
    input clock,
    input [5:0] value,
    input [9:0] address, // The address of the head of the linked list
    output reg [9:0] next_card, // The memory address of the next card
    output reg finished_adding, // If the module has finished adding the card to the linked list

    output reg [9:0] ram_address, // The input address of the ram module
    output reg ram_clock, // The input clock of the ram module
    output reg [31:0] ram_data, // The input data of the ram module
    output reg ram_wren, // The input write enable of the ram module
    input [31:0] ram_q // The output data of the ram module
    );

    reg [5:0] current_value;
    reg [9:0] current_addr;

    reg store_enable;
    wire finished_storing;

    wire [9:0] store_address;
    wire store_clock;
    wire [31:0] store_data;
    wire store_wren;

    reg [2:0] current_state;

    localparam  DO_NOTHING = 3'd0, // Wait until enable is triggered
                LOAD = 3'd1, // Load the address and n
                FIND_LAST = 3'd2, // Find the address of the last card in the linked list
                STORE_CARD = 3'd3, // Remove the n'th card
                SET_DONE = 3'd4; // Set the module to have been done

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: current_state = enable ? LOAD : DO_NOTHING;
            LOAD: current_state = FIND_NTH;
            FIND_LAST: current_state = (ram[9:0] == 10'b0) ? REMOVE_CARD : FIND_LAST;
            STORE_CARD: current_state = finished_storing ? SET_DONE : STORE_CARD;
            SET_DONE: current_state = DO_NOTHING;
            default: current_state = DO_NOTHING;
        endcase
    end

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: begin
                            store_enable = 0;
                            count = 0;
                            ram_wren = 0;
                            finished_adding = 0;
                        end
            LOAD:   begin
                        finished_adding = 0;
                        current_addr = address;
                        current_value = value;
                        ram_address = current_addr;
                    end
            FIND_LAST:  begin
                            if(ram_q[9:0] != 10'b0) begin
                                current_addr = ram_q[9:0];
                                ram_address = current_addr;
                            end
                        end
            STORE_CARD: begin
                            ram_address = store_address;
                            ram_clock = store_clock;
                            ram_data = store_data;
                            ram_wren = store_wren;
                            store_enable = 1;
                        end
            SET_DONE: begin
                        finished_adding = 1;
                      end
        endcase
    end


    store_card sc(
        .enable(store_enable),
        .clock(clock),
        .address(current_addr),
        .value(current_value),
        .suit(suit),
        .next_card(next_card),
        .finished_storing(finished_storing),
        .ram_address(store_address),
        .ram_clock(store_clock),
        .ram_data(store_data),
        .ram_wren(store_wren),
        .ram_q(ram_q)
    );
endmodule

// Splits the list at the n'th value (all values from 0:n) exclusive in heads
module split_list(
    input enable,
    input clock,
    input [5:0] n,
    input [9:0] address, // The address of the head of the linked list
    output reg [9:0] second_addr, // The address to the card that was split at
    output reg finished_splitting, // If the module is finished splitting the hand

    output reg [9:0] ram_address, // The input address of the ram module
    output ram_clock, // The input clock of the ram module
    output reg [31:0] ram_data, // The input data of the ram module
    output reg ram_wren, // The input write enable of the ram module
    input [31:0] ram_q // The output data of the ram module
    );

    assign ram_clock = clock;
    assign ram_data = {ram_q[31:16], 16'b0};

    reg [9:0] current_addr;
    reg [5:0] current_n, count;

    reg [2:0] current_state;

    localparam  DO_NOTHING = 3'd0, // Wait until enable is triggered
                LOAD = 3'd1, // Load the address and n
                FIND_NTH = 3'd2, // Find the n'th card
                SPLIT_CARD = 3'd3, // Remove at the n'th card
                SET_DONE = 3'd4; // Set the module to have been done

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: current_state = enable ? LOAD : DO_NOTHING;
            LOAD: current_state = FIND_NTH;
            FIND_NTH: current_state = (count == current_n - 1) ? REMOVE_CARD : FIND_NTH;
            SPLIT_CARD: current_state = finished_splitting ? SET_DONE : REMOVE_CARD;
            SET_DONE: current_state = DO_NOTHING;
            default:  current_state = DO_NOTHING;
        endcase
    end

    always @(posedge clock) begin
        case(current_state)
            DO_NOTHING: begin
                            count = 0;
                            ram_wren = 0;
                            finished_splitting = 0;
                        end
            LOAD:   begin
                        finished_splitting = 0;
                        current_addr = address;
                        current_n = n;
                        ram_address = current_addr;
                    end
            FIND_NTH:   begin // Behaviour undefined if num_cards(linked list) < n
                            if(count != current_n - 1) begin
                                count = count + 1;
                                current_addr = ram_q[9:0];
                                ram_address = current_addr;
                            end
                        end
            SPLIT_CARD: begin
                            second_addr = ram_q[9:0];
                            ram_wren = 1;
                        end
            SET_DONE: begin
                        finished_splitting = 1;
                      end
        endcase
    end
endmodule

module remove_card(
	input enable, // If the card is to be removed
    input clock, // The clocked of the circuit
    input [9:0] address, // The address of the card to remove
    output reg [5:0] removed_card, // The suit and value of the last card
    output reg finished_removing, // If the module has finished removing a card since the last time enable was triggered

    output reg [9:0] ram_address, // The input address of the ram module
    output reg ram_clock, // The input clock of the ram module
    output reg [31:0] ram_data, // The input data of the ram module
    output reg ram_wren, // The input write enable of the ram module
    input [31:0] ram_q // The output data of the ram module
    );

    reg [9:0] current_addr, next_addr;
    reg [31:0] next_card, empty_card;

    initial begin
        empty_card = 32'b0;
    end

    reg [3:0] current_state;

    localparam 	DO_NOTHING = 4'd0, // Do nothing until enable is triggered
    		      	LOAD = 4'd1, // Load the address of the card to remove
                GET_NEXT_CARD_ADDR = 4'd2, // Get the address for the next card in the list
                GET_NEXT_CARD = 4'd3, // Get the data of the next card
                DELETE_NEXT_CARD = 4'd4, // Remove the data for the next card
                DISABLE_WREN = 4'd5, // Stop write enable
                SET_RAM_ADDR = 4'd6, // Set the address to the given one
                COPY_DATA = 4'd7, // Copy the next card's data to this one, effectively removing it
                SET_DONE = 4'd8; // Set the that module has finished

    always @(posedge clock) begin
        case (current_state)
        	DO_NOTHING: current_state = enable ? LOAD : DO_NOTHING;
        	LOAD: current_state = GET_NEXT_CARD_ADDR;
        	GET_NEXT_CARD_ADDR: current_state = GET_NEXT_CARD;
        	DELETE_NEXT_CARD: current_state = DISABLE_WREN;
        	DISABLE_WREN: current_state = SET_RAM_ADDR;
        	SET_RAM_ADDR: current_state = COPY_DATA;
        	COPY_DATA: current_state = SET_DONE;
          SET_DONE: current_state = DO_NOTHING;
        	default: current_state = DO_NOTHING;
        endcase
    end

    always @(posedge clock) begin
        case (current_state)
            DO_NOTHING:	begin
                          finished_removing = 0;
                          ram_wren = 0;
                        end
            LOAD:	begin
            			finished_removing = 0;
            			current_addr = address;
            			ram_clock = clock;
                        ram_address = current_address;
            		end
            GET_NEXT_CARD_ADDR: begin
            						removed_card = read_data[21:16];
                                    next_addr = ram_q[9:0];
                                    ram_address = next_addr;
                                end
            GET_NEXT_CARD: begin
                               next_card = ram_q;
                               ram_data = empty_card;
                               current_state = DELETE_NEXT_CARD;
                           end
            DELETE_NEXT_CARD: begin
                                  ram_wren = 1;
                                  current_state = DISABLE_WREN;
                              end
            DISABLE_WREN: begin
                              wren <= 0;
                              current_state = SET_RAM_ADDR;
                          end
            SET_RAM_ADDR: begin
                              ram_address = current_addr;
                              write_data = next_card;
                              current_state = COPY_DATA;
                          end
            COPY_DATA: begin
                           wren = 1;
                       end
            SET_DONE: begin
                        finished_removing = 1;
                      end
        endcase
    end
endmodule

// removes and outputs the nth card in a linked list of cards
module remove_nth_card(
  	input enable,
  	input clock,
    input [9:0] card, // The address of the head of the linked list
    input [5:0] n, // The nth card is outputted
    output reg [5:0] out_card, //data for the chosen cards
    output reg finished_removing,

    output reg [9:0] ram_address, // The input address of the ram module
    output reg ram_clock, // The input clock of the ram module
    output reg [31:0] ram_data, // The input data of the ram module
    output reg ram_wren, // The input write enable of the ram module
    input [31:0] ram_q // The output data of the ram module
    );

    reg [9:0] current_addr;
    reg [5:0] current_n, count;

    reg remove_enable;
    wire card_removed;

    wire [9:0] rem_address;
    wire rem_clock;
    wire [31:0] rem_data;
    wire rem_wren;

  	reg [2:0] current_state;

    localparam	DO_NOTHING = 3'd0, // Wait until enable is triggered
                LOAD = 3'd1, // Load the address and n
                FIND_NTH = 3'd2, // Find the n'th card
                REMOVE_CARD = 3'd3, // Remove the n'th card
                SET_DONE = 3'd4; // Set that the module is done

    always @(posedge clock) begin
    	case(current_state)
	    	DO_NOTHING: current_state = enable ? LOAD : DO_NOTHING;
	    	LOAD: current_state = FIND_NTH;
	    	FIND_NTH: current_state = (count == current_n) ? REMOVE_CARD : FIND_NTH;
	    	REMOVE_CARD: current_state = card_removed ? SET_DONE : REMOVE_CARD;
        SET_DONE: current_state = DO_NOTHING;
	    	default: current_state = DO_NOTHING;
    	endcase
    end

    always @(posedge clock) begin
    	case(current_state)
    		DO_NOTHING:	begin
    						remove_enable = 0;
    						count = 0;
    						ram_wren = 0;
    						finished_removing = 0;
    					end
	    	LOAD:	begin
	    				finished_removed = 0;
	    				current_addr = address;
	    				current_n = n;
	    				ram_address = current_addr;
	    			end
	    	FIND_NTH:	begin // Behaviour undefined if num_cards(linked list) < n
	    					if(count != current_n) begin
	    						count = count + 1;
	    						current_addr = ram_q[9:0];
	    						ram_address = current_addr;
	    					end
	    				end
	    	REMOVE_CARD:	begin
	    						ram_address = rem_address;
	    						ram_clock = rem_clock;
	    						ram_data = rem_data;
	    						ram_wren = rem_wren;
	    						remove_enable = 1;
	    					end
        SET_DONE: begin
                    finished_removing = 1;
                  end
	    endcase
	end


    remove_card remover(
    	.enable(remove_enable),
    	.clock(clock),
    	.address(current_addr),
    	.removed_card(out_card),
    	.finished_removing(card_removed),
      .ram_address(rem_address),
    	.ram_clock(rem_clock),
      .ram_data(rem_data),
      .ram_wren(rem_wren),
      .ram_q(ram_q)
    );
endmodule
