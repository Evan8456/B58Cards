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
    assign ram_data = {1'b1, 31'b0}; // Allocate the block by putting 1 in the most significant bit

	reg [1:0] current_state;
	localparam DO_NOTHING	= 2'd0, // Wait for enable
				  FIND_ADDR		= 2'd1; // Find a free address 

	always @(posedge clock) begin
		case(current_state)
			DO_NOTHING:	current_state = enable ? FIND_ADDR : DO_NOTHING;
			FIND_ADDR:	current_state = addr_found ? DO_NOTHING : FIND_ADDR;
			default:		current_state = DO_NOTHING;
		endcase
	end

	always @(posedge clock) begin
		addr_found <= 0;
		ram_wren <= 0;

		case(current_state)
			FIND_ADDR:	begin
								if(ram_address != 0 && ram_q[31] == 0) begin
								  out_address <= ram_address;
								  addr_found <= 1;
								  ram_wren <= 1;
								end
								else begin
									ram_address <= ram_address + 10'd32;
								end
							end
		endcase
	end

endmodule

module set_address(enable, clock, address, finished_setting, ram_address, ram_clock, ram_data, ram_wren, ram_q);
    input enable; // Finds a new memory address
    input clock; // A clock to run
    input [9:0] address; // The address to set
	output reg finished_setting; // If the module is finished setting the address

    output reg [9:0] ram_address; // The input address of the ram module
    output ram_clock; // The input clock of the ram module
    output [31:0] ram_data; // The input data of the ram module
    output reg ram_wren; // The input write enable of the ram module
    input [31:0] ram_q; // The output data of the ram module

	assign ram_clock = clock;
	assign ram_data = {1'b1, 31'b0};

	reg [1:0] current_state;

	localparam DO_NOTHING	= 2'd0, // Wait for enable
			   LOAD_ADDRESS = 2'd1, // Load the address
			   ENABLE_WRITE = 2'd2, // Enable write
			   FINISH		= 2'd3; // Set finished setting to 1

	
	always @(posedge clock) begin
		case (current_state)
			DO_NOTHING: current_state = enable ? LOAD_ADDRESS : DO_NOTHING;
			LOAD_ADDRESS: current_state = ENABLE_WRITE;
			ENABLE_WRITE: current_state = FINISH;
			FINISH: current_state = DO_NOTHING;
			default: current_state = DO_NOTHING;
		endcase
	end
	
	always @(posedge clock) begin
		ram_wren = 0;
		finished_setting = 0;

		case (current_state)
			LOAD_ADDRESS: begin
				ram_address <= address;
			end
			ENABLE_WRITE: begin
				ram_wren <= 1;
			end
			FINISH: begin
				finished_setting <= 1;
			end
		endcase
	end
endmodule

