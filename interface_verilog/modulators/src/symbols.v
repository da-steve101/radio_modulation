`ifndef _SYMBOLS_V_
`define _SYMBOLS_V_

// qpsk symbols
module qpsk_mem(
	input wire clk,
	input wire rst,
	input wire [15:0] rd_addr,
	output reg [7:0] i,
	output reg [7:0] q
);

	localparam NUM_WORDS = (1 << 16);

	reg [7:0] mem_i [0:NUM_WORDS-1];
	reg [7:0] mem_q [0:NUM_WORDS-1];

	localparam NUM_SYMBOLS = 144;
	wire [15:0] rd_addr_mod = (rd_addr % NUM_SYMBOLS);

	always @ (posedge clk) begin
		if (rst) begin
			i <= 0;
			q <= 0;
		end else begin
			i <= mem_i[rd_addr_mod];
			q <= mem_q[rd_addr_mod];
		end
	end

	initial begin
		mem_i[0] = $signed(1); mem_q[0] = $signed(1);
		mem_i[1] = $signed(1); mem_q[1] = $signed(1);
		mem_i[2] = $signed(-1); mem_q[2] = $signed(-1);
		mem_i[3] = $signed(1); mem_q[3] = $signed(-1);
		mem_i[4] = $signed(1); mem_q[4] = $signed(-1);
		mem_i[5] = $signed(1); mem_q[5] = $signed(-1);
		mem_i[6] = $signed(-1); mem_q[6] = $signed(1);
		mem_i[7] = $signed(1); mem_q[7] = $signed(-1);
		mem_i[8] = $signed(-1); mem_q[8] = $signed(-1);
		mem_i[9] = $signed(1); mem_q[9] = $signed(-1);
		mem_i[10] = $signed(-1); mem_q[10] = $signed(-1);
		mem_i[11] = $signed(-1); mem_q[11] = $signed(1);
		mem_i[12] = $signed(-1); mem_q[12] = $signed(-1);
		mem_i[13] = $signed(1); mem_q[13] = $signed(1);
		mem_i[14] = $signed(-1); mem_q[14] = $signed(1);
		mem_i[15] = $signed(1); mem_q[15] = $signed(1);
		mem_i[16] = $signed(1); mem_q[16] = $signed(-1);
		mem_i[17] = $signed(-1); mem_q[17] = $signed(-1);
		mem_i[18] = $signed(1); mem_q[18] = $signed(-1);
		mem_i[19] = $signed(-1); mem_q[19] = $signed(1);
		mem_i[20] = $signed(1); mem_q[20] = $signed(-1);
		mem_i[21] = $signed(-1); mem_q[21] = $signed(1);
		mem_i[22] = $signed(-1); mem_q[22] = $signed(1);
		mem_i[23] = $signed(-1); mem_q[23] = $signed(-1);
		mem_i[24] = $signed(-1); mem_q[24] = $signed(1);
		mem_i[25] = $signed(1); mem_q[25] = $signed(-1);
		mem_i[26] = $signed(1); mem_q[26] = $signed(-1);
		mem_i[27] = $signed(1); mem_q[27] = $signed(-1);
		mem_i[28] = $signed(-1); mem_q[28] = $signed(-1);
		mem_i[29] = $signed(1); mem_q[29] = $signed(1);
		mem_i[30] = $signed(-1); mem_q[30] = $signed(-1);
		mem_i[31] = $signed(1); mem_q[31] = $signed(-1);
		mem_i[32] = $signed(-1); mem_q[32] = $signed(1);
		mem_i[33] = $signed(1); mem_q[33] = $signed(1);
		mem_i[34] = $signed(-1); mem_q[34] = $signed(1);
		mem_i[35] = $signed(1); mem_q[35] = $signed(1);
		mem_i[36] = $signed(1); mem_q[36] = $signed(-1);
		mem_i[37] = $signed(-1); mem_q[37] = $signed(-1);
		mem_i[38] = $signed(1); mem_q[38] = $signed(1);
		mem_i[39] = $signed(1); mem_q[39] = $signed(-1);
		mem_i[40] = $signed(1); mem_q[40] = $signed(1);
		mem_i[41] = $signed(-1); mem_q[41] = $signed(1);
		mem_i[42] = $signed(-1); mem_q[42] = $signed(1);
		mem_i[43] = $signed(1); mem_q[43] = $signed(1);
		mem_i[44] = $signed(1); mem_q[44] = $signed(-1);
		mem_i[45] = $signed(-1); mem_q[45] = $signed(1);
		mem_i[46] = $signed(-1); mem_q[46] = $signed(-1);
		mem_i[47] = $signed(-1); mem_q[47] = $signed(-1);
		mem_i[48] = $signed(1); mem_q[48] = $signed(-1);
		mem_i[49] = $signed(-1); mem_q[49] = $signed(1);
		mem_i[50] = $signed(1); mem_q[50] = $signed(-1);
		mem_i[51] = $signed(-1); mem_q[51] = $signed(-1);
		mem_i[52] = $signed(-1); mem_q[52] = $signed(1);
		mem_i[53] = $signed(-1); mem_q[53] = $signed(1);
		mem_i[54] = $signed(-1); mem_q[54] = $signed(-1);
		mem_i[55] = $signed(-1); mem_q[55] = $signed(-1);
		mem_i[56] = $signed(-1); mem_q[56] = $signed(1);
		mem_i[57] = $signed(-1); mem_q[57] = $signed(1);
		mem_i[58] = $signed(-1); mem_q[58] = $signed(-1);
		mem_i[59] = $signed(1); mem_q[59] = $signed(1);
		mem_i[60] = $signed(1); mem_q[60] = $signed(1);
		mem_i[61] = $signed(1); mem_q[61] = $signed(1);
		mem_i[62] = $signed(1); mem_q[62] = $signed(1);
		mem_i[63] = $signed(-1); mem_q[63] = $signed(-1);
		mem_i[64] = $signed(-1); mem_q[64] = $signed(1);
		mem_i[65] = $signed(-1); mem_q[65] = $signed(-1);
		mem_i[66] = $signed(-1); mem_q[66] = $signed(1);
		mem_i[67] = $signed(1); mem_q[67] = $signed(1);
		mem_i[68] = $signed(1); mem_q[68] = $signed(1);
		mem_i[69] = $signed(-1); mem_q[69] = $signed(-1);
		mem_i[70] = $signed(1); mem_q[70] = $signed(-1);
		mem_i[71] = $signed(1); mem_q[71] = $signed(1);
		mem_i[72] = $signed(-1); mem_q[72] = $signed(1);
		mem_i[73] = $signed(1); mem_q[73] = $signed(1);
		mem_i[74] = $signed(1); mem_q[74] = $signed(-1);
		mem_i[75] = $signed(1); mem_q[75] = $signed(-1);
		mem_i[76] = $signed(1); mem_q[76] = $signed(-1);
		mem_i[77] = $signed(1); mem_q[77] = $signed(-1);
		mem_i[78] = $signed(1); mem_q[78] = $signed(-1);
		mem_i[79] = $signed(1); mem_q[79] = $signed(-1);
		mem_i[80] = $signed(-1); mem_q[80] = $signed(-1);
		mem_i[81] = $signed(1); mem_q[81] = $signed(1);
		mem_i[82] = $signed(-1); mem_q[82] = $signed(1);
		mem_i[83] = $signed(-1); mem_q[83] = $signed(-1);
		mem_i[84] = $signed(-1); mem_q[84] = $signed(1);
		mem_i[85] = $signed(1); mem_q[85] = $signed(-1);
		mem_i[86] = $signed(1); mem_q[86] = $signed(1);
		mem_i[87] = $signed(-1); mem_q[87] = $signed(1);
		mem_i[88] = $signed(-1); mem_q[88] = $signed(1);
		mem_i[89] = $signed(-1); mem_q[89] = $signed(-1);
		mem_i[90] = $signed(1); mem_q[90] = $signed(1);
		mem_i[91] = $signed(1); mem_q[91] = $signed(-1);
		mem_i[92] = $signed(-1); mem_q[92] = $signed(-1);
		mem_i[93] = $signed(1); mem_q[93] = $signed(1);
		mem_i[94] = $signed(1); mem_q[94] = $signed(-1);
		mem_i[95] = $signed(-1); mem_q[95] = $signed(-1);
		mem_i[96] = $signed(-1); mem_q[96] = $signed(1);
		mem_i[97] = $signed(1); mem_q[97] = $signed(-1);
		mem_i[98] = $signed(1); mem_q[98] = $signed(-1);
		mem_i[99] = $signed(1); mem_q[99] = $signed(-1);
		mem_i[100] = $signed(1); mem_q[100] = $signed(-1);
		mem_i[101] = $signed(1); mem_q[101] = $signed(1);
		mem_i[102] = $signed(1); mem_q[102] = $signed(-1);
		mem_i[103] = $signed(1); mem_q[103] = $signed(1);
		mem_i[104] = $signed(1); mem_q[104] = $signed(1);
		mem_i[105] = $signed(-1); mem_q[105] = $signed(-1);
		mem_i[106] = $signed(1); mem_q[106] = $signed(1);
		mem_i[107] = $signed(-1); mem_q[107] = $signed(1);
		mem_i[108] = $signed(-1); mem_q[108] = $signed(1);
		mem_i[109] = $signed(1); mem_q[109] = $signed(-1);
		mem_i[110] = $signed(-1); mem_q[110] = $signed(1);
		mem_i[111] = $signed(1); mem_q[111] = $signed(-1);
		mem_i[112] = $signed(-1); mem_q[112] = $signed(1);
		mem_i[113] = $signed(-1); mem_q[113] = $signed(-1);
		mem_i[114] = $signed(-1); mem_q[114] = $signed(1);
		mem_i[115] = $signed(1); mem_q[115] = $signed(1);
		mem_i[116] = $signed(-1); mem_q[116] = $signed(1);
		mem_i[117] = $signed(1); mem_q[117] = $signed(-1);
		mem_i[118] = $signed(-1); mem_q[118] = $signed(1);
		mem_i[119] = $signed(-1); mem_q[119] = $signed(1);
		mem_i[120] = $signed(1); mem_q[120] = $signed(1);
		mem_i[121] = $signed(-1); mem_q[121] = $signed(-1);
		mem_i[122] = $signed(-1); mem_q[122] = $signed(1);
		mem_i[123] = $signed(1); mem_q[123] = $signed(-1);
		mem_i[124] = $signed(1); mem_q[124] = $signed(1);
		mem_i[125] = $signed(-1); mem_q[125] = $signed(-1);
		mem_i[126] = $signed(1); mem_q[126] = $signed(-1);
		mem_i[127] = $signed(-1); mem_q[127] = $signed(1);
		mem_i[128] = $signed(1); mem_q[128] = $signed(-1);
		mem_i[129] = $signed(1); mem_q[129] = $signed(1);
		mem_i[130] = $signed(-1); mem_q[130] = $signed(1);
		mem_i[131] = $signed(1); mem_q[131] = $signed(1);
		mem_i[132] = $signed(1); mem_q[132] = $signed(1);
		mem_i[133] = $signed(-1); mem_q[133] = $signed(-1);
		mem_i[134] = $signed(-1); mem_q[134] = $signed(1);
		mem_i[135] = $signed(-1); mem_q[135] = $signed(-1);
		mem_i[136] = $signed(-1); mem_q[136] = $signed(-1);
		mem_i[137] = $signed(1); mem_q[137] = $signed(1);
		mem_i[138] = $signed(-1); mem_q[138] = $signed(1);
		mem_i[139] = $signed(-1); mem_q[139] = $signed(1);
		mem_i[140] = $signed(-1); mem_q[140] = $signed(-1);
		mem_i[141] = $signed(1); mem_q[141] = $signed(1);
		mem_i[142] = $signed(-1); mem_q[142] = $signed(1);
		mem_i[143] = $signed(1); mem_q[143] = $signed(-1);
	end

