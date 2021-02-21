//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,

	input  wire       ce,
	input  wire       reset,
	input  wire       rfsh,
	input  wire       mreq,
	input  wire       iorq,
	input  wire       wr,
	input  wire       m1,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,
	input  wire[15:0] a,

	output wire       cn,

	input  wire       vce,
	output wire[ 7:0] vq,
	input  wire[12:0] va,

	output wire       ramWe,
	inout  wire[ 7:0] ramDQ,
	output wire[20:0] ramA
);
//-------------------------------------------------------------------------------------------------

reg mapForce;
reg mapAuto;
reg mapRam;
reg m1on;
reg[3:0] mapPage;

always @(posedge clock) if(ce)
if(!reset)
begin
	mapForce <= 1'b0;
	mapAuto <= 1'b0;
	mapPage <= 4'd0;
	mapRam <= 1'b0;
	m1on <= 1'b0;
end
else
begin
	if(!iorq && !wr && a[7:0] == 8'hE3)
	begin
		mapForce <= d[7];
		mapPage <= d[3:0];
		mapRam <= d[6]|mapRam;
	end

	if(!mreq && !m1)
	begin
		if(a == 16'h0000 || a == 16'h0008 || a == 16'h0038 || a == 16'h0066 || a == 16'h04C6 || a == 16'h0562)
			m1on <= 1'b1; // activate automapper after this cycle

		else if(a[15:3] == 13'h3FF)
			m1on <= 1'b0; // deactivate automapper after this cycle

		else if(a[15:8] == 8'h3D)
		begin
			m1on <= 1'b1; // activate automapper immediately
			mapAuto <= 1'b1;
		end
	end

	if(m1) mapAuto <= m1on;
end

//-------------------------------------------------------------------------------------------------

reg vduPage;
reg romPage;
reg noPaging;
reg[2:0] ramPage;

always @(posedge clock) if(ce)
if(!reset)
begin
	noPaging <= 1'b0;
	romPage <= 1'b0;
	vduPage <= 1'b0;
	ramPage <= 3'b000;
end
else if(!iorq && !a[15] && !a[1] && !wr && !noPaging)
begin
	noPaging <= d[5];
	romPage <= d[4];
	vduPage <= d[3];
	ramPage <= d[2:0];
end

//-------------------------------------------------------------------------------------------------

wire[ 7:0] romQ;
wire[14:0] romA = { romPage, a[13:0] };

rom #(.AW(15), .FN("+2.hex")) Rom128K // zxdiagnostics diagrom
(
	.clock  (clock  ),
	.ce     (ce     ),
	.q      (romQ   ),
	.a      (romA   )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] divQ;
wire[12:0] divA = a[12:0];

rom #(.AW(13), .FN("esxdos 088.hex")) RomESXDOS
(
	.clock  (clock  ),
	.ce     (ce     ),
	.q      (divQ   ),
	.a      (divA   )
);

//-------------------------------------------------------------------------------------------------

wire va01 = a[15:14] == 2'b01;
wire va11 = a[15:14] == 2'b11 && (ramPage == 3'd5 || ramPage == 3'd7);

wire we1 = !(!mreq && !wr && (va01 || va11) && !a[13]);
wire[13:0] a1 = { va11 ? ramPage[1] : 1'b0, a[12:0] };
wire[13:0] a2 = { vduPage, !rfsh && a[15:14] == 2'b01 ? { va[12:7], a[6:0] } : va };

dpr #(.AW(14)) Dpr
(
	.clock  (clock  ),
	.ce1    (ce     ),
	.we1    (we1    ),
	.d1     (d      ),
	.a1     (a1     ),
	.ce2    (vce    ),
	.q2     (vq     ),
	.a2     (a2     )
);

//-------------------------------------------------------------------------------------------------

wire map = mapForce | mapAuto;
wire[3:0] page = !a[13] ? 4'd3 : mapPage;

assign ramWe = !(!mreq && !wr && (a[15] || a[14] || (a[13] && map)));
assign ramDQ = ramWe ? 8'hZZ : d;
assign ramA =
{
	2'b00
	, a[15:14] == 2'b00 && map ? { 2'b01, page, a[12:0] }
	: { 2'b00, a[15:14] == 2'b01 ? 3'd5 : a[15:14] == 2'b10 ? 3'd2 : ramPage , a[13:0] }
};

//-------------------------------------------------------------------------------------------------

assign cn = a[15:14] == 2'b11 && ramPage[0];

//-------------------------------------------------------------------------------------------------

assign q
	= a[15:13] == 3'b000 && map && !mapRam ? divQ
	: a[15:14] == 2'b00 && !map ? romQ
	: ramDQ;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
