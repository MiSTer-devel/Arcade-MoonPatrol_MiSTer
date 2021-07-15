//============================================================================
//  Arcade: Moon Patrol
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 1'b0;
assign LED_POWER = 1'b0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;

reg [1:0] ar;

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.MOONPT;;",
	"OGJ,CRT H adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"OKN,CRT V adjust,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"O6,Video timing,Original,PAL;",
	"-;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O7,Pause when OSD is open,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Jump,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,B,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_vid, clk_snd;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys), // 30
	.outclk_1(clk_vid), // 48
	.outclk_2(clk_snd), // 3.58
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
reg         forced_scandoubler;
wire        sd;
wire        direct_video;

wire				ioctl_download;
wire				ioctl_upload;
wire				ioctl_wr;
wire	[7:0]		ioctl_index;
wire	[24:0]	ioctl_addr;
wire	[7:0]		ioctl_dout;
wire	[7:0]		ioctl_din;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;


wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(sd),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4];
wire m_jump   = joy[5];

wire m_up_2   = joy[3];
wire m_down_2 = joy[2];
wire m_left_2 = joy[1];
wire m_right_2= joy[0];
wire m_fire_2 = joy[4];
wire m_jump_2 = joy[5];

wire m_start1 = joy[6];
wire m_start2 = joy[7];
wire m_coin1  = joystick_0[8];
wire m_coin2  = joystick_1[8];
wire m_pause  = joy[9];

// PAUSE SYSTEM
reg				pause;									// Pause signal (active-high)
reg				pause_toggle = 1'b0;					// User paused (active-high)
reg [31:0]		pause_timer;							// Time since pause
reg [31:0]		pause_timer_dim = 31'h11E1A300;	// Time until screen dim (10 seconds @ 48Mhz)
reg 				dim_video = 1'b0;						// Dim video output (active-high)

// Pause when highscore module requires access, user has pressed pause, or OSD is open and option is set
assign pause = hs_access | pause_toggle  | (OSD_STATUS && ~status[7]);
assign dim_video = (pause_timer >= pause_timer_dim) ? 1'b1 : 1'b0;

always @(posedge clk_vid) begin
	reg old_pause;
	old_pause <= m_pause;
	if(~old_pause & m_pause) pause_toggle <= ~pause_toggle;
	if(pause_toggle)
	begin
		if(pause_timer<pause_timer_dim)
		begin
			pause_timer <= pause_timer + 1'b1;
		end
	end
	else
	begin
		pause_timer <= 1'b0;
	end
end

wire hbl,vbl,hs,vs;
wire [3:0] r,g,b;
wire [11:0] rgb_out;

reg clk_6; // nasty! :)
always @(negedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	clk_6 <= div[2];
end

reg ce_pix;
reg HSync,VSync,HBlank,VBlank;
reg [2:0] fx;
always @(posedge clk_vid) begin
	reg old_clk_v;
	old_clk_v <= clk_6;
	ce_pix <= (old_clk_v & ~clk_6);
	rgb_out <= dim_video ? {r >> 1,g >> 1, b >> 1} : {r,g,b};
	HSync <= hs;
	VSync <= vs;
	HBlank <= hbl;
	VBlank <= vbl;
	fx <= status[5:3];
	ar <= status[15:14];
	forced_scandoubler <= sd;
end

arcade_video #(256,12) arcade_video
(
	.*,
	.clk_video(clk_vid),
	.RGB_in(rgb_out)
);

wire [12:0] audio;
assign AUDIO_L = {audio, 3'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;

wire rom_download = ioctl_download & !ioctl_index;
wire reset = RESET | status[0] | ioctl_download | buttons[1];

wire palmode = status[6];
wire [3:0] hs_offset = status[19:16];
wire [3:0] vs_offset = status[23:20];

target_top moonpatrol
(
	.clock_30(clk_sys),
	.clock_v(clk_6),
	.clock_3p58(clk_snd),

	.reset(reset),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr & rom_download),

	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.VGA_HBLANK(hbl),
	.VGA_VBLANK(vbl),

	.palmode(palmode),
	.hs_offset(hs_offset),
	.vs_offset(vs_offset),

	.AUDIO(audio),

	.JOY({m_coin1, m_start1, m_jump, m_fire, m_up, m_down, m_left, m_right}),
	.JOY2({m_coin2, m_start2, m_jump_2, m_fire_2, m_up_2, m_down_2, m_left_2, m_right_2}),

	.pause(pause),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(ioctl_din),
	.hs_write(hs_write)
);


wire [11:0]hs_address;
wire [7:0]hs_data_in;
wire hs_write;
wire hs_access;

hiscore #(
	.HS_ADDRESSWIDTH(12),
	.HS_SCOREWIDTH(6),
	.CFG_ADDRESSWIDTH(1),
	.CFG_LENGTHWIDTH(2)
) hi (
	.clk(clk_sys),
	.reset(reset),
	.ioctl_upload(ioctl_upload),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ram_address(hs_address),
	.data_to_ram(hs_data_in),
	.ram_write(hs_write),
	.ram_access(hs_access)
);

endmodule
