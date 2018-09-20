module rock_paper_scissor
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		SW,
		HEX0,
		HEX1,
		//HEX5
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

		input			CLOCK_50;				//	50 MHz
		// Declare your inputs and outputs here
		input          [3:0]KEY;
		input          [9:0]SW;
		output          [6:0]HEX0;
		output          [6:0]HEX1;
		//output          [6:0]HEX5;
	   // Declare your inputs and outputs here
		// Do not change the following outputs
		
		output	VGA_CLK;   				//	VGA Clock
		output	VGA_HS;					//	VGA H_SYNC
		output	VGA_VS;					//	VGA V_SYNC
		output	VGA_BLANK_N;				//	VGA BLANK
		output	VGA_SYNC_N;				//	VGA SYNC
		output	[9:0]	VGA_R;   				//	VGA Red[9:0]
		output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
		output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	
		wire load;
		wire resetn;
		wire [3:0] scorex;
		wire [3:0] scorey;
		
		wire [7:0] x;  //160
		wire [6:0] y; //120
		wire [7:0] xcoordinate;
		wire [6:0] ycoordinate;
	
		assign load = ~KEY[0];
		assign  resetn = KEY[3];
		
		  
	
	   wire [1:0] winner;
		wire [1:0] ply1;
		wire [1:0] ply2;
		wire load_input;
		wire count;
		wire compare ,drawbefore_enable_left, drawbefore_enable_right,writeEn;
		wire drawbefore_done_left, drawdone_done_right;
		wire drawafter_enable;
		wire clear_enable;
		wire clear_done;
		wire drawafter_done;
		wire [1:0] drawmux;
		assign ply1 = SW [1:0];
		assign ply2 = SW [9:8];
		
		 //assign ply1 = SW[1:0];
	   //	assign ply2 = SW[9:8];
	
			// always@(*)
				// begin
					//if (load == 0)
					//ply1 = SW [1:0];
					//ply2 = SW [9:8];
				// end
				
	      
		  
	
			// Create the colour, x, y and writeEn wires that are inputs to the controller.
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
						.VGA_CLK(VGA_CLK));
					defparam VGA.RESOLUTION = "160x120";
					defparam VGA.MONOCHROME = "FALSE";
					defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
					defparam VGA.BACKGROUND_IMAGE = "Untitled.mif";
	     // Put your code here. Your code should produce signals x,y,colour and writeEn
	    // for the VGA controller, in addition to any other functionality your design may require.
			control u1(
			   .winner (winner),
				.clk(CLOCK_50),
				.resetn(resetn),
				.go(load),
				.drawbefore_done_left (drawbefore_done_left),
				.drawbefore_done_right (drawbefore_done_right),
				.clear_done(clear_done),
				.drawafter_done (drawafter_done),
				.writeEn(writeEn),
				.load_input(load_input),
				.compare_(compare),
				.count_(count),
				.drawbefore_enable_left(drawbefore_enable_left),
				.drawbefore_enable_right(drawbefore_enable_right),
				.clear_enable(clear_enable),
				.drawafter_enable(drawafter_enable)
				);
			datapath u2(
				.clk(CLOCK_50),
				.resetn(resetn),
				.ply1(ply1),
				.ply2(ply2),
				.load_input(load_input),
				.compare_enable(compare),
				.count_enable(count),
				.drawbefore_enable_left(drawbefore_enable_left),
				.drawbefore_enable_right(drawbefore_enable_right),
				.clear_enable(clear_enable),
				.drawafter_enable(drawafter_enable),
				.winner(winner),
				.scorex(scorex),
				.scorey(scorey),
				.drawbefore_done_left (drawbefore_done_left),
				.drawbefore_done_right (drawbefore_done_right),
				.drawafter_done (drawafter_done),
				.clear_done(clear_done),
				.X(xcoordinate),
				.Y(ycoordinate),
				.drawmux(drawmux)
				);
			colourmux u3 (
			   .drawmux(drawmux),
			   .x(xcoordinate),
				.y(ycoordinate),
				.colour(colour),
				.X(x),
				.Y(y)
			   );
			hexdecoder h0(
				.in(scorex),
				.hex(HEX0[6:0])
				);
			hexdecoder h1(
				.in(scorey),
				.hex(HEX1[6:0])
				);
				 
		  	  
endmodule 

