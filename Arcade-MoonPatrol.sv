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
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;

`include "build_id.v" 
localparam CONF_STR = {
	"A.MOONPT;;",
	"-;",
	"O1,Aspect Ratio,Original,Wide;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"-;",
	"T6,Reset;",
	"J,Fire,Jump,Start;",
	"V,v1.00.",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_vid, clk_snd;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vid),
	.outclk_2(clk_snd),
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire        forced_scandoubler;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up         <= pressed; // up
			'hX72: btn_down       <= pressed; // down
			'hX6B: btn_left       <= pressed; // left
			'hX74: btn_right      <= pressed; // right
			'h029: btn_jump       <= pressed; // space
			'h014: btn_fire       <= pressed; // ctrl

			'h005: btn_one_player <= pressed; // F1
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;
reg btn_jump  = 0;
reg btn_one_player  = 0;

wire m_up     = btn_up   | joy[3];
wire m_down   = btn_down | joy[2];
wire m_left   = btn_left | joy[1];
wire m_right  = btn_right| joy[0];
wire m_fire   = btn_fire | joy[4];
wire m_jump   = btn_jump | joy[5];

wire m_start1 = btn_one_player  | joy[6];
wire m_coin   = m_start1;

assign VGA_CLK  = clk_vid;
assign HDMI_CLK = VGA_CLK;
assign HDMI_CE  = VGA_CE;
assign HDMI_R   = VGA_R;
assign HDMI_G   = VGA_G;
assign HDMI_B   = VGA_B;
assign HDMI_DE  = VGA_DE;
assign HDMI_HS  = VGA_HS;
assign HDMI_VS  = VGA_VS;
assign HDMI_SL  = 0;

wire HSync, VSync;
wire HBlank, VBlank;
wire [3:0] r,g,b;

wire [1:0] scale = status[4:3];

reg ce_vid;
reg clk_6; // nasty! :)
always @(negedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_vid <= !div;
	clk_6 <= div[2];
end

video_mixer #(.HALF_DEPTH(1)) video_mixer
(
	.*,
	.clk_sys(VGA_CLK),
	.ce_pix(ce_vid),
	.ce_pix_out(VGA_CE),

	.scanlines({scale == 3, scale == 2}),
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),
	.mono(0),

	.R(r),
	.G(g),
	.B(b)
);

wire [12:0] audio;
assign AUDIO_L = {audio, 3'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;

reg initReset_n = 0;
always @(posedge clk_sys) begin
	reg old_download = 0;
	
	old_download <= ioctl_download;
	if(old_download & ~ioctl_download) initReset_n <= 1;
end

target_top moonpatrol
(
	.clock_30(clk_sys),
	.clock_v(clk_6),
	.clock_3p58(clk_snd),

	.reset(RESET | status[0] | status[6] | buttons[1] | ~initReset_n),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HS(HSync),
	.VGA_VS(VSync),
	.VGA_HBLANK(HBlank),
	.VGA_VBLANK(VBlank),

	.AUDIO(audio),

	.JOY({m_coin, m_start1, m_jump, m_fire, m_up, m_down, m_left, m_right})
);

endmodule
