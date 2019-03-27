module warControl(
	input clock,
	input resetn,
	input go, // HIGH indicates that a process has finished (player choosing a card, a card drawing, etc)
	
	input [7:0] player_head, // head of the player's deck - starts empty
	input [7:0] com_head, // head of the com's deck - starts empty
	
	input [7:0] deck_head, // head of original deck - starts with 52 cards
	
	output reg plot
	);

    reg [4:0] current_state, next_state;
	
	wire [7:0] player_x_loc; // x location for drawing player card
	wire [7:0] player_y_loc; // y location for drawing player card
	wire [7:0] com_x_loc; // x location for drawing com card
	wire [7:0] com_y_loc; // y location for drawing com card
	assign player_x_loc = 8'd200;
	assign player_y_loc = 8'd500;
	assign com_x_loc = 8'200;
	assign com_y_loc = 8'd100;
	
	reg dealEn;
	reg drawEn;
	reg storeEn;
	reg [1:0] winner; // 0-no winner yet, 1-player wins, 2-com wins
	
	reg [4:0] player_count; // the number of cards in the player's deck
	reg [4:0] com_count; // the number of cards in the com's deck
	
	reg [15:0] player_card;
	reg [15:0] com_card;
	reg [7:0] card_head;
	reg [7:0] store_to_head;
	reg [15:0] card_to_store;
	reg [15:0] card_out;
	reg [7:0] x_loc; // x position to draw next card
	reg [7:0] y_loc; // y position to draw next card
    
	localparam  
				DEAL_TO_PLAYER		= 3'd0,
				DEAL_TO_COM			= 3'd1,
				PLAYER_WAIT			= 3'd2,
				PLAYER_PLAY			= 3'd3,
				PLAYER_DRAW			= 3'd4,
				COM_PLAY			= 3'd5,
				COM_DRAW			= 3'd6,
				CALCULATE			= 3'd7, // calculate who wins
				PLAYER_WINS			= 3'd8,
				COM_WINS			= 3'd9;
	
	// Next state logic
	always @(posedge clock) begin
		case(current_state)
				DEAL_TO_PLAYER: begin
					if(player_count == 4'd26)
						next_state = DEAL_TO_COM;
					else
						next_state = DEAL_TO_PLAYER;
				end
				DEAL_TO_COM: begin
					if(com_count == 4'd26)
						next_state = PLAYER_WAIT;
					else
						next_state = DEAL_TO_COM;
				end
				PLAYER_WAIT: 		next_state = go ? PLAYER_PLAY : PLAYER_WAIT;
				PLAYER_PLAY: 		next_state = PLAYER_DRAW;
				PLAYER_DRAW:		next_state = go ? COM_PLAY : PLAYER_DRAW;
				COM_PLAY: 			next_state = COM_DRAW;
				COM_DRAW:			next_state = go ? CALCULATE : COM_DRAW;
				CALCULATE: begin
					if(winner == 0):
						next_state = CALCULATE;
					else if(winner == 1):
						next_state = PLAYER_WINS;
					else
						next_state = COM_WINS;
				end
				PLAYER_WINS:		next_state = go ? DEAL : PLAYER_WINS;
				COM_WINS:		next_state = go ? DEAL : COM_WINS;
            default: next_state = DEAL;
		endcase
	end
	
	// Output Logic
	always @(*) begin
		dealEn = 0;
		drawEn = 0;
		storeEn = 0;
		winner = 0;
		case(current_state)
			DEAL_TO_PLAYER: begin
				dealEn <= 1;
				player_count <= player_count+1;
				// move card from deck to player
				card_head <= deck_head;
				store_to_head <= player_head;
				storeEn <= 1;
			end
			DEAL_TO_COM: begin
				dealEn <= 1;
				com_count <= com_count+1
				// move card from deck to com
				card_head <= deck_head;
				store_to_head <= com_head;
				storeEn <= 1;
			end
			PLAYER_PLAY: begin
				card_head <= player_head;
				x_loc <= player_x_loc;
				y_loc <= player_y_loc;
				drawEn <= 1;
				player_card <= card_out[15:0];
			end
			COM_PLAY: begin
				card_head <= com_head;
				x_loc <= com_x_loc;
				y_loc <= com_y_loc;
				drawEn <= 1;
				com_card <= card_out[15:0];
			end
			CALCULATE: begin
				// check winner
				if(player_card[3:0] < com_card[3:0])
					winner <= 2;
				else
					winner <= 1;
			end
			PLAYER_WINS: begin
				storeEn <= 1;
				store_to_head <= player_head;
				///////////////////////////////////////////////////// Store player and com cards to player
			end
			COM_WINS: begin
				storeEn <= 1;
				store_to_head <= com_head;
				///////////////////////////////////////////////////// Store player and com cards to com
			end
		endcase
	end
	
	// update current_state
	always@(posedge clock) begin
        if(!resetn)
			player_count <= 0;
			com_count <= 0;
            current_state <= DEAL_TO_PLAYER;
        else
            current_state <= next_state;
	end
	
	Deal dealer(
		.enable(dealEn),
		.card_head(card_head),
		.card_out(card_out)
	);
	
	StoreCard card_adder(
		.enable(storeEn),
		.head(store_to_head),
		.card_in(card_to_store)
	);
	
	DrawCard drawer(
		.enable(drawEn)
		.card_data(card_out[7:0]),
		.x_loc(x_loc),
		.y_loc(y_loc)
	);
endmodule
