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
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler



	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 1'b0;
assign LED_POWER = 1'b0;

assign {FB_PAL_CLK,  FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

reg [1:0] ar;

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.MOONPT;;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Jump,Start 1P,Start 2P,Coin;",
	"jn,A,B,Start,Select,R;",
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

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;


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
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

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

wire hbl,vbl,hs,vs;
wire [3:0] r,g,b;

reg clk_6; // nasty! :)
always @(negedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	clk_6 <= div[2];
end

reg ce_pix;
reg [11:0] rgb;
reg HSync,VSync,HBlank,VBlank;
reg [2:0] fx;
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
	rgb <= {r,g,b};
	HSync <= ~hs;
	VSync <= ~vs;
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
	.RGB_in(rgb)
);

wire [12:0] audio;
assign AUDIO_L = {audio, 3'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;

target_top moonpatrol
(
	.clock_30(clk_sys),
	.clock_v(clk_6),
	.clock_3p58(clk_snd),

	.reset(RESET | status[0] |ioctl_download | buttons[1] ),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.VGA_HBLANK(hbl),
	.VGA_VBLANK(vbl),

	.AUDIO(audio),

	.JOY({m_coin1, m_start1, m_jump, m_fire, m_up, m_down, m_left, m_right}),
	.JOY2({m_coin2, m_start2, m_jump_2, m_fire_2, m_up_2, m_down_2, m_left_2, m_right_2})
);

endmodule
