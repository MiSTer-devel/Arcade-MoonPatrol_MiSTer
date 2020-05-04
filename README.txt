---------------------------------------------------------------------------------
-- 
-- Arcade: Moon Patrol port to MiSTer by Sorgelig
-- 27 November 2017
-- 
---------------------------------------------------------------------------------
-- Uses PACE framework by http://pacedev.net/
---------------------------------------------------------------------------------
-- Moon patrol sound board by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- cpu68 - Version 9th Jan 2004 0.8
-- 6800/01 compatible CPU core 
-- GNU public license - December 2002 : John E. Kent
---------------------------------------------------------------------------------
-- 
-- 
-- Keyboard inputs :
--
--   F1          : Coin + Start
--   CTRL        : Fire
--   SPACE       : Jump
--   LEFT,RIGHT  : Increase/Decrease the speed
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
