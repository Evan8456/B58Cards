/*		 _______   _    _   _   _____        _   _____        _        _       __        _____     _
		|__   __| | |  | | | | |  ___|      | | |  ___|      | |      | |     /  \      |  _  \   | |
		   | |    | |__| | | | | |___       | | | |___       | |  __  | |    / /\ \     | |_|_/   | |
			| |	 |  __  | | | |____ |      | | |____ |      | | /  \ | |   / ____ \    |  _ \    |_|
			| |	 | |  | | | |  ___| |      | |  ___| |      | |/ /\ \| |  / /    \ \   | | \ \    _
			|_|    |_|  |_| |_| |_____|      |_| |_____|      |___/  \___| /_/      \_\  |_|  \_\  |_|
			
			                                      KAW!       ____
			      ____      /\                         \  __/ o  \
	  			  /    \     ||                _ _ _      /__     |        _ _ _
			  ___|    |___  ||                \\\\\\       |     |       //////
			  \__________/  ||                 \\\\\\     /       \     //////
				 | o  o |    ||                  \\\\\\   |         |   //////
				 |   -  |   / /                   \\\\\\  |  \/ \/  |  //////
				  \_  _/   / /                     \\\\\\ | \/ \/ \/| //////
				    ||____/ /                       \\\\\\|         |//////
					/  _____/                         ---------------------
				  //||                         
				  
*/
module cursor2
	(
	CLOCK_50,						//	On Board 50 MHz
	// Your inputs and outputs here
   KEY,
	SW,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,					//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B,   						//	VGA Blue[9:0]

   PS2_CLK,                   // PS2 Clock
   PS2_DAT                    // PS2 Data Lines
	);

	input	CLOCK_50;				//	50 MHz
	input [9:0] SW;
	input [3:0] KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
   inout PS2_CLK;
   inout PS2_DAT;

	output VGA_CLK;   			//	VGA Clock
	output VGA_HS;					//	VGA H_SYNC
	output VGA_VS;					//	VGA V_SYNC
	output VGA_BLANK_N;			//	VGA BLANK
	output VGA_SYNC_N;			//	VGA SYNC
	output [9:0]	VGA_R;   	//	VGA Red[9:0]
	output [9:0]	VGA_G;	 	//	VGA Green[9:0]
	output [9:0]	VGA_B;   	//	VGA Blue[9:0]

    wire resetn;
    assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(colour),
        .x(x),
        .y(y),
        .plot(writeEn),
        /* Signals for the DAC to drive the monitor. */
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK(VGA_BLANK_N),
        .VGA_SYNC(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";

    wire [7:0] received_data;   // PS/2 outputs
    wire received_data_en;

    PS2_Controller #(.INITIALIZE_MOUSE(1'b1)) PS2(
        .CLOCK_50(CLOCK_50),
        .reset(resetn),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),
        .received_data(received_data [7:0]),
        .received_data_en(received_data_en)
    );

    wire LdData;
    wire UpdateX;
    wire UpdateY;
    wire LdC;
    wire LdR;

	 
    control Control(
        .resetn(resetn),                    // Active low reset
        .clock(CLOCK_50),                   // Clock
        .received_data_en(received_data_en),// Mouse input to signal new data
        .LdData(LdData),                    // Datapath control signals
        .UpdateX(UpdateX),
        .UpdateY(UpdateY),
        .LdC(LdC),
        .LdR(LdR),
        .plot(writeEn)                      // VGA control signal
    );

    datapath Data(
        .resetn(resetn),                    // Active low reset
        .clock(CLOCK_50),                   // Clock
        .received_data(received_data[7:0]), // Mouse data
        .colour(SW[2:0]),                   // Colour data
        .LdData(received_data[7:0]),        // Control signals
        .UpdateX(UpdateX),
        .UpdateY(UpdateY),
        .LdC(LdC),
        .LdR(LdR),
        .X_out(x[7:0]),                     // VGA outputs
        .Y_out(y[6:0]),
        .C_out(colour[2:0])
    );
endmodule