endmodule

// bpsk symbols
module bpsk_mem(
	input wire clk,
	input wire rst,
	input wire [15:0] rd_addr,
	output reg [7:0] i,
	output reg [7:0] q
);

	localparam NUM_WORDS = (1 << 16);

	reg [7:0] mem_i [0:NUM_WORDS-1];
	reg [7:0] mem_q [0:NUM_WORDS-1];

	localparam NUM_SYMBOLS = 288;
	wire [15:0] rd_addr_mod = (rd_addr % NUM_SYMBOLS);

	always @ (posedge clk) begin
		if (rst) begin
			i <= 0;
			q <= 0;
		end else begin
			i <= mem_i[rd_addr_mod];
			q <= mem_q[rd_addr_mod];
		end
	end

	initial begin
		mem_i[0] = $signed(-1); mem_q[0] = $signed(0);
		mem_i[1] = $signed(-1); mem_q[1] = $signed(0);
		mem_i[2] = $signed(-1); mem_q[2] = $signed(0);
		mem_i[3] = $signed(-1); mem_q[3] = $signed(0);
		mem_i[4] = $signed(1); mem_q[4] = $signed(0);
		mem_i[5] = $signed(1); mem_q[5] = $signed(0);
		mem_i[6] = $signed(1); mem_q[6] = $signed(0);
		mem_i[7] = $signed(-1); mem_q[7] = $signed(0);
		mem_i[8] = $signed(1); mem_q[8] = $signed(0);
		mem_i[9] = $signed(-1); mem_q[9] = $signed(0);
		mem_i[10] = $signed(1); mem_q[10] = $signed(0);
		mem_i[11] = $signed(-1); mem_q[11] = $signed(0);
		mem_i[12] = $signed(-1); mem_q[12] = $signed(0);
		mem_i[13] = $signed(1); mem_q[13] = $signed(0);
		mem_i[14] = $signed(1); mem_q[14] = $signed(0);
		mem_i[15] = $signed(-1); mem_q[15] = $signed(0);
		mem_i[16] = $signed(1); mem_q[16] = $signed(0);
		mem_i[17] = $signed(1); mem_q[17] = $signed(0);
		mem_i[18] = $signed(1); mem_q[18] = $signed(0);
		mem_i[19] = $signed(-1); mem_q[19] = $signed(0);
		mem_i[20] = $signed(1); mem_q[20] = $signed(0);
		mem_i[21] = $signed(1); mem_q[21] = $signed(0);
		mem_i[22] = $signed(-1); mem_q[22] = $signed(0);
		mem_i[23] = $signed(1); mem_q[23] = $signed(0);
		mem_i[24] = $signed(1); mem_q[24] = $signed(0);
		mem_i[25] = $signed(1); mem_q[25] = $signed(0);
		mem_i[26] = $signed(-1); mem_q[26] = $signed(0);
		mem_i[27] = $signed(-1); mem_q[27] = $signed(0);
		mem_i[28] = $signed(-1); mem_q[28] = $signed(0);
		mem_i[29] = $signed(1); mem_q[29] = $signed(0);
		mem_i[30] = $signed(-1); mem_q[30] = $signed(0);
		mem_i[31] = $signed(-1); mem_q[31] = $signed(0);
		mem_i[32] = $signed(1); mem_q[32] = $signed(0);
		mem_i[33] = $signed(-1); mem_q[33] = $signed(0);
		mem_i[34] = $signed(1); mem_q[34] = $signed(0);
		mem_i[35] = $signed(1); mem_q[35] = $signed(0);
		mem_i[36] = $signed(1); mem_q[36] = $signed(0);
		mem_i[37] = $signed(-1); mem_q[37] = $signed(0);
		mem_i[38] = $signed(-1); mem_q[38] = $signed(0);
		mem_i[39] = $signed(1); mem_q[39] = $signed(0);
		mem_i[40] = $signed(1); mem_q[40] = $signed(0);
		mem_i[41] = $signed(-1); mem_q[41] = $signed(0);
		mem_i[42] = $signed(-1); mem_q[42] = $signed(0);
		mem_i[43] = $signed(1); mem_q[43] = $signed(0);
		mem_i[44] = $signed(-1); mem_q[44] = $signed(0);
		mem_i[45] = $signed(1); mem_q[45] = $signed(0);
		mem_i[46] = $signed(1); mem_q[46] = $signed(0);
		mem_i[47] = $signed(1); mem_q[47] = $signed(0);
		mem_i[48] = $signed(-1); mem_q[48] = $signed(0);
		mem_i[49] = $signed(1); mem_q[49] = $signed(0);
		mem_i[50] = $signed(1); mem_q[50] = $signed(0);
		mem_i[51] = $signed(-1); mem_q[51] = $signed(0);
		mem_i[52] = $signed(1); mem_q[52] = $signed(0);
		mem_i[53] = $signed(-1); mem_q[53] = $signed(0);
		mem_i[54] = $signed(1); mem_q[54] = $signed(0);
		mem_i[55] = $signed(-1); mem_q[55] = $signed(0);
		mem_i[56] = $signed(1); mem_q[56] = $signed(0);
		mem_i[57] = $signed(1); mem_q[57] = $signed(0);
		mem_i[58] = $signed(-1); mem_q[58] = $signed(0);
		mem_i[59] = $signed(-1); mem_q[59] = $signed(0);
		mem_i[60] = $signed(1); mem_q[60] = $signed(0);
		mem_i[61] = $signed(1); mem_q[61] = $signed(0);
		mem_i[62] = $signed(1); mem_q[62] = $signed(0);
		mem_i[63] = $signed(-1); mem_q[63] = $signed(0);
		mem_i[64] = $signed(-1); mem_q[64] = $signed(0);
		mem_i[65] = $signed(1); mem_q[65] = $signed(0);
		mem_i[66] = $signed(-1); mem_q[66] = $signed(0);
		mem_i[67] = $signed(-1); mem_q[67] = $signed(0);
		mem_i[68] = $signed(-1); mem_q[68] = $signed(0);
		mem_i[69] = $signed(1); mem_q[69] = $signed(0);
		mem_i[70] = $signed(-1); mem_q[70] = $signed(0);
		mem_i[71] = $signed(-1); mem_q[71] = $signed(0);
		mem_i[72] = $signed(1); mem_q[72] = $signed(0);
		mem_i[73] = $signed(-1); mem_q[73] = $signed(0);
		mem_i[74] = $signed(1); mem_q[74] = $signed(0);
		mem_i[75] = $signed(1); mem_q[75] = $signed(0);
		mem_i[76] = $signed(-1); mem_q[76] = $signed(0);
		mem_i[77] = $signed(-1); mem_q[77] = $signed(0);
		mem_i[78] = $signed(1); mem_q[78] = $signed(0);
		mem_i[79] = $signed(-1); mem_q[79] = $signed(0);
		mem_i[80] = $signed(-1); mem_q[80] = $signed(0);
		mem_i[81] = $signed(-1); mem_q[81] = $signed(0);
		mem_i[82] = $signed(-1); mem_q[82] = $signed(0);
		mem_i[83] = $signed(1); mem_q[83] = $signed(0);
		mem_i[84] = $signed(-1); mem_q[84] = $signed(0);
		mem_i[85] = $signed(1); mem_q[85] = $signed(0);
		mem_i[86] = $signed(-1); mem_q[86] = $signed(0);
		mem_i[87] = $signed(-1); mem_q[87] = $signed(0);
		mem_i[88] = $signed(1); mem_q[88] = $signed(0);
		mem_i[89] = $signed(-1); mem_q[89] = $signed(0);
		mem_i[90] = $signed(-1); mem_q[90] = $signed(0);
		mem_i[91] = $signed(1); mem_q[91] = $signed(0);
		mem_i[92] = $signed(1); mem_q[92] = $signed(0);
		mem_i[93] = $signed(1); mem_q[93] = $signed(0);
		mem_i[94] = $signed(1); mem_q[94] = $signed(0);
		mem_i[95] = $signed(1); mem_q[95] = $signed(0);
		mem_i[96] = $signed(1); mem_q[96] = $signed(0);
		mem_i[97] = $signed(-1); mem_q[97] = $signed(0);
		mem_i[98] = $signed(-1); mem_q[98] = $signed(0);
		mem_i[99] = $signed(1); mem_q[99] = $signed(0);
		mem_i[100] = $signed(1); mem_q[100] = $signed(0);
		mem_i[101] = $signed(-1); mem_q[101] = $signed(0);
		mem_i[102] = $signed(1); mem_q[102] = $signed(0);
		mem_i[103] = $signed(1); mem_q[103] = $signed(0);
		mem_i[104] = $signed(-1); mem_q[104] = $signed(0);
		mem_i[105] = $signed(1); mem_q[105] = $signed(0);
		mem_i[106] = $signed(-1); mem_q[106] = $signed(0);
		mem_i[107] = $signed(1); mem_q[107] = $signed(0);
		mem_i[108] = $signed(1); mem_q[108] = $signed(0);
		mem_i[109] = $signed(1); mem_q[109] = $signed(0);
		mem_i[110] = $signed(1); mem_q[110] = $signed(0);
		mem_i[111] = $signed(1); mem_q[111] = $signed(0);
		mem_i[112] = $signed(-1); mem_q[112] = $signed(0);
		mem_i[113] = $signed(1); mem_q[113] = $signed(0);
		mem_i[114] = $signed(-1); mem_q[114] = $signed(0);
		mem_i[115] = $signed(1); mem_q[115] = $signed(0);
		mem_i[116] = $signed(1); mem_q[116] = $signed(0);
		mem_i[117] = $signed(1); mem_q[117] = $signed(0);
		mem_i[118] = $signed(-1); mem_q[118] = $signed(0);
		mem_i[119] = $signed(-1); mem_q[119] = $signed(0);
		mem_i[120] = $signed(-1); mem_q[120] = $signed(0);
		mem_i[121] = $signed(-1); mem_q[121] = $signed(0);
		mem_i[122] = $signed(-1); mem_q[122] = $signed(0);
		mem_i[123] = $signed(-1); mem_q[123] = $signed(0);
		mem_i[124] = $signed(-1); mem_q[124] = $signed(0);
		mem_i[125] = $signed(-1); mem_q[125] = $signed(0);
		mem_i[126] = $signed(1); mem_q[126] = $signed(0);
		mem_i[127] = $signed(1); mem_q[127] = $signed(0);
		mem_i[128] = $signed(-1); mem_q[128] = $signed(0);
		mem_i[129] = $signed(1); mem_q[129] = $signed(0);
		mem_i[130] = $signed(1); mem_q[130] = $signed(0);
		mem_i[131] = $signed(1); mem_q[131] = $signed(0);
		mem_i[132] = $signed(-1); mem_q[132] = $signed(0);
		mem_i[133] = $signed(1); mem_q[133] = $signed(0);
		mem_i[134] = $signed(-1); mem_q[134] = $signed(0);
		mem_i[135] = $signed(-1); mem_q[135] = $signed(0);
		mem_i[136] = $signed(-1); mem_q[136] = $signed(0);
		mem_i[137] = $signed(-1); mem_q[137] = $signed(0);
		mem_i[138] = $signed(1); mem_q[138] = $signed(0);
		mem_i[139] = $signed(1); mem_q[139] = $signed(0);
		mem_i[140] = $signed(1); mem_q[140] = $signed(0);
		mem_i[141] = $signed(-1); mem_q[141] = $signed(0);
		mem_i[142] = $signed(-1); mem_q[142] = $signed(0);
		mem_i[143] = $signed(-1); mem_q[143] = $signed(0);
		mem_i[144] = $signed(-1); mem_q[144] = $signed(0);
		mem_i[145] = $signed(1); mem_q[145] = $signed(0);
		mem_i[146] = $signed(-1); mem_q[146] = $signed(0);
		mem_i[147] = $signed(-1); mem_q[147] = $signed(0);
		mem_i[148] = $signed(1); mem_q[148] = $signed(0);
		mem_i[149] = $signed(-1); mem_q[149] = $signed(0);
		mem_i[150] = $signed(1); mem_q[150] = $signed(0);
		mem_i[151] = $signed(-1); mem_q[151] = $signed(0);
		mem_i[152] = $signed(1); mem_q[152] = $signed(0);
		mem_i[153] = $signed(-1); mem_q[153] = $signed(0);
		mem_i[154] = $signed(1); mem_q[154] = $signed(0);
		mem_i[155] = $signed(-1); mem_q[155] = $signed(0);
		mem_i[156] = $signed(1); mem_q[156] = $signed(0);
		mem_i[157] = $signed(-1); mem_q[157] = $signed(0);
		mem_i[158] = $signed(1); mem_q[158] = $signed(0);
		mem_i[159] = $signed(-1); mem_q[159] = $signed(0);
		mem_i[160] = $signed(1); mem_q[160] = $signed(0);
		mem_i[161] = $signed(1); mem_q[161] = $signed(0);
		mem_i[162] = $signed(-1); mem_q[162] = $signed(0);
		mem_i[163] = $signed(-1); mem_q[163] = $signed(0);
		mem_i[164] = $signed(-1); mem_q[164] = $signed(0);
		mem_i[165] = $signed(1); mem_q[165] = $signed(0);
		mem_i[166] = $signed(1); mem_q[166] = $signed(0);
		mem_i[167] = $signed(1); mem_q[167] = $signed(0);
		mem_i[168] = $signed(-1); mem_q[168] = $signed(0);
		mem_i[169] = $signed(1); mem_q[169] = $signed(0);
		mem_i[170] = $signed(1); mem_q[170] = $signed(0);
		mem_i[171] = $signed(-1); mem_q[171] = $signed(0);
		mem_i[172] = $signed(-1); mem_q[172] = $signed(0);
		mem_i[173] = $signed(-1); mem_q[173] = $signed(0);
		mem_i[174] = $signed(-1); mem_q[174] = $signed(0);
		mem_i[175] = $signed(1); mem_q[175] = $signed(0);
		mem_i[176] = $signed(-1); mem_q[176] = $signed(0);
		mem_i[177] = $signed(1); mem_q[177] = $signed(0);
		mem_i[178] = $signed(1); mem_q[178] = $signed(0);
		mem_i[179] = $signed(1); mem_q[179] = $signed(0);
		mem_i[180] = $signed(-1); mem_q[180] = $signed(0);
		mem_i[181] = $signed(-1); mem_q[181] = $signed(0);
		mem_i[182] = $signed(1); mem_q[182] = $signed(0);
		mem_i[183] = $signed(-1); mem_q[183] = $signed(0);
		mem_i[184] = $signed(1); mem_q[184] = $signed(0);
		mem_i[185] = $signed(1); mem_q[185] = $signed(0);
		mem_i[186] = $signed(-1); mem_q[186] = $signed(0);
		mem_i[187] = $signed(-1); mem_q[187] = $signed(0);
		mem_i[188] = $signed(1); mem_q[188] = $signed(0);
		mem_i[189] = $signed(-1); mem_q[189] = $signed(0);
		mem_i[190] = $signed(1); mem_q[190] = $signed(0);
		mem_i[191] = $signed(1); mem_q[191] = $signed(0);
		mem_i[192] = $signed(-1); mem_q[192] = $signed(0);
		mem_i[193] = $signed(1); mem_q[193] = $signed(0);
		mem_i[194] = $signed(1); mem_q[194] = $signed(0);
		mem_i[195] = $signed(-1); mem_q[195] = $signed(0);
		mem_i[196] = $signed(1); mem_q[196] = $signed(0);
		mem_i[197] = $signed(-1); mem_q[197] = $signed(0);
		mem_i[198] = $signed(1); mem_q[198] = $signed(0);
		mem_i[199] = $signed(-1); mem_q[199] = $signed(0);
		mem_i[200] = $signed(1); mem_q[200] = $signed(0);
		mem_i[201] = $signed(-1); mem_q[201] = $signed(0);
		mem_i[202] = $signed(-1); mem_q[202] = $signed(0);
		mem_i[203] = $signed(-1); mem_q[203] = $signed(0);
		mem_i[204] = $signed(1); mem_q[204] = $signed(0);
		mem_i[205] = $signed(-1); mem_q[205] = $signed(0);
		mem_i[206] = $signed(-1); mem_q[206] = $signed(0);
		mem_i[207] = $signed(-1); mem_q[207] = $signed(0);
		mem_i[208] = $signed(-1); mem_q[208] = $signed(0);
		mem_i[209] = $signed(-1); mem_q[209] = $signed(0);
		mem_i[210] = $signed(1); mem_q[210] = $signed(0);
		mem_i[211] = $signed(1); mem_q[211] = $signed(0);
		mem_i[212] = $signed(-1); mem_q[212] = $signed(0);
		mem_i[213] = $signed(-1); mem_q[213] = $signed(0);
		mem_i[214] = $signed(-1); mem_q[214] = $signed(0);
		mem_i[215] = $signed(1); mem_q[215] = $signed(0);
		mem_i[216] = $signed(-1); mem_q[216] = $signed(0);
		mem_i[217] = $signed(1); mem_q[217] = $signed(0);
		mem_i[218] = $signed(1); mem_q[218] = $signed(0);
		mem_i[219] = $signed(-1); mem_q[219] = $signed(0);
		mem_i[220] = $signed(-1); mem_q[220] = $signed(0);
		mem_i[221] = $signed(1); mem_q[221] = $signed(0);
		mem_i[222] = $signed(1); mem_q[222] = $signed(0);
		mem_i[223] = $signed(-1); mem_q[223] = $signed(0);
		mem_i[224] = $signed(-1); mem_q[224] = $signed(0);
		mem_i[225] = $signed(1); mem_q[225] = $signed(0);
		mem_i[226] = $signed(1); mem_q[226] = $signed(0);
		mem_i[227] = $signed(1); mem_q[227] = $signed(0);
		mem_i[228] = $signed(-1); mem_q[228] = $signed(0);
		mem_i[229] = $signed(1); mem_q[229] = $signed(0);
		mem_i[230] = $signed(-1); mem_q[230] = $signed(0);
		mem_i[231] = $signed(-1); mem_q[231] = $signed(0);
		mem_i[232] = $signed(-1); mem_q[232] = $signed(0);
		mem_i[233] = $signed(1); mem_q[233] = $signed(0);
		mem_i[234] = $signed(1); mem_q[234] = $signed(0);
		mem_i[235] = $signed(-1); mem_q[235] = $signed(0);
		mem_i[236] = $signed(-1); mem_q[236] = $signed(0);
		mem_i[237] = $signed(1); mem_q[237] = $signed(0);
		mem_i[238] = $signed(-1); mem_q[238] = $signed(0);
		mem_i[239] = $signed(1); mem_q[239] = $signed(0);
		mem_i[240] = $signed(-1); mem_q[240] = $signed(0);
		mem_i[241] = $signed(-1); mem_q[241] = $signed(0);
		mem_i[242] = $signed(1); mem_q[242] = $signed(0);
		mem_i[243] = $signed(1); mem_q[243] = $signed(0);
		mem_i[244] = $signed(-1); mem_q[244] = $signed(0);
		mem_i[245] = $signed(1); mem_q[245] = $signed(0);
		mem_i[246] = $signed(1); mem_q[246] = $signed(0);
		mem_i[247] = $signed(-1); mem_q[247] = $signed(0);
		mem_i[248] = $signed(-1); mem_q[248] = $signed(0);
		mem_i[249] = $signed(-1); mem_q[249] = $signed(0);
		mem_i[250] = $signed(1); mem_q[250] = $signed(0);
		mem_i[251] = $signed(1); mem_q[251] = $signed(0);
		mem_i[252] = $signed(1); mem_q[252] = $signed(0);
		mem_i[253] = $signed(-1); mem_q[253] = $signed(0);
		mem_i[254] = $signed(-1); mem_q[254] = $signed(0);
		mem_i[255] = $signed(1); mem_q[255] = $signed(0);
		mem_i[256] = $signed(1); mem_q[256] = $signed(0);
		mem_i[257] = $signed(-1); mem_q[257] = $signed(0);
		mem_i[258] = $signed(-1); mem_q[258] = $signed(0);
		mem_i[259] = $signed(-1); mem_q[259] = $signed(0);
		mem_i[260] = $signed(-1); mem_q[260] = $signed(0);
		mem_i[261] = $signed(1); mem_q[261] = $signed(0);
		mem_i[262] = $signed(-1); mem_q[262] = $signed(0);
		mem_i[263] = $signed(-1); mem_q[263] = $signed(0);
		mem_i[264] = $signed(-1); mem_q[264] = $signed(0);
		mem_i[265] = $signed(-1); mem_q[265] = $signed(0);
		mem_i[266] = $signed(1); mem_q[266] = $signed(0);
		mem_i[267] = $signed(1); mem_q[267] = $signed(0);
		mem_i[268] = $signed(-1); mem_q[268] = $signed(0);
		mem_i[269] = $signed(1); mem_q[269] = $signed(0);
		mem_i[270] = $signed(1); mem_q[270] = $signed(0);
		mem_i[271] = $signed(1); mem_q[271] = $signed(0);
		mem_i[272] = $signed(1); mem_q[272] = $signed(0);
		mem_i[273] = $signed(1); mem_q[273] = $signed(0);
		mem_i[274] = $signed(-1); mem_q[274] = $signed(0);
		mem_i[275] = $signed(-1); mem_q[275] = $signed(0);
		mem_i[276] = $signed(-1); mem_q[276] = $signed(0);
		mem_i[277] = $signed(1); mem_q[277] = $signed(0);
		mem_i[278] = $signed(-1); mem_q[278] = $signed(0);
		mem_i[279] = $signed(1); mem_q[279] = $signed(0);
		mem_i[280] = $signed(1); mem_q[280] = $signed(0);
		mem_i[281] = $signed(1); mem_q[281] = $signed(0);
		mem_i[282] = $signed(-1); mem_q[282] = $signed(0);
		mem_i[283] = $signed(-1); mem_q[283] = $signed(0);
		mem_i[284] = $signed(-1); mem_q[284] = $signed(0);
		mem_i[285] = $signed(1); mem_q[285] = $signed(0);
		mem_i[286] = $signed(1); mem_q[286] = $signed(0);
		mem_i[287] = $signed(-1); mem_q[287] = $signed(0);
	end