module datapath (
        input clk,
        input resetn,
		  input [1:0] ply1,
		  input [1:0] ply2,
		  input load_input,
		  input compare_enable,
		  input count_enable,
		  input drawbefore_enable_left,
		  input drawbefore_enable_right,
		  input clear_enable,
		  input drawafter_enable,
		  output reg [1:0] winner,
		  output [3:0] scorex,
		  output [3:0] scorey,
		  output drawbefore_done_left,
		  output drawbefore_done_right,
		  output drawafter_done,
		  output clear_done,
		  output reg [7:0] X,
		  output reg [6:0] Y,
		  output [1:0] drawmux
		  );
		  
		  reg [3:0]ply1s =4'b0000;
		  reg [3:0]ply2s =4'b0000;
		  
		  reg [1:0]ply1_reg = 2'b00;
		  reg [1:0]ply2_reg = 2'b00; 
		  
		  wire [7:0]xincrement_before_left ;
		  wire [6:0]yincrement_before_left ;
		  wire [7:0]xincrement_before_right;
		  wire [6:0]yincrement_before_right;
		  wire [7:0]xincrement_clear;
		  wire [6:0]yincrement_clear;
		  wire [7:0]xincrement_after;
		  wire [6:0]yincrement_after;
		  
		  wire drawbeforedone_left;
		  wire drawbeforedone_right;
		  
		  wire drawafterdone ;
		  wire  cleardone ;
		  
		  reg [1:0] drawmux_ = 2'b11;
		  
		
		  
		  
		  
		     always@ (posedge clk) begin 
		   
					if (!resetn) begin 
						ply1s <= 4'b0000;
						ply2s <= 4'b0000;
						winner <= 2'b10;
				      end 
					else if (load_input) begin 
							ply1_reg <= ply1[1:0];
							ply2_reg <= ply2[1:0];
						  end 
					else if (compare_enable) begin 
						if (ply1_reg == 2'b00) begin 
							if (ply2_reg == 2'b00) winner<= 2'b11;
						   else if (ply2_reg == 2'b01) winner<= 2'b01; // player 2
							else if (ply2_reg == 2'b10) winner <= 2'b00; 
							end 
						else if (ply1_reg == 2'b01) begin 
							if (ply2_reg == 2'b00) winner<= 2'b00;
							else if (ply2_reg == 2'b01) winner<= 2'b11;
							else if (ply2_reg == 2'b10) winner<= 2'b01;
							end 
						else if (ply1_reg == 2'b10) begin 
							if (ply2_reg == 2'b10) winner<= 2'b11;
							else if (ply2_reg == 2'b00) winner<= 2'b01;
							else if ( ply2_reg == 2'b01) winner<= 2'b00;
							end
					end 
					else if (count_enable) begin
				      if (winner == 2'b01) begin
					    	ply2s <= ply2s + 1;
							winner <= 2'b10;
							end 
					   else if ( winner == 2'b00) begin 
					    	ply1s <= ply1s + 1;
							winner <= 2'b10;
							end 
						else winner <= 2'b10;
					
				   end
						
				end
			
			//change the coodinates of one area (drawbefore_left
			  quarticsquareCounter q0 (
			                   .resetn(resetn),
			                   .enable(drawbefore_enable_left),
									 .clk(clk),
									 .done(drawbeforedone_left), 
									 .xincrement(xincrement_before_left),
									 .yincrement(yincrement_before_left));  
			
			
			//change the coordinates for drawbefore-right 
			  quarticsquareCounter q1 (
			                   .resetn(resetn),
			                   .enable(drawbefore_enable_right),
									 .clk(clk),
									 .done(drawbeforedone_right), 
									 .xincrement(xincrement_before_right),
									 .yincrement(yincrement_before_right));  
			  
			
			/*always @(*) begin
				if (!resetn) begin
					drawbeforedone_right <=1'b0;
				end
				else if (drawbefore_enable_right) begin 
					if (xincrement >= 79) begin
						xincrement <= 7'b0;
						yincrement <= yincrement +1;
					end
					else if (yincrement >= 59 & xincrement >= 79) begin 
						xincrement <= 7'b0;
					   yincrement <= 6'b0;
						drawbeforedone_right <= 1'b1; // someplaces need it to set to zero
					end 
					else 
						xincrement <= xincrement + 1'b1;
					end
				
				
			end */
			// change the coordinates to draw the clear 
			  halfsquareCounter q2 (
			                   .resetn(resetn),
			                   .enable(clear_enable),
									 .clk(clk),
									 .done(cleardone), 
									 .xincrement(xincrement_clear),
									 .yincrement(yincrement_clear));  
			/*always @(*) begin
				if (!resetn) begin
					cleardone <=1'b0;
				end
				else if (clear_enable) begin 
					if (xincrement >=159 ) begin
						xincrement <= 7'b0;
						yincrement <= yincrement +1;
					end
					else if (yincrement >= 59 & xincrement >= 159) begin 
						xincrement <= 7'b0;
					   yincrement <= 6'b0;
						cleardone <= 1'b1; // someplaces need it to set to zero
					end 
					else 
						xincrement <= xincrement + 1'b1;
				 end
			
			end */
			
			 // change the coordiantes to draw the drawafter (who's winner )
			 quarticsquareCounter q3(
			                   .resetn(resetn),
			                   .enable(drawafter_enable),
									 .clk(clk),
									 .done(drawafterdone), 
									 .xincrement(xincrement_after),
									 .yincrement(yincrement_after));  
			 
		   /* always @(*) begin
				if (!resetn) begin
					drawafterdone <=1'b0;
				end
				else if (drawafter_enable) begin 
					if (xincrement >=79 ) begin
						xincrement <= 7'b0;
						yincrement <= yincrement +1;
					end
					else if (yincrement >= 59 & xincrement >= 79) begin 
						xincrement <= 7'b0;
					   yincrement <= 6'b0;
						drawafterdone <= 1'b1; // someplaces need it to set to zero
					end 
					else 
						xincrement <= xincrement + 1'b1;
					end
				
				
				
			end*/
			
			
			always @(*) begin 
				if (drawbefore_enable_left) begin
					X = xincrement_before_left;
					Y = 7'd60 + yincrement_before_left; 
				end 
				else if (drawbefore_enable_right) begin 
					X = xincrement_before_right +8'd80;
					Y = 7'd60 + yincrement_before_right; 
				end 
				else if (clear_enable) begin 
					X = xincrement_clear;
					Y = 7'd60 + yincrement_clear;
				end 
				else if (drawafter_enable) begin
					if (winner == 2'b00) begin 
						 X = xincrement_after;
					    Y = 7'd60 + yincrement_after;	
			          end 
					else if (winner == 1'b01) begin 
					    X = xincrement_after +8'd80;
					    Y = 7'd60 + yincrement_after; 
				       end 
				   else begin 
					    X = xincrement_after;
					    Y = 7'd60 + yincrement_after;
				       end 	
			    	
					
				end 
			end 
			
			//decide which colour need to print at different stages
			always@(*) begin 
				if (drawbefore_enable_left) begin 
					drawmux_ <= ply1_reg;
				   end
				else if (drawbefore_enable_right) begin 
					drawmux_ <= ply2_reg;
				   end 
			/*	else if (compare_enable) begin 
				   drawbeforedone_left = 1'b0;
					drawbeforedone_right = 1'b0;
				   end */
				else if (clear_enable) begin 
					drawmux_<= 2'b11; 
			   	end 
				else if (drawafter_enable)begin 
				    if (winner == 2'b00) drawmux_ <= ply1_reg;
					 else if (winner == 2'b01) drawmux_ <= ply2_reg;
					 else if (winner == 2'b11 | winner == 2'b10) drawmux_<= 2'b11;
			       end
			end 
  		      assign scorex = ply1s;
				assign scorey = ply2s;
				assign drawbefore_done_left =drawbeforedone_left;
				assign drawbefore_done_right = drawbeforedone_right;
				assign drawafter_done = drawafterdone;
				assign clear_done = cleardone;
				assign drawmux = drawmux_;
				 
endmodule 
				
			
	

module quarticsquareCounter (resetn,enable,clk,done,xincrement,yincrement);
	input resetn;
	input enable;
	input clk;
	output  done;
	output reg [7:0] xincrement;
	output reg [6:0] yincrement;
	
	reg done_ = 1'b0;


	always @(posedge clk) begin
	        // done <= 1'b0;
				if (!resetn) begin
				//done<=1'b0;
				end
				else if (enable & (~done))begin 
					if (xincrement >=8'd79 ) begin
						xincrement <= 8'd0;
						yincrement <= yincrement +7'd1;
					end
					else if (yincrement >= 7'd59 & xincrement >= 8'd79) begin 
						xincrement <= 8'd0;
					   yincrement <= 7'd0;
					end
					
					else 
						xincrement <= xincrement + 8'd1;
				 end
				else if (done) begin 
				     xincrement <= 8'd0;
					  yincrement <= 7'd0;
				end 
			
			end 
	always @(*) begin
		if (!resetn) begin
			done_ <= 1'b0;
		end
		else begin
			done_ <= ((yincrement == 7'd59)&(xincrement== 8'd79 ));
		end
	end
	assign done = done_;
 
endmodule 




module halfsquareCounter (resetn,enable,clk,done,xincrement,yincrement);
	input resetn;
	input enable;
	input clk;
	output  done;
	output reg [7:0] xincrement;
	output reg [6:0] yincrement;
	
	reg done_ = 1'b0;


	always @(posedge clk) begin
	        // done <= 1'b0;
				if (!resetn) begin
				//done<=1'b0;
				end
				else if (enable & (~done))begin 
					if (xincrement >=8'd159 ) begin
						xincrement <= 8'd0;
						yincrement <= yincrement +7'd1;  
					end
					else if (yincrement >= 7'd59 & xincrement >= 8'd159) begin 
						xincrement <= 8'd0;
					   yincrement <= 7'd0;
					end
					
					else 
						xincrement <= xincrement + 8'd1;
				 end
				else if (done) begin 
				     xincrement <= 8'd0;
					  yincrement <= 7'd0;
				end 
			
			end 
	always @(*) begin
		if (!resetn) begin
			done_ <= 1'b0;
		end
		else begin
			done_ <= ((yincrement == 7'd59)&(xincrement== 8'd159));
		end
	end
	assign done = done_;
 



endmodule 



	
// drawmux 00 rock 
// drawmux 01  
// ply 10 scissor 
// ply 11 black 			  
module colourmux (drawmux,x,y,colour,X,Y);
	input [1:0]drawmux;
	input [7:0]x;
	input [6:0]y;
	output reg [2:0]colour;
	output [7:0]X;
	output [6:0]Y;
	
		always @(*) begin 
			if (drawmux == 2'b00) begin 
			// rock left 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51
	      if ( (y ==7'd61) & ( ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43)) )colour <= 3'b111; 
			
			else if ( (y == 7'd62 )& ( ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46)) )colour <= 3'b111;
			else if ( (y == 7'd63)& ( ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49)) )colour <= 3'b111;
			else if ( (y == 7'd64)& ( ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49)) )colour <= 3'b111;
			else if ( (y == 7'd65)& ( ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)) )colour <= 3'b111;
			else if ( (y == 7'd66)& ( ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)) )colour <= 3'b111;
			else if ( (y == 7'd67)& ( ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)) )colour <= 3'b111;
			else if ( (y == 7'd68)& ( ( x == 8'd24 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd50)) )colour <= 3'b111;	
			else if ( (y == 7'd69)& ( ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd50)) )colour <= 3'b111;

			else if ( (y == 7'd70)& ( ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd50)	))colour <= 3'b111;	
				
			else if ( (y == 7'd71)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)))colour <= 3'b111;
			
			else if ( (y == 7'd72)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)	))colour <= 3'b111;	
				
			else if ( (y == 7'd73)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)))colour <= 3'b111;
			
			else if ( (y == 7'd74)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)	))colour <= 3'b111;	
				
			else if ( (y == 7'd75)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)))colour <= 3'b111;
			
			else if ( (y == 7'd76)& ( ( x == 8'd26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51)	))colour <= 3'b111;	
				
			else if ( (y == 7'd77)& ( ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)))colour <= 3'b111;
			
			else if ( (y == 7'd78)& ( ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)	))colour <= 3'b111;	
				
			else if ( (y == 7'd79)& ( ( x == 8'd26 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50)))colour <= 3'b111;
			
			else if ( (y == 7'd80)& ( ( x == 8'd26 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )	))colour <= 3'b111;	
				
			else if ( (y == 7'd81)& ( ( x == 8'd23 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )))colour <= 3'b111;
			
			else if ( (y == 7'd82)& ( ( x == 8'd24)))colour <= 3'b111;	
				
			else if ( (y == 7'd83)& ( ( x == 8'd25 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd43 )))colour <= 3'b111;
			
			else if ( (y == 7'd84)& ( ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )	))colour <= 3'b111;	
				
			else if ( (y == 7'd85)& ( ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )))colour <= 3'b111;
			
			else if ( (y == 7'd86)& ( ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd42 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )	))colour <= 3'b111;	
				
			else if ( (y == 7'd87)& ( ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 ))
				)colour <= 3'b111;
			
			else if ( (y == 7'd88)& ( ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47  )	)
				)colour <= 3'b111;	
				
			else if ( (y == 7'd89)& ( ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd46 )| ( x == 8'd47 ))
				)colour <= 3'b111;
				
			else if ( (y == 7'd91)& ( ( x == 8'd43 )| ( x == 8'd44))
				)colour <= 3'b111;	
			
			
			
			
			
			
			// rock right 106 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131	+ 80
				
			else if ( (y == 7'd61)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd1106 )| ( x == 8'd1103)))
				colour <= 3'b111; 
			
			else if ( (y == 7'd62)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd63)&(  ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129)) )
				colour <= 3'b111;
				
			else if ( (y == 7'd64)&(  ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129)) )	
				colour <= 3'b111;
				
			else if ( (y == 7'd65)&(  ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130) ))	
				colour <= 3'b111;
			
			else if ( (y == 7'd66)&(  ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130) ))	
				colour <= 3'b111;
			
			else if ( (y == 7'd67)&(  ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130)) )	
				colour <= 3'b111;
			
			else if ( (y == 7'd68)&(  ( x == 8'd104 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd130)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd69)&(  ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd130)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd70)&(  ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd130)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd71)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd72)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd73)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd74)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd75)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd76)&(  ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd77)&(  ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd78)&(  ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd79)&(  ( x == 8'd102 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd80)&(  ( x == 8'd102 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd81)&(  ( x == 8'd103 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd82)&(  ( x == 8'd104)))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd83)&(  ( x == 8'd105 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd123)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd84)&(  ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd85)&(  ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd86)&(  ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd122 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd87)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128)))
				colour <= 3'b111;
			
			else if ( (y == 7'd88)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd89)&(  ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd126 )| ( x == 8'd127)) )
				colour <= 3'b111;
				
			else if ( (y == 7'd91)&(  ( x == 8'd103 )| ( x == 8'd104))	
				)colour <= 3'b111;	
				
			else colour<= 3'b000;
			end
							
			
							
							
							
		   else if (drawmux == 2'b01) begin 
			// paper left 26 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51 )| ( x == 8'd52 )| ( x == 8'd53
				
			if ( (y == 7'd112)&(  ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )))
				colour <= 3'b111; 
			
			else if ( (y == 7'd111)&(  ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd31)| ( x == 8'd32)| ( x == 8'd33)| ( x == 8'd34)| ( x == 8'd35)))	
				colour <= 3'b111;
			
			else if ( (y == 7'd110)&(  ( x == 8'd21 )| ( x == 8'd22 )| ( x == 8'd23)| ( x == 8'd24)| ( x == 8'd25)| ( x == 8'd35)| ( x == 8'd36)| ( x == 8'd37)))	
				colour <= 3'b111;
			
			else if ( (y == 7'd109)&(  ( x == 8'd21 )| ( x == 8'd22 )| ( x == 8'd37)| ( x == 8'd38)))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd108)&(  ( x == 8'd19 )| ( x == 8'd20 )| ( x == 8'd21)| ( x == 8'd38)| ( x == 8'd39)))
				colour <= 3'b111;
			
			else if ( (y == 7'd107)&(  ( x == 8'd17 )| ( x == 8'd18 )| ( x == 8'd19)| ( x == 8'd39)| ( x == 8'd40)))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd106)&(  ( x == 8'd16 )| ( x == 8'd17 )| ( x == 8'd18)| ( x == 8'd40)| ( x == 8'd41)))
				colour <= 3'b111;
			
			else if ( (y == 7'd105)&(  ( x == 8'd16 )| ( x == 8'd41 )| ( x == 8'd42 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd104)&(  ( x == 8'd15 )| ( x == 8'd16 )| ( x == 8'd42 )| ( x == 8'd43 )))	
				colour <= 3'b111;
				
			else if ( (y == 7'd103)&(  ( x == 8'd16 )| ( x == 8'd43 )| ( x == 8'd44 )))	
				colour <= 3'b111;
				
			else if ( (y == 7'd102)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd16 )| ( x == 8'd44 )| ( x == 8'd45)))
				colour <= 3'b111;
			
			else if ( (y == 7'd101)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd45 )| ( x == 8'd46 )))	
				colour <= 3'b111;
			
			else if ( (y == 7'd100)&(  ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd46 )| ( x == 8'd47)))
				colour <= 3'b111;
			
			else if ( (y == 7'd99)&(  ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd46 )| ( x == 8'd47)))
				colour <= 3'b111;	
				
			else if ( (y == 7'd98)&(  ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd51 )| ( x == 8'd52 )| ( x == 8'd53 )| ( x == 8'd54 )| ( x == 8'd55)| ( x == 8'd56)))
				colour <= 3'b111;
			
			else if ( (y == 7'd97)&(  ( x == 8'd13 )| ( x == 8'd56 )| ( x == 8'd57 )| ( x == 8'd58 )| ( x == 8'd59)))
				colour <= 3'b111;	
				
			else if ( (y == 7'd96)&(  ( x == 8'd13 )| ( x == 8'd60 )| ( x == 8'd61 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd95)&(  ( x == 8'd13 )| ( x == 8'd61 )| ( x == 8'd62 )| ( x == 8'd63 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd94)&(  ( x == 8'd13 )| ( x == 8'd63 )| ( x == 8'd64 ))
				colour <= 3'b111;
			
			else if ( (y == 7'd93)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd64 )| ( x == 8'd65 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd92)&(  ( x == 8'd14 )| ( x == 8'd65 )| ( x == 8'd66 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd91)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd66 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd90)&(  ( x == 8'd15 )| ( x == 8'd66 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd89)&(  ( x == 8'd15 )| ( x == 8'd16 )| ( x == 8'd66 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd88)&(  ( x == 8'd15 )( x == 8'd66 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd87)&(  ( x == 8'd15 )| ( x == 8'd66 )))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd86)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd66 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd85)&(  ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd66 )))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd84)&(  ( x == 8'd11 )| ( x == 8'd12 )| ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd54 )| ( x == 8'd55 )| ( x == 8'd56 )| ( x == 8'd65 )| ( x == 8'd66 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd83)&(  ( x == 8'd11 )| ( x == 8'd12 )| ( x == 8'd55 )| ( x == 8'd56 )| ( x == 8'd57 )| ( x == 8'd58 )| ( x == 8'd59 )| ( x == 8'd60 )| ( x == 8'd61 )| ( x == 8'd62 )))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd82)&(  ( x == 8'd9 )| ( x == 8'd10 )| ( x == 8'd11 )| ( x == 8'd57 )| ( x == 8'd58 )| ( x == 8'd59 )| ( x == 8'd60 )| ( x == 8'd61 )| ( x == 8'd62 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd81)&(  ( x == 8'd9 )| ( x == 8'd10 )| ( x == 8'd58 )| ( x == 8'd59 )| ( x == 8'd60 )| ( x == 8'd61 )| ( x == 8'd26 )))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd80)&(  ( x == 8'd8 )| ( x == 8'd9 )| ( x == 8'd61 )| ( x == 8'd62 )| ( x == 8'd25 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd79)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd25 )| ( x == 8'd62 )| ( x == 8'd63 )))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd78)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd62 )| ( x == 8'd63 )))
				colour <= 3'b111;
				
			else if ( (y == 7'd77)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd64 )))	
				colour <= 3'b111;
				
			else if ( (y == 7'd76)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd64 )| ( x == 8'd46 )))
				colour <= 3'b111;
			
			else if ( (y == 7'd75)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd64 )| ( x == 8'd65 )))
				colour <= 3'b111;
				
			else if ( (y == 7'd74)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd65 )))	
				colour <= 3'b111;
				
			else if ( (y == 7'd73)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd22 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd65 )))	
				colour <= 3'b111;

			else if ( (y == 7'd72)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd22 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd49 )| ( x == 8'd50 )| ( x == 8'd65 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd71)&(  ( x == 8'd7 )| ( x == 8'd8 )| ( x == 8'd22 )| ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd50 )| ( x == 8'd51 )| ( x == 8'd65 )）	)
				colour <= 3'b111;

			else if ( (y == 7'd70)&(  ( x == 8'd9 )| ( x == 8'd20 )| ( x == 8'd21 )| ( x == 8'd22 )| ( x == 8'd23 )| ( x == 8'd51 )| ( x == 8'd52 )| ( x == 8'd65 )| ( x == 8'd36 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd69)&(  ( x == 8'd9 )| ( x == 8'd10 )| ( x == 8'd11 )| ( x == 8'd17 )| ( x == 8'd18 )| ( x == 8'd19 )| ( x == 8'd20 )| ( x == 8'd21 )| ( x == 8'd22 )| ( x == 8'd23 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd53 )| ( x == 8'd54 )| ( x == 8'd65 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd68)&(  ( x == 8'd11 )| ( x == 8'd12 )| ( x == 8'd13 )| ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd16 )| ( x == 8'd17 )| ( x == 8'd23 )| ( x == 8'd37 )| ( x == 8'd53 )| ( x == 8'd64 )| ( x == 8'd65 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd67)&(  ( x == 8'd14 )| ( x == 8'd15 )| ( x == 8'd23 )| ( x == 8'd37 )| ( x == 8'd53 )| ( x == 8'd65 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd66)&(  ( x == 8'd23 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd54 )| ( x == 8'd62 )| ( x == 8'd63 )| ( x == 8'd64 )）)	
				colour <= 3'b111;
						
			else if ( (y == 7'd65)&(  ( x == 8'd23 )| ( x == 8'd38 )| ( x == 8'd54 )| ( x == 8'd55 )| ( x == 8'd56 )| ( x == 8'd59 )| ( x == 8'd60 )| ( x == 8'd61 )| ( x == 8'd62 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd64)&(  ( x == 8'd23 )| ( x == 8'd54 )| ( x == 8'd55 )| ( x == 8'd56 )| ( x == 8'd57 )| ( x == 8'd58 )| ( x == 8'd59 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd63)&(  ( x == 8'd23 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd62)&(  ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd39 )| ( x == 8'd55 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd61)&(  ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd39 )| ( x == 8'd55 )| ( x == 8'd23 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd60)&(  ( x == 8'd23 )| ( x == 8'd24 )| ( x == 8'd38 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd59)&(  ( x == 8'd24 )| ( x == 8'd25 )| ( x == 8'd38 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd58)&(  ( x == 8'd25 )| ( x == 8'd38 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd54 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd57)&(  ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd38 )| ( x == 8'd42 )| ( x == 8'd54 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd56)&(  ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd51 )| ( x == 8'd53 )| ( x == 8'd54 )| ( x == 8'd55 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd55)&(  ( x == 8'd25 )| ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd37 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd50 )| ( x == 8'd51 )| ( x == 8'd52 )| ( x == 8'd53 )）)	
				colour <= 3'b111;

			else if ( (y == 7'd54)&(  ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 )））	
				colour <= 3'b111;

			else if ( (y == 7'd53)&(  ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 ) ))
				colour <= 3'b111;
			
						
			// paper right 106 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131 )| ( x == 8'd132 )| ( x == 8'd133	+ 78		
						
			else if ( (y == 7'd113)&(  ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)| ( x == 8'd126)| ( x == 8'd127)| ( x == 8'd128)| ( x == 8'd129)| ( x == 8'd130)| ( x == 8'd131) ))
				colour <= 3'b111; 
			
			else if ( (y == 7'd112)&(  ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123)| ( x == 8'd124)| ( x == 8'd125)| ( x == 8'd123)| ( x == 8'd131)| ( x == 8'd132)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd111)&(  ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121)| ( x == 8'd132)| ( x == 8'd133)| ( x == 8'd124)| ( x == 8'd135)) )	
				colour <= 3'b111;
			
			else if ( (y == 7'd110)&(  ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd134)| ( x == 8'd135)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd109)&(  ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd135)| ( x == 8'd136)| ( x == 8'd137)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd108)&(  ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd137)| ( x == 8'd138)| ( x == 8'd1369)) )	
			   colour <= 3'b111;	
				
			else if ( (y == 7'd107)&(  ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd138)| ( x == 8'd139)| ( x == 8'd140)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd106)&(  ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd140 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd105)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd139 )| ( x == 8'd140 )| ( x == 8'd141)) )
				colour <= 3'b111;
				
			else if ( (y == 7'd104)&(  ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd140 )))	
				colour <= 3'b111;
				
			else if ( (y == 7'd103)&(  ( x == 8'd112 )| ( x == 8'd140 )| ( x == 8'd141 )| ( x == 8'd142 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd102)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd1141 )) )	
				colour <= 3'b111;
			
			else if ( (y == 7'd101)&(  ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd141 )| ( x == 8'd142 )| ( x == 8'd143 )) )	
				colour <= 3'b111;
			
			else if ( (y == 7'd100)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd99)&(  ( x == 8'd100 )| ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd142)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd98)&(  ( x == 8'd97 )| ( x == 8'd98 )| ( x == 8'd99 )| ( x == 8'd100 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111;	
				
			else if ( (y == 7'd97)&(  ( x == 8'd95 )| ( x == 8'd96 )| ( x == 8'd143 )) )
				colour <= 3'b111;

			else if ( (y == 7'd96)&(  ( x == 8'd93 )| ( x == 8'd94 )| ( x == 8'd95 )| ( x == 8'd143 )))
				colour <= 3'b111;	

			else if ( (y == 7'd95)&(  ( x == 8'd92 )| ( x == 8'd93 )| ( x == 8'd143 )))
				colour <= 3'b111;	
			
			else if ( (y == 7'd94)&(  ( x == 8'd91 )| ( x == 8'd92 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111;	

			else if ( (y == 7'd93)&(  ( x == 8'd90 )| ( x == 8'd91 )| ( x == 8'd142 )))
				colour <= 3'b111;	

			else if ( (y == 7'd92)&(  ( x == 8'd90 )| ( x == 8'd141 )| ( x == 8'd142 )))
				colour <= 3'b111;	

			else if ( (y == 7'd91)&(  ( x == 8'd90 )| ( x == 8'd141 )))
				colour <= 3'b111;	

			else if ( (y == 7'd90)&(  ( x == 8'd90 )| ( x == 8'd141 )| ( x == 8'd142 ) ))
				colour <= 3'b111;

			else if ( (y == 7'd89)&(  ( x == 8'd90 )| ( x == 8'd141 )))
				colour <= 3'b111;	

			else if ( (y == 7'd88)&(  ( x == 8'd90 )| ( x == 8'd141 )))
				colour <= 3'b111;		

			else if ( (y == 7'd87)&(  ( x == 8'd90 )| ( x == 8'd141 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111;	

			else if ( (y == 7'd86)&(  ( x == 8'd90 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111;	

			else if ( (y == 7'd85)&(  ( x == 8'd90 )| ( x == 8'd91 )| ( x == 8'd100 )| ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd143 )| ( x == 8'd144 )| ( x == 8'd145 )))
				colour <= 3'b111;

			else if ( (y == 7'd84)&(  ( x == 8'd91 )| ( x == 8'd92 )| ( x == 8'd93 )| ( x == 8'd94 )| ( x == 8'd95 )| ( x == 8'd98 )| ( x == 8'd99 )| ( x == 8'd101 )| ( x == 8'd144 )| ( x == 8'd145 )))
				colour <= 3'b111;

			else if ( (y == 7'd83)&(  ( x == 8'd94 )| ( x == 8'd95 )| ( x == 8'd96 )| ( x == 8'd97 )| ( x == 8'd98 )| ( x == 8'd99 )|( x == 8'd144 )| ( x == 8'd145 )| ( x == 8'd146 )| ( x == 8'd147 )))
				colour <= 3'b111;

			else if ( (y == 7'd82)&(  ( x == 8'd95 )| ( x == 8'd96 )| ( x == 8'd97 )| ( x == 8'd98 )| ( x == 8'd130 )| ( x == 8'd146 )| ( x == 8'd147 )))
				colour <= 3'b111;	

			else if ( (y == 7'd81)&(  ( x == 8'd94 )| ( x == 8'd95 )| ( x == 8'd131 )| ( x == 8'd147 )| ( x == 8'd148 )))
				colour <= 3'b111;

			else if ( (y == 7'd80)&(  ( x == 8'd93 )| ( x == 8'd94 )| ( x == 8'd131 )| ( x == 8'd148 )))
				colour <= 3'b111;	

			else if ( (y == 7'd79)&(  ( x == 8'd93 )| ( x == 8'd130 )| ( x == 8'd131 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111;

			else if ( (y == 7'd78)&(  ( x == 8'd92 )| ( x == 8'd130 )| ( x == 8'd131 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111;

			else if ( (y == 7'd77)&(  ( x == 8'd92 )| ( x == 8'd110 )| ( x == 8'd130 )| ( x == 8'd131 )| ( x == 8'd132 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111;

			else if ( (y == 7'd76)&(  ( x == 8'd91 )| ( x == 8'd92 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd131 )| ( x == 8'd132 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111;

			else if ( (y == 7'd75)&(  ( x == 8'd91 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd131 )| ( x == 8'd132 )| ( x == 8'd133 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111; 

			else if ( (y == 7'd74)&(  ( x == 8'd91 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd132 )| ( x == 8'd133 )| ( x == 8'd134 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111; 

			else if ( (y == 7'd73)&(  ( x == 8'd91 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd132 )| ( x == 8'd133 )| ( x == 8'd134 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111; 

			else if ( (y == 7'd72)&(  ( x == 8'd91 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd133 )| ( x == 8'd134 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111; 

			else if ( (y == 7'd71)&(  ( x == 8'd91 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd120 )| ( x == 8'd133 )| ( x == 8'd134 )| ( x == 8'd135 )| ( x == 8'd136 )| ( x == 8'd148 )| ( x == 8'd149 )))
				colour <= 3'b111; 

			else if ( (y == 7'd70)&(  ( x == 8'd91 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd109 )| ( x == 8'd120 )| ( x == 8'd133 )| ( x == 8'd135 )| ( x == 8'd136 )| ( x == 8'd137 )| ( x == 8'd138 )| ( x == 8'd139 )| ( x == 8'd145 )| ( x == 8'd146 )| ( x == 8'd147 )))
				colour <= 3'b111; 

			else if ( (y == 7'd69)&(  ( x == 8'd91 )| ( x == 8'd92 )| ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd119 )| ( x == 8'd133 )| ( x == 8'd139 )| ( x == 8'd140 )| ( x == 8'd141 )| ( x == 8'd142 )| ( x == 8'd143 )| ( x == 8'd144 )| ( x == 8'd145 )))
				colour <= 3'b111; 

			else if ( (y == 7'd68)&(  ( x == 8'd92 )| ( x == 8'd103 )| ( x == 8'd119 )| ( x == 8'd133 )| ( x == 8'd142 )| ( x == 8'd143 )))
				colour <= 3'b111; 

			else if ( (y == 7'd67)&(  ( x == 8'd92 )| ( x == 8'd93 )| ( x == 8'd94 )| ( x == 8'd102 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd133 )))
				colour <= 3'b111; 


			else if ( (y == 7'd66)&(  ( x == 8'd94 )| ( x == 8'd95 )| ( x == 8'd96 )| ( x == 8'd97 )| ( x == 8'd100 )| ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd118 )| ( x == 8'd133 )))
				colour <= 3'b111; 

			else if ( (y == 7'd65)&(  ( x == 8'd97 )| ( x == 8'd98 )| ( x == 8'd99 )| ( x == 8'd100 )| ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd118 )| ( x == 8'd133 )))
				colour <= 3'b111; 

			else if ( (y == 7'd64)&(  ( x == 8'd101 )| ( x == 8'd118 )| ( x == 8'd133 )))
				colour <= 3'b111; 

			else if ( (y == 7'd63)&(  ( x == 8'd101 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd133 )))
				colour <= 3'b111; 

			else if ( (y == 7'd62)&(  ( x == 8'd101 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd133 )))
				colour <= 3'b111;

			else if ( (y == 7'd61)&(  ( x == 8'd101 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd118 )| ( x == 8'd132 )| ( x == 8'd133 )))
				colour <= 3'b111; 

			else if ( (y == 7'd60)&(  ( x == 8'd101 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd118 )| ( x == 8'd131 )| ( x == 8'd132 )))
				colour <= 3'b111; 

			else if ( (y == 7'd59)&(  ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd118 )| ( x == 8'd131 )))
				colour <= 3'b111; 	

			else if ( (y == 7'd58)&(  ( x == 8'd101 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd118 )| ( x == 8'd130 )| ( x == 8'd131 )))
				colour <= 3'b111; 

			else if ( (y == 7'd57)&(  ( x == 8'd101 )| ( x == 8'd102 )| ( x == 8'd103 )| ( x == 8'd105 )| ( x == 8'd113 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd130 )| ( x == 8'd131 )))
				colour <= 3'b111; 		 

			else if ( (y == 7'd56)&(  ( x == 8'd103 )| ( x == 8'd104 )| ( x == 8'd105 )| ( x == 8'd106 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd119 )| ( x == 8'd129 )| ( x == 8'd130 )| ( x == 8'd131 )))
				colour <= 3'b111; 


			else if ( (y == 7'd55)&(  ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )))
				colour <= 3'b111; 

			else if ( (y == 7'd54)&(  ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )))
				colour <= 3'b111; 

			end 
			
			
			else if (drawmux==2'b10) begin 
					// Scissors left 26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 )| ( x == 8'd37 )| ( x == 8'd38 )| ( x == 8'd39 )| ( x == 8'd40 )| ( x == 8'd41 )| ( x == 8'd42 )| ( x == 8'd43 )| ( x == 8'd44 )| ( x == 8'd45 )| ( x == 8'd46 )| ( x == 8'd47 )| ( x == 8'd48 )| ( x == 8'd49 )| ( x == 8'd50 
			
			if ( (y == 7'd65)&(  ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 ))
				)colour <= 3'b111;
			
			else if ( (y == 7'd66)&(  ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 ))
				)colour <= 3'b111;
			
			else if ( (y == 7'd67)&(  ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 ))	
				)colour <= 3'b111;
				
			else if ( (y == 7'd68)&(  ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 ))		
				)colour <= 3'b111;
				
			else if ( (y == 7'd69)&(  ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36 ))	
				)colour <= 3'b111;
			
			else if ( (y == 7'd70)&(  ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37))	
				)colour <= 3'b111;
			
			else if ( (y == 7'd71)&(  ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37))	
				)colour <= 3'b111;
			
			else if ( (y == 7'd72)&(  ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39) )	
				)colour <= 3'b111;	
				
			else if ( (y == 7'd73)&(  ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd74)&(  ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd75)&(  ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd76)&(  ( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40) )
				)colour <= 3'b111;
				
			else if ( (y == 7'd77)&(  ( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd78)&(  ( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd79)&(  ( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd80)&(  ( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd81)&(  ( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd82)&(  ( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd83)&(  ( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd84)&(  ( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43) )	
				)colour <= 3'b111;	
				
			else if ( (y == 7'd85)&(  ( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd86)&(  ( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd87)&(  ( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd88)&(  ( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd89)&(  ( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd90)&(  ( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd91)&(  ( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd92)&(  ( x == 8'd20 )|( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45)| ( x == 8'd46) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd93)&(  ( x == 8'd20 )|( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45)| ( x == 8'd46) )
				)colour <= 3'b111;
				
			else if ( (y == 7'd94)&(  ( x == 8'd20 )|( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45)| ( x == 8'd46) )
				)colour <= 3'b111;	
				
			else if ( (y == 7'd95)&(  ( x == 8'd19 )|( x == 8'd20 )|( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45)| ( x == 8'd46)| ( x == 8'd47) )
				)colour <= 3'b111;
			
			else if ( (y == 7'd96)&(  ( x == 8'd19 )|( x == 8'd20 )|( x == 8'd21 )|( x == 8'd22 )|( x == 8'd23 )|( x == 8'd24 )|( x == 8'd25 )|( x == 8'd26 )| ( x == 8'd27 )| ( x == 8'd28 )| ( x == 8'd29 )| ( x == 8'd30 )| ( x == 8'd31 )| ( x == 8'd32 )| ( x == 8'd33 )| ( x == 8'd34 )| ( x == 8'd35 )| ( x == 8'd36)| ( x == 8'd37)| ( x == 8'd38)| ( x == 8'd39)| ( x == 8'd40)| ( x == 8'd41)| ( x == 8'd42)| ( x == 8'd43)| ( x == 8'd44)| ( x == 8'd45)| ( x == 8'd46)| ( x == 8'd47) )
				)colour <= 3'b111;	
				
	
			
			
			// Scissors right 106 )| ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 + 80
			
			else if ( (y == 7'd51)&(  ( x == 8'd106 )| ( x == 8'd129 )| ( x == 8'd130)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd52)&(  ( x == 8'd106 )| ( x == 8'd107 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd53)&(  ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129 )| ( x == 8'd130) ))	
				colour <= 3'b111;
				
			else if ( (y == 7'd54)&(  ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129) ))	
				colour <= 3'b111;
				
			else if ( (y == 7'd55)&(  ( x == 8'd107 )| ( x == 8'd108 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd56)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129)))
				colour <= 3'b111;
			
			else if ( (y == 7'd57)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128 )| ( x == 8'd129)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd58)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd59)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )| ( x == 8'd128)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd60)&(  ( x == 8'd108 )| ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127))	)
				colour <= 3'b111;	
				
			else if ( (y == 7'd61)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd62)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd63)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd64)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125 )| ( x == 8'd126 )| ( x == 8'd127)) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd65)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd66)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd67)&(  ( x == 8'd111 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd68)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd122))	)
				colour <= 3'b111;	
				
			else if ( (y == 7'd69)&(  ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd70)&(  ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd71)&(  ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd72)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd73)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd74)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )) )
				colour <= 3'b111;	
				
			else if ( (y == 7'd75)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )) )
				colour <= 3'b111;
			
			else if ( (y == 7'd76)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123))  )
				colour <= 3'b111;	
				
			else if ( (y == 7'd77)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123))  )
				colour <= 3'b111;
			
			else if ( (y == 7'd78)&(  ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123)  ))	
				colour <= 3'b111;	
				
			else if ( (y == 7'd79)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124) ))
				colour <= 3'b111;
				
			else if ( (y == 7'd80)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd81)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125) ))
				colour <= 3'b111;
			
			else if ( (y == 7'd82)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)	))
				colour <= 3'b111;	
				
			else if ( (y == 7'd83)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125) ))
				colour <= 3'b111;
			
			else if ( (y == 7'd84)&(  ( x == 8'd109 )| ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125) ))	
				colour <= 3'b111;	
			
			else if ( (y == 7'd85)&(  ( x == 8'd110 )| ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd86)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123 )| ( x == 8'd124 )| ( x == 8'd125)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd87)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121 )| ( x == 8'd122 )| ( x == 8'd123)) )
				colour <= 3'b111;
			
			else if ( (y == 7'd88)&(  ( x == 8'd111 )| ( x == 8'd112 )| ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120 )| ( x == 8'd121)) )	
				colour <= 3'b111;	
				
			else if ( (y == 7'd89)&(  ( x == 8'd113 )| ( x == 8'd114 )| ( x == 8'd115 )| ( x == 8'd116 )| ( x == 8'd117 )| ( x == 8'd118 )| ( x == 8'd119 )| ( x == 8'd120)) )
				colour <= 3'b111;		
			else colour<= 3'b000;
			end 
			else colour<= 3'b000;
		end

		
		
		assign X = x;
		assign Y = y;


endmodule 			
			
	
	// scissor 10
	// rock 00
	// paper 01
	
	// winner: 00 indicates player1 winning.
	//         01 indicates player2 winning.
	//         11 indicates draw
	//         10 normal state

module control (
        input [1:0] winner,
        input clk,
        input resetn,
        input go,
		  input drawbefore_done_left, // havent been declared 
		  input drawbefore_done_right, 
		  input clear_done,
		  input drawafter_done,
		  output reg writeEn,
		  output reg load_input,
		  output reg compare_,
		  output reg count_,
		  output reg drawbefore_enable_left,// havent been declared 
		  output reg drawbefore_enable_right,
		  output reg clear_enable,
		  output reg drawafter_enable
		  
	     );
		  
		  reg [3:0] current_state, next_state;
			   
    localparam  
	             INITIAL       = 4'b0000,
					 INIWAIT       = 4'b0001,
					 
                LOADING       = 4'b0010,
					 LOADWAIT      = 4'b0011,
					 
					 DRAWBEFOREL   = 4'b0101,
					 DRAWBEFORER   = 4'b0110,
					 
					 COMPARE       = 4'b0111,
					 COMPAREWAIT   = 4'b1000,
					 
					 CLEARING    = 4'b0100,
					// CLEARINGR     = 4'b1000,
					 DRAWAFTER     = 4'b1001,
					
					 
					 COUNTING      = 4'b1100,
					 COUNTWAIT     = 4'b1101;
					 
					
					
					 
					 
					 
					 
	//state logic table 
   always@(*)
		begin: state_table 
		case (current_state) 
				INITIAL: next_state = go? INIWAIT : INITIAL;
				INIWAIT: next_state = go? INIWAIT : LOADING;
				
				LOADING:next_state = go? LOADWAIT: LOADING;
				LOADWAIT: next_state = go? LOADWAIT : DRAWBEFOREL;
				
				DRAWBEFOREL: next_state = drawbefore_done_left? DRAWBEFORER : DRAWBEFOREL;
				DRAWBEFORER: next_state = drawbefore_done_right? COMPARE : DRAWBEFORER;
				
				COMPARE:next_state = go? COMPAREWAIT: COMPARE;
				COMPAREWAIT: next_state = go ? COMPAREWAIT:CLEARING;
				
				CLEARING: next_state =  clear_done? DRAWAFTER:CLEARING;
				DRAWAFTER: next_state= drawafter_done? COUNTING : DRAWAFTER;
				
				COUNTING:next_state = (winner == 2'b10)? COUNTWAIT: COUNTING;
				COUNTWAIT: next_state = go? INITIAL : COUNTWAIT;
				default:next_state =INITIAL;     
	  	 endcase
	   end 
	
	always@(*)
	begin: enable_signals
	   compare_ = 1'b0;
		load_input = 1'b0;
		count_  = 1'b0;
		drawbefore_enable_left = 1'b0;
		drawbefore_enable_right = 1'b0;
		writeEn = 1'b0;
		clear_enable = 1'b0;
		drawafter_enable = 1'b0;
		case (current_state)
		  LOADING: begin 
		      compare_ = 1'b0;
		      count_  = 1'b0;
				load_input = 1'b1;
				end
		  DRAWBEFOREL:begin 
		      drawbefore_enable_left  = 1'b1;
				writeEn = 1'b1;
		      end 
		  DRAWBEFORER : begin 
		      drawbefore_enable_right  = 1'b1;
				writeEn = 1'b1;
				end 
		  COMPARE: begin 
		      load_input = 1'b0;
		      count_  = 1'b0;
				compare_ = 1'b1;
				end
		  COMPAREWAIT: begin 
		      load_input = 1'b0;
		      count_  = 1'b0;
		      compare_ = 1'b1;
				end
		  CLEARING: begin 
				clear_enable = 1'b1;
				writeEn = 1'b1;
		      end 
		  DRAWAFTER: begin 
				drawafter_enable = 1'b1;
				writeEn = 1'b1; 
				end 
		  COUNTING: begin 
		  	   compare_ = 1'b0;
		      load_input = 1'b0;
		      count_ = 1'b1;
				end
		 endcase 
	end // enable signals 
	
   always@(posedge clk)
		begin: state_FFs
		if(!resetn)
			current_state <= INITIAL;
		else
			current_state <= next_state;
	end // state_FFS

endmodule	
		  


		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
module hexdecoder(in, hex);
   	input  [3:0] in;
	   output reg [6:0] hex;
 
  always @(*)  
    case (in)
      4'h0: hex = 7'b1000000;
		4'h1: hex = 7'b1111001;
		4'h2: hex = 7'b0100100;
		4'h3: hex = 7'b0110000;
		4'h4: hex = 7'b0011001;
		4'h5: hex = 7'b0010010;
		4'h6: hex = 7'b0000010;
		4'h7: hex = 7'b1111000;
		4'h8: hex = 7'b0000000;
		4'h9: hex = 7'b0010000;
		4'hA: hex = 7'b0001000;
		4'hb: hex = 7'b0000011;
		4'hC: hex = 7'b1000110;
		4'hd: hex = 7'b0100001;
		4'hE: hex = 7'b0000110;
		4'hF: hex = 7'b0001110;
		default: hex = 7'b1111001;
     endcase 
endmodule
					
		  
		  
		  
		  
		  
module counter4Bit(clock, reset, enable, count, count_done);
	input clock;
	input reset, enable;
	
	output reg [3:0] count;
	output reg count_done;
	
	
	always@ (posedge clock) begin
		if(reset == 0) begin
			count<=0;
			count_done <= 1'b0;
			end
			
	        else if(count == 4'b1111) begin
	            count <= 4'b0000;
	            count_done <= 1'b1;
	            end
		else if(enable) begin
			count<= count+1;
			count_done <= 1'b0;
			end
	        else 
	            count_done <= 1'b0;
	end
endmodule
				
module RateDivider_60(clock,en);
	input clock;
	output reg en;
   	reg [25:0] q = 26'd0;
	
	always@(posedge clock)
	begin
		en <= 0;
		if(q == 26'd0)
		begin
			en <= 1'b1;
			q <= q + 1;
		end
		else if(q == 26'd83333-1)
			q <= 26'd0;
		else 
			q <= q + 1;
	end
	
endmodule

module RateDivider_15frames(clock,en);
	input clock;
	output reg en;
   	reg [25:0] q = 26'd0;
	
	always@(posedge clock)
	begin
		en <= 0;
		if(q == 26'd0)
		begin
			en <= 1'b1;
			q <= q + 1;
		end
		else if(q == 26'd15-1)
			q <= 26'd0;
		else 
			q <= q + 1;
	end
	
endmodule
 
 
 
    /* always @(*) begin
				if (!resetn) begin
					drawafterdone <=1'b0;
				end
				else if (drawafter_enable) begin 
					if (xincrement >=79 ) begin
						xincrement <= 7'b0;
						yincrement <= yincrement +1;
					end
					else if (yincrement >= 59 & xincrement >= 79) begin 
						xincrement <= 7'b0;
					   yincrement <= 6'b0;
						drawafterdone <= 1'b1; // someplaces need it to set to zero
					end 
					else 
						xincrement <= xincrement + 1'b1;
					end
				
				
				
			end*/
			
			
			
			
/*module demo
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		SW,
		HEX0,
		HEX1,
		//HEX5
		colour,
		x,
		y
	);

		input			CLOCK_50;				//	50 MHz
		// Declare your inputs and outputs here
		input          [3:0]KEY;
		input          [9:0]SW;
		output          [6:0]HEX0;
		output          [6:0]HEX1;
		output [7:0] x;  //160
		output [6:0] y; //120
		output [2:0] colour;

	
		wire load;
		wire resetn;
		wire [3:0] scorex;
		wire [3:0] scorey;
		
		output [7:0] x;  //160
		output [6:0] y; //120
		wire [7:0] xcoordinate;
		wire [6:0] ycoordinate;
	
		assign load = ~KEY[0];
		assign  resetn = KEY[3];
		
		  
	
	   wire [1:0] winner;
		wire [1:0] ply1;
		wire [1:0] ply2;
		wire load_input;
		wire count;
		wire compare ,drawbefore_enable_left, drawbefore_enable_right,writeEn;
		wire drawbefore_done_left, drawdone_done_right;
		wire drawafter_enable;
		wire clear_enable;
		wire clear_done;
		wire drawafter_done;
		wire [1:0] drawmux;
		assign ply1 = SW [1:0];
		assign ply2 = SW [9:8];
		
	
			control u1(
			   .winner (winner),
				.clk(CLOCK_50),
				.resetn(resetn),
				.go(load),
				.drawbefore_done_left (drawbefore_done_left),
				.drawbefore_done_right (drawbefore_done_right),
				.clear_done(clear_done),
				.drawafter_done (drawafter_done),
				.writeEn(writeEn),
				.load_input(load_input),
				.compare_(compare),
				.count_(count),
				.drawbefore_enable_left(drawbefore_enable_left),
				.drawbefore_enable_right(drawbefore_enable_right),
				.clear_enable(clear_enable),
				.drawafter_enable(drawafter_enable)
				);
			datapath u2(
				.clk(CLOCK_50),
				.resetn(resetn),
				.ply1(ply1),
				.ply2(ply2),
				.load_input(load_input),
				.compare_enable(compare),
				.count_enable(count),
				.drawbefore_enable_left(drawbefore_enable_left),
				.drawbefore_enable_right(drawbefore_enable_right),
				.clear_enable(clear_enable),
				.drawafter_enable(drawafter_enable),
				.winner(winner),
				.scorex(scorex),
				.scorey(scorey),
				.drawbefore_done_left (drawbefore_done_left),
				.drawbefore_done_right (drawbefore_done_right),
				.drawafter_done (drawafter_done),
				.clear_done(clear_done),
				.X(xcoordinate),
				.Y(ycoordinate),
				.drawmux(drawmux)
				);
			colourmux u3 (
			   .drawmux(drawmux),
			   .x(xcoordinate),
				.y(ycoordinate),
				.colour(colour),
				.X(x),
				.Y(y)
			   );
			hexdecoder h0(
				.in(scorex),
				.hex(HEX0[6:0])
				);
			hexdecoder h1(
				.in(scorey),
				.hex(HEX1[6:0])
				);
				 
		  	  
endmodule */