//-------------------------------------------------------------------------------------------------
module video
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,
	input  wire[ 2:0] border,
	input  wire[ 7:0] d,
	output wire[12:0] a,
	output wire       bi,
	output wire       rd,
	output wire       cn,
	output wire       vs,
	output wire       hs,
	output wire       r,
	output wire       g,
	output wire       b,
	output wire       i
);
//-------------------------------------------------------------------------------------------------

reg[8:0] hCount;
wire hCountReset = hCount >= 455;
always @(posedge clock) if(ce) if(hCountReset) hCount <= 1'd0; else hCount <= hCount+1'd1;

reg[8:0] vCount;
wire vCountReset = vCount >= 310;
always @(posedge clock) if(ce) if(hCountReset) if(vCountReset) vCount <= 1'd0; else vCount <= vCount+1'd1;

reg[4:0] fCount;
always @(posedge clock) if(ce) if(hCountReset) if(vCountReset) fCount <= fCount+1'd1;

//-------------------------------------------------------------------------------------------------

wire dataEnable = hCount <= 255 && vCount <= 191;

reg videoEnable;
wire videoEnableLoad = hCount[3];
always @(posedge clock) if(ce) if(videoEnableLoad) videoEnable <= dataEnable;

//-------------------------------------------------------------------------------------------------

reg[7:0] dataInput;
wire dataInputLoad = (hCount[3:0] ==  9 || hCount[3:0] == 13) && dataEnable;
always @(posedge clock) if(ce) if(dataInputLoad) dataInput <= d;

reg[7:0] attrInput;
wire attrInputLoad = (hCount[3:0] == 11 || hCount[3:0] == 15) && dataEnable;
always @(posedge clock) if(ce) if(attrInputLoad) attrInput <= d;

reg[7:0] dataOutput;
wire dataOutputLoad = hCount[2:0] == 4 && videoEnable;
always @(posedge clock) if(ce) if(dataOutputLoad) dataOutput <= dataInput; else dataOutput <= { dataOutput[6:0], 1'b0 };

reg[7:0] attrOutput;
wire attrOutputLoad = hCount[2:0] == 4;
always @(posedge clock) if(ce) if(attrOutputLoad) attrOutput <= { videoEnable ? attrInput[7:3] : { 2'b00, border }, attrInput[2:0] };

//-------------------------------------------------------------------------------------------------

wire dataSelect = dataOutput[7] ^ (fCount[4] & attrOutput[7]);
wire videoBlank = (hCount >= 320 && hCount <= 415) || (vCount >= 248 && vCount <= 255);

//-------------------------------------------------------------------------------------------------

assign a = { !hCount[1] ? { vCount[7:6], vCount[2:0] } : { 3'b110, vCount[7:6] }, vCount[5:3], hCount[7:4], hCount[2] };

assign bi = !(vCount == 248 && hCount >= 6 && hCount <= 77);

assign rd = hCount[3] && dataEnable;
assign cn = (hCount[3] || hCount[2]) && dataEnable;

//-------------------------------------------------------------------------------------------------

assign hs = hCount >= 344 && hCount <= 375;
assign vs = vCount >= 248 && vCount <= 251;

assign r = !videoBlank && (dataSelect ? attrOutput[1] : attrOutput[4]);
assign g = !videoBlank && (dataSelect ? attrOutput[2] : attrOutput[5]);
assign b = !videoBlank && (dataSelect ? attrOutput[0] : attrOutput[3]);

assign i = attrOutput[6];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
