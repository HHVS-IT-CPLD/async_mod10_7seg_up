module async_mod10_7seg_up (
	// =============================
	// 實作平台與接腳對應（註解說明）
	// 裝置：MAX II EPM1270T144C5
	// 7 段顯示器 a~g：接至 CPLD 第 1~7 腳
	// CLK：接至 CPLD 第 11 腳
	// RST：接至 CPLD 第 12 腳
	// =============================
	// 外部輸入時脈（驅動最低位元 q[0]）
	input  wire clk,
	// 外部重置信號（建議使用低有效按鍵）
	input  wire rst_n,
	// 7 段顯示器段訊號輸出（共陽極，低電位點亮）
	output wire [6:0] seg,
	// 4-bit 計數值輸出（範圍 0~9）
	output reg  [3:0] q
);

// 非同步清除訊號（active-low）
// auto_clr_n：計到 10 時自動清零
// clr_n：外部 RST 與自動清零共同作用
wire auto_clr_n;
wire clr_n;

// 非同步除10清除：當計數到 1010(10) 時，立即清回 0000。
// 判斷條件 q[3] & q[1] 對應到狀態 1010（其餘位元為 0 時）。
// 這是 ripple counter 常見的 mod-10 實作方式。
assign auto_clr_n = ~(q[3] & q[1]);

// 外部 RST 與自動除10清零皆可觸發清除。
// 只要任一條件要求清除（低），clr_n 即為低。
assign clr_n = rst_n & auto_clr_n;

// ---------------------------
// 非同步上數器（Ripple Counter）
// ---------------------------
// 位元 q[0]：直接由外部 clk 的負緣觸發。
// 每次觸發時將自身反相（toggle），形成除2效果。
always @(negedge clk or negedge clr_n) begin
	if (!clr_n)
		q[0] <= 1'b0;
	else
		q[0] <= ~q[0];
end

// 位元 q[1]：由 q[0] 的負緣觸發，形成串接除2。
// 與 q[0] 合併後可形成 2-bit 非同步上數。
always @(negedge q[0] or negedge clr_n) begin
	if (!clr_n)
		q[1] <= 1'b0;
	else
		q[1] <= ~q[1];
end

// 位元 q[2]：由 q[1] 的負緣觸發。
always @(negedge q[1] or negedge clr_n) begin
	if (!clr_n)
		q[2] <= 1'b0;
	else
		q[2] <= ~q[2];
end

// 位元 q[3]：由 q[2] 的負緣觸發。
// 4 個觸發器串接後先形成 0~15 計數，再由 clr_n 截成 0~9。
always @(negedge q[2] or negedge clr_n) begin
	if (!clr_n)
		q[3] <= 1'b0;
	else
		q[3] <= ~q[3];
end

// 共陽極 7 段顯示器：段訊號為 active-low。
// seg = {a, b, c, d, e, f, g}
// 0 代表該段點亮，1 代表該段熄滅。
reg [6:0] seg_r;
// 內部 seg_r 採 {a,b,c,d,e,f,g}（bit[6] 對應 a）編碼；
// 實體接腳為 seg[0]=a ... seg[6]=g，因此在輸出端做位元反轉映射。
assign seg = {seg_r[0], seg_r[1], seg_r[2], seg_r[3], seg_r[4], seg_r[5], seg_r[6]};

// 組合邏輯解碼：依照 q 對應顯示 0~9。
// 若因暫態或未定義狀態落在 default，則全部熄滅避免亂碼。
always @(*) begin
	case (q)
		
		4'd0: seg_r = 7'b0000001;// 數字 0		
		4'd1: seg_r = 7'b1001111;// 數字 1		
		4'd2: seg_r = 7'b0010010;// 數字 2		
		4'd3: seg_r = 7'b0000110;// 數字 3		
		4'd4: seg_r = 7'b1001100;// 數字 4		
		4'd5: seg_r = 7'b0100100;// 數字 5		
		4'd6: seg_r = 7'b0100000;// 數字 6		
		4'd7: seg_r = 7'b0001111;// 數字 7		
		4'd8: seg_r = 7'b0000000;// 數字 8		
		4'd9: seg_r = 7'b0000100;// 數字 9	
		default: seg_r = 7'b1111111;// 其餘狀態：全部熄滅
	endcase
end

endmodule