endmodule

// 8psk symbols
module M8psk_mem(
	input wire clk,
	input wire rst,
	input wire [15:0] rd_addr,
	output reg [7:0] i,
	output reg [7:0] q
);

	localparam NUM_WORDS = (1 << 16);

	reg [7:0] mem_i [0:NUM_WORDS-1];
	reg [7:0] mem_q [0:NUM_WORDS-1];

	localparam NUM_SYMBOLS = 96;
	wire [15:0] rd_addr_mod = (rd_addr % NUM_SYMBOLS);

	always @ (posedge clk) begin
		if (rst) begin
			i <= 0;
			q <= 0;
		end else begin
			i <= mem_i[rd_addr_mod];
			q <= mem_q[rd_addr_mod];
		end
	end

	initial begin
		mem_i[0] = $signed(1); mem_q[0] = $signed(0);
		mem_i[1] = $signed(0); mem_q[1] = $signed(1);
		mem_i[2] = $signed(-1); mem_q[2] = $signed(0);
		mem_i[3] = $signed(1); mem_q[3] = $signed(-1);
		mem_i[4] = $signed(0); mem_q[4] = $signed(1);
		mem_i[5] = $signed(0); mem_q[5] = $signed(1);
		mem_i[6] = $signed(-1); mem_q[6] = $signed(0);
		mem_i[7] = $signed(-1); mem_q[7] = $signed(0);
		mem_i[8] = $signed(0); mem_q[8] = $signed(-1);
		mem_i[9] = $signed(1); mem_q[9] = $signed(1);
		mem_i[10] = $signed(1); mem_q[10] = $signed(1);
		mem_i[11] = $signed(0); mem_q[11] = $signed(1);
		mem_i[12] = $signed(-1); mem_q[12] = $signed(-1);
		mem_i[13] = $signed(0); mem_q[13] = $signed(-1);
		mem_i[14] = $signed(1); mem_q[14] = $signed(-1);
		mem_i[15] = $signed(-1); mem_q[15] = $signed(1);
		mem_i[16] = $signed(0); mem_q[16] = $signed(1);
		mem_i[17] = $signed(1); mem_q[17] = $signed(-1);
		mem_i[18] = $signed(-1); mem_q[18] = $signed(0);
		mem_i[19] = $signed(-1); mem_q[19] = $signed(-1);
		mem_i[20] = $signed(-1); mem_q[20] = $signed(1);
		mem_i[21] = $signed(1); mem_q[21] = $signed(1);
		mem_i[22] = $signed(1); mem_q[22] = $signed(0);
		mem_i[23] = $signed(-1); mem_q[23] = $signed(-1);
		mem_i[24] = $signed(-1); mem_q[24] = $signed(0);
		mem_i[25] = $signed(-1); mem_q[25] = $signed(-1);
		mem_i[26] = $signed(-1); mem_q[26] = $signed(-1);
		mem_i[27] = $signed(1); mem_q[27] = $signed(1);
		mem_i[28] = $signed(1); mem_q[28] = $signed(-1);
		mem_i[29] = $signed(1); mem_q[29] = $signed(-1);
		mem_i[30] = $signed(0); mem_q[30] = $signed(1);
		mem_i[31] = $signed(-1); mem_q[31] = $signed(1);
		mem_i[32] = $signed(-1); mem_q[32] = $signed(-1);
		mem_i[33] = $signed(0); mem_q[33] = $signed(-1);
		mem_i[34] = $signed(0); mem_q[34] = $signed(-1);
		mem_i[35] = $signed(-1); mem_q[35] = $signed(0);
		mem_i[36] = $signed(-1); mem_q[36] = $signed(1);
		mem_i[37] = $signed(-1); mem_q[37] = $signed(0);
		mem_i[38] = $signed(0); mem_q[38] = $signed(1);
		mem_i[39] = $signed(-1); mem_q[39] = $signed(-1);
		mem_i[40] = $signed(1); mem_q[40] = $signed(0);
		mem_i[41] = $signed(1); mem_q[41] = $signed(0);
		mem_i[42] = $signed(0); mem_q[42] = $signed(-1);
		mem_i[43] = $signed(-1); mem_q[43] = $signed(1);
		mem_i[44] = $signed(1); mem_q[44] = $signed(-1);
		mem_i[45] = $signed(1); mem_q[45] = $signed(0);
		mem_i[46] = $signed(-1); mem_q[46] = $signed(1);
		mem_i[47] = $signed(1); mem_q[47] = $signed(0);
		mem_i[48] = $signed(1); mem_q[48] = $signed(-1);
		mem_i[49] = $signed(1); mem_q[49] = $signed(-1);
		mem_i[50] = $signed(-1); mem_q[50] = $signed(0);
		mem_i[51] = $signed(1); mem_q[51] = $signed(-1);
		mem_i[52] = $signed(-1); mem_q[52] = $signed(0);
		mem_i[53] = $signed(0); mem_q[53] = $signed(1);
		mem_i[54] = $signed(1); mem_q[54] = $signed(0);
		mem_i[55] = $signed(-1); mem_q[55] = $signed(1);
		mem_i[56] = $signed(0); mem_q[56] = $signed(1);
		mem_i[57] = $signed(1); mem_q[57] = $signed(0);
		mem_i[58] = $signed(1); mem_q[58] = $signed(-1);
		mem_i[59] = $signed(-1); mem_q[59] = $signed(1);
		mem_i[60] = $signed(1); mem_q[60] = $signed(1);
		mem_i[61] = $signed(0); mem_q[61] = $signed(1);
		mem_i[62] = $signed(1); mem_q[62] = $signed(1);
		mem_i[63] = $signed(0); mem_q[63] = $signed(1);
		mem_i[64] = $signed(0); mem_q[64] = $signed(1);
		mem_i[65] = $signed(1); mem_q[65] = $signed(-1);
		mem_i[66] = $signed(-1); mem_q[66] = $signed(0);
		mem_i[67] = $signed(1); mem_q[67] = $signed(0);
		mem_i[68] = $signed(-1); mem_q[68] = $signed(-1);
		mem_i[69] = $signed(1); mem_q[69] = $signed(0);
		mem_i[70] = $signed(0); mem_q[70] = $signed(-1);
		mem_i[71] = $signed(1); mem_q[71] = $signed(1);
		mem_i[72] = $signed(0); mem_q[72] = $signed(1);
		mem_i[73] = $signed(1); mem_q[73] = $signed(1);
		mem_i[74] = $signed(-1); mem_q[74] = $signed(-1);
		mem_i[75] = $signed(-1); mem_q[75] = $signed(1);
		mem_i[76] = $signed(1); mem_q[76] = $signed(-1);
		mem_i[77] = $signed(1); mem_q[77] = $signed(1);
		mem_i[78] = $signed(-1); mem_q[78] = $signed(-1);
		mem_i[79] = $signed(-1); mem_q[79] = $signed(0);
		mem_i[80] = $signed(1); mem_q[80] = $signed(1);
		mem_i[81] = $signed(-1); mem_q[81] = $signed(0);
		mem_i[82] = $signed(-1); mem_q[82] = $signed(-1);
		mem_i[83] = $signed(0); mem_q[83] = $signed(1);
		mem_i[84] = $signed(-1); mem_q[84] = $signed(-1);
		mem_i[85] = $signed(0); mem_q[85] = $signed(-1);
		mem_i[86] = $signed(1); mem_q[86] = $signed(0);
		mem_i[87] = $signed(-1); mem_q[87] = $signed(-1);
		mem_i[88] = $signed(1); mem_q[88] = $signed(1);
		mem_i[89] = $signed(-1); mem_q[89] = $signed(0);
		mem_i[90] = $signed(-1); mem_q[90] = $signed(1);
		mem_i[91] = $signed(-1); mem_q[91] = $signed(-1);
		mem_i[92] = $signed(1); mem_q[92] = $signed(-1);
		mem_i[93] = $signed(-1); mem_q[93] = $signed(1);
		mem_i[94] = $signed(1); mem_q[94] = $signed(0);
		mem_i[95] = $signed(0); mem_q[95] = $signed(-1);
	end

