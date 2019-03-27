module player(load, hand, current_hand);
	input load; // Load the hand on the positive edge of this
	input [9:0] hand; // The address to the head of the linked list containing the hand
	output [9:0] current_hand; // The address to the head of the linked list of the player's current hand

	reg [9:0] reg_hand;

	always @(posedge load) begin
		reg_hand = hand;
	end

	assign current_hand = reg_hand;
endmodule
