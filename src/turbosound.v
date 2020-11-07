//-------------------------------------------------------------------------------------------------
module turbosound
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,

	input  wire       reset,
	input  wire       iorq,
	input  wire       wr,
	input  wire       rd,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,
	input  wire[15:0] a,

	output wire[ 7:0] a1,
	output wire[ 7:0] b1,
	output wire[ 7:0] c1,

	output wire[ 7:0] a2,
	output wire[ 7:0] b2,
	output wire[ 7:0] c2
);
//-------------------------------------------------------------------------------------------------

// IN  (0xfffd) - !bdir -  bc1 - Read the value of the selected register
// OUT (0xbffd) -  bdir - !bc1 - Write to the selected register
// OUT (0xfffd) -  bdir -  bc1 - Select a register 0-15

wire bdir = !iorq && a[15] && !a[1] && !wr;
wire bc1  = !iorq && a[15] && !a[1] && a[14] && (!rd || !wr);

reg sel;
always @(posedge clock) if(!reset) sel <= 1'b0; else if(bdir && bc1 && d[4]) sel <= ~d[0];

//-------------------------------------------------------------------------------------------------

wire bdir1 = !sel ? bdir : 1'b0;
wire bc11 = !sel ? bc1 : 1'b0;
wire[7:0] q1;

jt49_bus Psg1
(
	.clk    (clock  ),
	.clk_en (ce     ),
	.rst_n  (reset  ),
	.bdir   (bdir1  ),
	.bc1    (bc11   ),
	.din    (d      ),
	.dout   (q1     ),
	.A      (a1     ),
	.B      (b1     ),
	.C      (c1     ),
	.sel    (1'b0   ),
	.sound  (       ),
	.IOA_in (8'hFF  ),
	.IOA_out(       ),
	.IOB_in (8'hFF  ),
	.IOB_out(       )
);

//-------------------------------------------------------------------------------------------------

wire bdir2 = sel ? bdir : 1'b0;
wire bc12 = sel ? bc1 : 1'b0;
wire[7:0] q2;

jt49_bus Psg2
(
	.clk    (clock  ),
	.clk_en (ce     ),
	.rst_n  (reset  ),
	.bdir   (bdir2  ),
	.bc1    (bc12   ),
	.din    (d      ),
	.dout   (q2     ),
	.A      (a2     ),
	.B      (b2     ),
	.C      (c2     ),
	.sel    (1'b0   ),
	.sound  (       ),
	.IOA_in (8'hFF  ),
	.IOA_out(       ),
	.IOB_in (8'hFF  ),
	.IOB_out(       )
);

//-------------------------------------------------------------------------------------------------

assign q = !sel ? q1 : q2;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
