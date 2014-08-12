m3u8-generator-script
=====================

           m3u8generator.sh

  (c) 2014 Marcel Poelstra / The Video Express
  
  This script generates I-Frame based m3u8 playlists for HLS streaming
  The inputfile should be a valid single file h.264/aac transportstream 
  
  Usage :  m3u8generator.sh <inputfile>.ts
  

  Prerequisites : 
  
  - jq  JSON processor  http://stedolan.github.io/jq/
  
  - sed GNU text filter https://www.gnu.org/software/sed/
  
  - awk GNU data formatting tool http://www.gnu.org/software/gawk/

  - ffprobe part of ffmpeg suite https://www.ffmpeg.org/
  
  Tested on Debian 7.x Wheezy but should work on most *nix platforms
 
 