module datapath(
    resetn, clock,
    received_data,
    colour,
    LdData, UpdateX, UpdateY, LdC, LdR,
    X_out, Y_out, C_out);

    input resetn;
    input clock;

    input [7:0] received_data;  // Mouse input data
    input [2:0] colour;         // Colour data
    input LdData;               // Signal to load mouse data into RegData
    input UpdateX, UpdateY;     // Signal to update X and Y based on mouse data
    input LdC;                  // Signal to load colour into RegC
    input LdR;		            // Signal to output to X_out, Y_out, C_out from RegX, RegY, and RegC

    output reg [7:0] X_out;
    output reg [6:0] Y_out;
    output reg [2:0] C_out;

    reg [7:0] RegData;
    reg [7:0] RegX, RegY;
    reg [2:0] RegC;

    always @ (posedge clock) begin
        if (!resetn) begin
            RegData <= 8'b0;
            RegX    <= 8'b0;
            RegY    <= 8'b0;
            RegC    <= 8'b0;
        end else begin
            if (LdData == 1'b1)
                RegData <= received_data[7:0];
            if (UpdateX == 1'b1)
                RegX    <= RegX + received_data;
            if (UpdateY == 1'b1)
                RegY    <= RegY + received_data;
            if (LdC == 1'b1)
                RegC    <= colour[2:0];
        end
    end

    // Output to out register
    always@(posedge clock) begin
        if(!resetn) begin
            X_out <= 8'b0;
            Y_out <= 8'b0;
            C_out <= 3'b0;
        end else if(LdR) begin
            X_out <= RegX;
            Y_out <= RegY;
            C_out <= RegC;
        end
    end
endmodule

module control(
    resetn, clock,
    received_data_en,
    LdData, UpdateX, UpdateY, LdC, LdR, plot);

    input resetn;
    input clock;

    input received_data_en;

    output reg LdData;
    output reg UpdateX, UpdateY, LdC;
    output reg LdR;
    output reg plot;

    reg [3:0] current_state, next_state;

    localparam NO_MOUSE     = 3'd0,
               MOUSE_IN1    = 3'd1,
               MOUSE_IN2    = 3'd2,
               MOUSE_IN3    = 3'd3,
               UPDATE_X     = 3'd4,
               UPDATE_Y     = 3'd5,
               LOAD_C       = 3'd6,
               DRAW         = 3'd7;

    always @(*)
        begin
            case (current_state)
                NO_MOUSE: next_state = received_data_en ? MOUSE_IN1 : NO_MOUSE; // Stay in NO_MOUSE until mouse movement
                MOUSE_IN1: next_state = MOUSE_IN2;
                MOUSE_IN2: next_state = MOUSE_IN3;
                MOUSE_IN3: next_state = UPDATE_X;
                UPDATE_X: next_state = UPDATE_Y;
                UPDATE_Y: next_state = LOAD_C;
                LOAD_C:   next_state = DRAW;
                DRAW:     next_state = NO_MOUSE;
                default:  next_state = NO_MOUSE;
            endcase
        end

    always @(*) begin
        LdData = 1'b0;
        UpdateX = 1'b0;
        UpdateY = 1'b0;
        LdC = 1'b0;
        LdR = 1'b0;
        plot = 1'b0;

        case (current_state)
            MOUSE_IN2: LdData = 1'b1;
            UPDATE_X: UpdateX = 1'b1;
            UPDATE_Y: UpdateY = 1'b1;
            LOAD_C:   LdC = 1'b1;
            DRAW: begin
                LdR = 1'b1;
                plot = 1'b1;
            end
        endcase
    end

    // current_state registers
    always @(posedge clock) begin
        if(!resetn)
            current_state <= NO_MOUSE;
        else
            current_state <= next_state;
    end
endmodule

module Counter(enable, clock, clear_b, Q);
    input enable;
    input clock;
    input clear_b;
    output [3:0] Q;

    TFlipFlop FF0(
        .t(enable),
        .q(Q[0]),
        .clock(clock),
        .resetN(clear_b)
    );

    TFlipFlop FF1(
        .t(Q[0] & enable),
        .q(Q[1]),
        .clock(clock),
        .resetN(clear_b)
    );

    TFlipFlop FF2(
        .t(Q[1] & Q[0] & enable),
        .q(Q[2]),
        .clock(clock),
        .resetN(clear_b)
    );

    TFlipFlop FF3(
        .t(Q[2] & Q[1] & Q[0] & enable),
        .q(Q[3]),
        .clock(clock),
        .resetN(clear_b)
    );
endmodule

module TFlipFlop(t, q, clock, resetN);
    input t;
    input clock;
    input resetN;
    output reg q;
    always @ (posedge clock, negedge resetN)
        begin
            if (resetN == 1'b0)
                q <= 0;
            else if (t == 1'b1)
                q <= 1'b1 - q;
        end
endmodule

module HexDecoder(IN, OUT);
    input [3:0] IN;
    output reg [6:0] OUT;

    always @(*) begin
        case (IN)
            4'h0: OUT = 7'b100_0000;
            4'h1: OUT = 7'b111_1001;
            4'h2: OUT = 7'b010_0100;
            4'h3: OUT = 7'b011_0000;
            4'h4: OUT = 7'b001_1001;
            4'h5: OUT = 7'b001_0010;
            4'h6: OUT = 7'b000_0010;
            4'h7: OUT = 7'b111_1000;
            4'h8: OUT = 7'b000_0000;
            4'h9: OUT = 7'b001_1000;
            4'hA: OUT = 7'b000_1000;
            4'hB: OUT = 7'b000_0011;
            4'hC: OUT = 7'b100_0110;
            4'hD: OUT = 7'b010_0001;
            4'hE: OUT = 7'b000_0110;
            4'hF: OUT = 7'b000_1110;
            default: OUT = 7'h7f;
        endcase
	end
endmodule