endmodule

// qam16 symbols
module qam16_mem(
	input wire clk,
	input wire rst,
	input wire [15:0] rd_addr,
	output reg [7:0] i,
	output reg [7:0] q
);

	localparam NUM_WORDS = (1 << 16);

	reg [7:0] mem_i [0:NUM_WORDS-1];
	reg [7:0] mem_q [0:NUM_WORDS-1];

	localparam NUM_SYMBOLS = 72;
	wire [15:0] rd_addr_mod = (rd_addr % NUM_SYMBOLS);

	always @ (posedge clk) begin
		if (rst) begin
			i <= 0;
			q <= 0;
		end else begin
			i <= mem_i[rd_addr_mod];
			q <= mem_q[rd_addr_mod];
		end
	end

	initial begin
		mem_i[0] = $signed(-2); mem_q[0] = $signed(-2);
		mem_i[1] = $signed(2); mem_q[1] = $signed(1);
		mem_i[2] = $signed(2); mem_q[2] = $signed(2);
		mem_i[3] = $signed(2); mem_q[3] = $signed(-1);
		mem_i[4] = $signed(2); mem_q[4] = $signed(1);
		mem_i[5] = $signed(-1); mem_q[5] = $signed(1);
		mem_i[6] = $signed(-2); mem_q[6] = $signed(1);
		mem_i[7] = $signed(-2); mem_q[7] = $signed(-1);
		mem_i[8] = $signed(1); mem_q[8] = $signed(2);
		mem_i[9] = $signed(-1); mem_q[9] = $signed(2);
		mem_i[10] = $signed(-1); mem_q[10] = $signed(2);
		mem_i[11] = $signed(1); mem_q[11] = $signed(-1);
		mem_i[12] = $signed(2); mem_q[12] = $signed(-1);
		mem_i[13] = $signed(2); mem_q[13] = $signed(2);
		mem_i[14] = $signed(-2); mem_q[14] = $signed(1);
		mem_i[15] = $signed(2); mem_q[15] = $signed(1);
		mem_i[16] = $signed(-2); mem_q[16] = $signed(-1);
		mem_i[17] = $signed(-2); mem_q[17] = $signed(-1);
		mem_i[18] = $signed(1); mem_q[18] = $signed(2);
		mem_i[19] = $signed(2); mem_q[19] = $signed(-2);
		mem_i[20] = $signed(-1); mem_q[20] = $signed(-2);
		mem_i[21] = $signed(-2); mem_q[21] = $signed(-1);
		mem_i[22] = $signed(-1); mem_q[22] = $signed(2);
		mem_i[23] = $signed(1); mem_q[23] = $signed(1);
		mem_i[24] = $signed(-1); mem_q[24] = $signed(2);
		mem_i[25] = $signed(1); mem_q[25] = $signed(2);
		mem_i[26] = $signed(-1); mem_q[26] = $signed(-1);
		mem_i[27] = $signed(1); mem_q[27] = $signed(1);
		mem_i[28] = $signed(-1); mem_q[28] = $signed(-1);
		mem_i[29] = $signed(-2); mem_q[29] = $signed(1);
		mem_i[30] = $signed(-2); mem_q[30] = $signed(-2);
		mem_i[31] = $signed(1); mem_q[31] = $signed(-2);
		mem_i[32] = $signed(1); mem_q[32] = $signed(-1);
		mem_i[33] = $signed(-2); mem_q[33] = $signed(-1);
		mem_i[34] = $signed(1); mem_q[34] = $signed(-2);
		mem_i[35] = $signed(-2); mem_q[35] = $signed(2);
		mem_i[36] = $signed(-2); mem_q[36] = $signed(-1);
		mem_i[37] = $signed(2); mem_q[37] = $signed(2);
		mem_i[38] = $signed(2); mem_q[38] = $signed(2);
		mem_i[39] = $signed(2); mem_q[39] = $signed(2);
		mem_i[40] = $signed(-2); mem_q[40] = $signed(1);
		mem_i[41] = $signed(1); mem_q[41] = $signed(-1);
		mem_i[42] = $signed(2); mem_q[42] = $signed(-1);
		mem_i[43] = $signed(-1); mem_q[43] = $signed(-2);
		mem_i[44] = $signed(1); mem_q[44] = $signed(-1);
		mem_i[45] = $signed(2); mem_q[45] = $signed(-2);
		mem_i[46] = $signed(-2); mem_q[46] = $signed(1);
		mem_i[47] = $signed(1); mem_q[47] = $signed(2);
		mem_i[48] = $signed(2); mem_q[48] = $signed(-1);
		mem_i[49] = $signed(2); mem_q[49] = $signed(2);
		mem_i[50] = $signed(-2); mem_q[50] = $signed(2);
		mem_i[51] = $signed(-2); mem_q[51] = $signed(2);
		mem_i[52] = $signed(1); mem_q[52] = $signed(-2);
		mem_i[53] = $signed(-1); mem_q[53] = $signed(-2);
		mem_i[54] = $signed(2); mem_q[54] = $signed(-1);
		mem_i[55] = $signed(2); mem_q[55] = $signed(-1);
		mem_i[56] = $signed(1); mem_q[56] = $signed(-1);
		mem_i[57] = $signed(-2); mem_q[57] = $signed(-1);
		mem_i[58] = $signed(2); mem_q[58] = $signed(-1);
		mem_i[59] = $signed(-1); mem_q[59] = $signed(-1);
		mem_i[60] = $signed(1); mem_q[60] = $signed(-2);
		mem_i[61] = $signed(2); mem_q[61] = $signed(-1);
		mem_i[62] = $signed(1); mem_q[62] = $signed(-2);
		mem_i[63] = $signed(-1); mem_q[63] = $signed(2);
		mem_i[64] = $signed(-2); mem_q[64] = $signed(2);
		mem_i[65] = $signed(-2); mem_q[65] = $signed(-1);
		mem_i[66] = $signed(1); mem_q[66] = $signed(-2);
		mem_i[67] = $signed(1); mem_q[67] = $signed(-1);
		mem_i[68] = $signed(-2); mem_q[68] = $signed(1);
		mem_i[69] = $signed(-1); mem_q[69] = $signed(-1);
		mem_i[70] = $signed(-2); mem_q[70] = $signed(1);
		mem_i[71] = $signed(2); mem_q[71] = $signed(-1);
	end
endmodule

`endif // _SYMBOLS_V_