module ram_controller(
    input enable, // The enable for the operation
    input clock, // The clocks for the modules
    input [1:0] select_op, // Selects an operation for loading
    input [9:0] arg1, // The first argument for a module
    input [9:0] arg2, // The second argument for a module
    output reg finished_op, // If the operation has been finished since the last time enable was run
    output reg [31:0] out1 // The operation output
    );

    reg [9:0] ram_address;
    reg ram_clock;
    reg [31:0] ram_data;
    reg ram_wren;
    wire ram_q;

    reg load_op, load_arg, start_module;
    reg [9:0] current_arg1, current_arg2;

    reg fsm_finished_op;

    reg [2:0] current_state;

    localparam  DO_NOTHING      = 3'd0, // Wait until enable is active
                LOAD_ARGS       = 3'd1, // Load the arguments
                LOAD_ARGS_WAIT  = 3'd2, // Wait another clock cycle
                LOAD_OP         = 3'd3, // Load the operation
                DO_OP           = 3'd4, // Do the operation
					 DONE_OP			  = 3'd5; // Done processing

    always @(posedge clock) begin
        case (current_state)
            DO_NOTHING:     current_state = enable ? LOAD_ARGS : DO_NOTHING;
            LOAD_ARGS:      current_state = LOAD_ARGS_WAIT;
            LOAD_ARGS_WAIT: current_state = LOAD_OP;
            LOAD_OP:        current_state = DO_OP;
            DO_OP:          current_state = fsm_finished_op ? DONE_OP : DO_OP;
				DONE_OP:			 current_state = DO_NOTHING;
        endcase
    end

    always @(posedge clock) begin
        case (current_state)
            DO_NOTHING:     begin
                                ram_wren <= 0;
                                load_op <= 0;
                                load_arg <= 0;
                                start_module <= 0;
                                fsm_finished_op <= 0;
                                finished_op <= 0;
                            end
            LOAD_ARGS:      begin
                                finished_op <= 0;
                                load_arg <= 1;
                            end
            LOAD_ARGS_WAIT: begin
                                load_arg <= 0;
                            end
            LOAD_OP:        begin
											case(select_op)
												2'd0: begin // add
														  ram_address = ac_ram_addr;
														  ram_clock = ac_ram_clock;
														  ram_data = ac_ram_data;
														  ram_wren = ac_ram_wren;

														  fsm_finished_op = ac_finished_adding;
														  out1 = ac_next_card;
													 end
												2'd1: begin // remove
														  ram_address = rnc_ram_addr;
														  ram_clock = rnc_ram_clock;
														  ram_data = rnc_ram_data;
														  ram_wren = rnc_ram_wren;

														  fsm_finished_op = rnc_finished_removing;
														  out1 = rnc_out_card;
													 end
												2'd2: begin // split
														  ram_address = sl_ram_addr;
														  ram_clock = sl_ram_clock;
														  ram_data = sl_ram_data;
														  ram_wren = sl_ram_wren;

														  fsm_finished_op = sl_finished_splitting;
														  out1 = sl_second_addr;
													 end
											2'd3: begin // Set
													ram_address = sa_ram_addr;
														  ram_clock = sa_ram_clock;
														  ram_data = sa_ram_data;
														  ram_wren = sa_ram_wren;

														  fsm_finished_op = sa_finished_setting;
												end
												default: begin
																ram_address = 0;
																ram_clock = clock;
																ram_data = 0;
																ram_wren = 0;

																fsm_finished_op = 1;
																finished_op = 1;
																out1 = 0;
														  end
										  endcase
                            end
            DO_OP:          begin
                                start_module <= 1;
                            end
				DONE_OP:			 begin
										  finished_op <= 1;
									 end
        endcase
    end

    // For loading arguments in the register
    always @(posedge load_arg) begin
        current_arg1 <= arg1;
        current_arg2 <= arg2;
    end

    // Load operation
    always @(posedge load_op) begin
        
    end

    always @(posedge start_module) begin
        ac_enable <= (select_op == 2'd0 && current_state != DO_NOTHING) ?  1 : 0;
        rnc_enable <= (select_op == 2'd1 && current_state != DO_NOTHING) ?  1 : 0;
        sl_enable <= (select_op == 2'd2 && current_state != DO_NOTHING) ?  1 : 0;
		  sa_enable <= (select_op == 2'd3 && current_state != DO_NOTHING) ?  1 : 0;
    end

    // The ram module
    ram1024x32 ram(
        .address(ram_address),
        .clock(ram_clock),
        .data(ram_data),
        .wren(ram_wren),
        .q(ram_q)
    );

    // Add card module inputs
    reg ac_enable;
    wire [5:0] ac_value;
    wire [9:0] ac_address;
    wire [9:0] ac_next_card;
    wire ac_finished_adding;

    assign ac_address = current_arg1;
    assign ac_value = current_arg2;

    // Add card module ram inputs
    wire [9:0] ac_ram_addr;
    wire ac_ram_clock;
    wire [31:0] ac_ram_data;
    wire ac_ram_wren;

    add_card ac(
      .enable(ac_enable),
      .clock(clock),
      .value(ac_value),
      .address(ac_address),
      .next_card(ac_next_card),
      .finished_adding(ac_finished_adding),
      .ram_address(ac_ram_addr),
      .ram_clock(ac_ram_clock),
      .ram_data(ac_ram_data),
      .ram_wren(ac_ram_wren),
      .ram_q(ram_q)
    );

    // Remove nth card module inputs
    reg rnc_enable;
    wire [9:0] rnc_card;
    wire [5:0] rnc_n;
    wire [5:0] rnc_out_card;
    wire rnc_finished_removing;

    assign rnc_card = current_arg1;
    assign rnc_n = current_arg2;

    // Remove nth card module ram inputs
    wire [9:0] rnc_ram_addr;
    wire rnc_ram_clock;
    wire [31:0] rnc_ram_data;
    wire rnc_ram_wren;

    remove_nth_card rnc(
      .enable(rnc_enable),
      .clock(clock),
      .card(rnc_card),
      .n(rnc_n),
      .out_card(rnc_out_card),
      .finished_removing(rnc_finished_removing),
      .ram_address(rnc_ram_addr),
      .ram_clock(rnc_ram_clock),
      .ram_data(rnc_ram_data),
      .ram_wren(rnc_ram_wren),
      .ram_q(ram_q)
    );

    // Split list module inputs
    reg sl_enable;
    wire [5:0] sl_n;
    wire [9:0] sl_address;
    wire [9:0] sl_second_addr;
    wire sl_finished_splitting;

    assign sl_n = current_arg1;
    assign sl_address = current_arg2;

    // Split list ram inputs
    wire [9:0] sl_ram_addr;
    wire sl_ram_clock;
    wire [31:0] sl_ram_data;
    wire sl_ram_wren;

    split_list sl(
      .enable(sl_enable),
      .clock(clock),
      .n(sl_n),
      .address(sl_address),
      .second_addr(sl_second_addr),
      .finished_splitting(sl_finished_splitting),
      .ram_address(sl_ram_addr),
      .ram_clock(sl_ram_clock),
      .ram_data(sl_ram_data),
      .ram_wren(sl_ram_wren),
      .ram_q(ram_q)
    );

	// Set address module inputs
    reg sa_enable;
    wire [9:0] sa_address;
    wire sa_finished_setting;

    assign sa_address = current_arg1;

    // Split list ram inputs
    wire [9:0] sa_ram_addr;
    wire sa_ram_clock;
    wire [31:0] sa_ram_data;
    wire sa_ram_wren;

    set_address sa(
      .enable(sa_enable),
      .clock(clock),
      .address(sa_address),
      .finished_setting(sa_finished_setting),
      .ram_address(sa_ram_addr),
      .ram_clock(sa_ram_clock),
      .ram_data(sa_ram_data),
      .ram_wren(sa_ram_wren),
      .ram_q(ram_q)
    );
endmodule