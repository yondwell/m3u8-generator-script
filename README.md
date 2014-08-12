m3u8-generator-script
=====================

           m3u8generator.sh

  (c) 2014 Marcel Poelstra / The Video Express
  
  Originally develloped for our hosting platform
  Since we no longer need it, we moved it to the public domain for anyone who might have any use for it.
  Please note that generating m3u8 files this way, is a rather cpu intensive job.
  
  
  This script generates I-frame based m3u8 playlists for HLS streaming
  The inputfile should be a valid single file h.264/aac transportstream (.ts)
  
  Usage :  m3u8generator.sh <inputfile>.ts
  

  Prerequisites : 
  
  - jq  JSON processor  http://stedolan.github.io/jq/
  
  - sed GNU text filter https://www.gnu.org/software/sed/
  
  - awk GNU data formatting tool http://www.gnu.org/software/gawk/

  - ffprobe part of ffmpeg suite https://www.ffmpeg.org/
  
  Tested on Debian 7.x Wheezy but should work on most *nix platforms
 
 
