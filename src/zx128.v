//-------------------------------------------------------------------------------------------------
// ZX128: ZX Spectrum 128K implementation for ZX-Uno board by Kyp
// https://github.com/Kyp069/zx128
//-------------------------------------------------------------------------------------------------
// Z80 chip module implementation by Sorgelig
// https://github.com/sorgelig/ZX_Spectrum-128K_MIST
//-------------------------------------------------------------------------------------------------
// AY chip module implementation by jotego
// https://github.com/jotego/jt49
//-------------------------------------------------------------------------------------------------
module zx128
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] stdn,
	output wire[ 1:0] sync,
	output wire[ 8:0] rgb,

	input  wire       ear,
	output wire[ 1:0] audio,

	input  wire[ 1:0] ps2,
	input  wire[ 5:0] joy,

	output wire       spiCs,
	output wire       spiCk,
	output wire       spiDi,
	input  wire       spiDo,

	output wire       ramWe,
	inout  wire[ 7:0] ramDQ,
	output wire[20:0] ramA
);
//-------------------------------------------------------------------------------------------------

clock Clock
(
	.i(clock50),
	.o(clock28)
);

reg[2:0] ce;
always @(negedge clock28) ce <= ce+1'd1;

wire ce7M0p = ~ce[0] &  ce[1];
wire ce7M0n = ~ce[0] & ~ce[1];

wire ce3M5p = ~ce[0] & ~ce[1] &  ce[2];
wire ce3M5n = ~ce[0] & ~ce[1] & ~ce[2];

//-------------------------------------------------------------------------------------------------

BUFG Bufg(.I(ce[0]), .O(clockmb));

multiboot Multiboot
(
	.clock  (clockmb),
	.boot   (keyHr   )
);

//-------------------------------------------------------------------------------------------------

reg[5:0] rs;
always @(posedge clock28) if(cc3M5p) if(!rs[5]) rs <= rs+1'd1;

//-------------------------------------------------------------------------------------------------

reg mreqt23iorqtw3;
always @(posedge clock28) if(cc3M5p) mreqt23iorqtw3 <= mreq & ioFE & io7FFD;

reg cpuck;
always @(posedge clock28) if(ce7M0n) cpuck <= !(cpuck && contend);

wire contend = !(vduCn && cpuck && mreqt23iorqtw3 && ((a[15:14] == 2'b01) || ramCn || !ioFE));

wire cc3M5p = ce3M5n & contend;
wire cc3M5n = ce3M5p & contend;

//-------------------------------------------------------------------------------------------------

wire reset = rs[5]&keySr;

reg mi = 1'b1;
always @(posedge clock28) if(cc3M5p) mi <= vduBi;

wire[ 7:0] d;
wire[ 7:0] q;
wire[15:0] a;

cpu Cpu
(
	.clock  (clock28),
	.cep    (cc3M5p ),
	.cen    (cc3M5n ),
	.reset  (reset  ),
	.rfsh   (rfsh   ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.m1     (m1     ),
	.nmi    (nmi    ),
	.mi     (mi     ),
	.d      (d      ),
	.q      (q      ),
	.a      (a      )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] memVQ;
wire[12:0] memVA;
wire[ 7:0] memQ;

memory Mem
(
	.clock  (clock28),
	.reset  (reset  ),
	.rfsh   (rfsh   ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.m1     (m1     ),
	.d      (q      ),
	.a      (a      ),
	.cn     (ramCn  ),
	.vce    (ce7M0n ),
	.vq     (memVQ  ),
	.va     (memVA  ),
	.ce     (cc3M5p ),
	.q      (memQ   ),
	.ramWe  (ramWe  ),
	.ramDQ  (ramDQ  ),
	.ramA   (ramA   )
);

//-------------------------------------------------------------------------------------------------

reg[2:0] border;

video Vdu
(
	.clock  (clock28),
	.ce     (ce7M0n ),
	.border (border ),
	.d      (memVQ  ),
	.a      (memVA  ),
	.bi     (vduBi  ),
	.rd     (vduRd  ),
	.cn     (vduCn  ),
	.vs     (vs     ),
	.hs     (hs     ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.i      (i      )
);

//-------------------------------------------------------------------------------------------------

reg[7:0] specdrum;

reg speaker;
reg mic;

wire[7:0] psgA1;
wire[7:0] psgB1;
wire[7:0] psgC1;

wire[7:0] psgA2;
wire[7:0] psgB2;
wire[7:0] psgC2;

audio Aud
(
	.clock  (clock28),
	.reset  (reset  ),
	.specdrum(specdrum),
	.speaker(speaker),
	.mic    (mic    ),
	.ear    (~ear   ),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  ),
	.audio  (audio  )
);

//-------------------------------------------------------------------------------------------------

wire[4:0] keyQ;
wire[7:0] keyA = a[15:8];

keyboard Key
(
	.clock  (clock28),
	.ce     (ce7M0p ),
	.ps2    (ps2    ),
	.f12    (keySr  ),
	.f11    (keyHr  ),
	.f5     (nmi    ),
	.q      (keyQ   ),
	.a      (keyA   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] spiQ;
wire[7:0] spiA = a[7:0];

spi Spi
(
	.clock  (clock28),
	.cep    (ce7M0p ),
	.cen    (ce7M0n ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.q      (spiQ   ),
	.a      (spiA   ),
	.spiCs  (spiCs  ),
	.spiCk  (spiCk  ),
	.spiDi  (spiDi  ),
	.spiDo  (spiDo  )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] psgQ;

turbosound TS
(
	.clock  (clock28),
	.ce     (ce3M5p ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.q      (psgQ   ),
	.a      (a      ),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  )
);

//-------------------------------------------------------------------------------------------------

always @(posedge clock28) if(cc3M5p) if(!ioDF && !wr) specdrum <= q;

//-------------------------------------------------------------------------------------------------

always @(posedge clock28) if(ce7M0n) if(!ioFE && !wr) { speaker, mic, border } <= q[4:0];

//-------------------------------------------------------------------------------------------------

wire io1F = !(!iorq && a[7:5] == 3'b000);          // kempston
wire ioDF = !(!iorq && a[7:4] == 4'b1101);         // specdrum
wire ioEB = !(!iorq && a[7:0] == 8'hEB);           // spi
wire ioFE = !(!iorq && !a[0]);                     // ula
wire io7FFD = !(!iorq && !a[15] && !a[1]);         // paging
wire ioFFFD = !(!iorq && a[15] && a[14] && !a[1]); // psg

assign d
	= !mreq   ? memQ
	: !ioFE   ? { 1'b1, ~ear|speaker, 1'b1, keyQ }
	: !io1F   ? { 2'b00, ~joy }
	: !ioEB   ? spiQ
	: !ioFFFD ? psgQ
	: !iorq & vduRd ? memVQ
	: 8'hFF;

//-------------------------------------------------------------------------------------------------

assign stdn = 2'b01; // PAL
assign sync = { 1'b1, ~(vs^hs) };
assign rgb  = { r,r&i,r, g,g&i,g, b,b&i,b };

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
