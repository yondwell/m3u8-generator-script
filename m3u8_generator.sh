#!/bin/bash
# 
#           m3u8generator.sh
#
#  (c) 2014 Marcel Poelstra / The Video Express
#
#  Prerequisites : jq sed awk ffprobe
#  Tested on Debian 7.x Wheezy
# 
#  This script generates I-Frame based m3u8 playlists for HLS streaming
#  The inputfile should be a valid single file h.264/aac transportstream 
#  Usage :  m3u8generator.sh <inputfile>.ts
#
# SET DESIRED CHUNK SIZE IN SECONDS BELOW :
#
CHUNK=30
#
# DO NOT EDIT BELOW THIS LINE
#
##################################################################################################################
INPUT="$@";
#
# LOG FUNCTION
function logit() {
  if $LOGGING ; then
    logger -st "TVX m3u8 generator" $$ "$1"
  fi
}


logit "Starting m3u8 generator"
#
FILENAME_TS=$(basename "$INPUT");
BASENAME_TS=${FILENAME_TS%%.*}
#

# Determining input video duration :
#
DURATION_TS=$(ffprobe $INPUT -show_format -v quiet | grep duration |sed "s/duration=//g");

if [ $DURATION_TS -le $CHUNK ]
then
logit "Video duration < desired chunksize, using default single file playlist"
cat > "${BASENAME_TS}.m3u8" << EOF
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:${DURATION_TS}
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:$DURATION_TS,
ts/${BASENAME_TS}.ts
#EXT-X-ENDLIST
EOF
logit "Single file m3u8 successfully created"
exit 1
fi
#
# Creating temporay json file with packet information: 
#
ffprobe $INPUT -show_packets -print_format json -v quiet > /tmp/packetinfo_$BASENAME_TS.json;
#
# Creating temporary file with i-frame information
#
/usr/local/bin/jq -r '.packets[] | select(.codec_type="video") | select(.flags=="K") | select (.pos !=null) | .pos ' "tmp/packetinfo_${BASENAME_TS}.json" > /tmp/iframes_$BASENAME_TS.tmp;
#
logit " debug : /tmp/packetinfo_${BASENAME_TS}.json";
# Counting total number of I-frames in input video :
#
IFRAME_COUNT=$(/usr/local/bin/jq -r '[.packets[] | select(.codec_type="video") | select(.flags=="K") | select (.pos !=null) | .pos] | length' "/tmp/packetinfo_${BASENAME_TS}.json" );
#
logit "I-frame count : ${IFRAME_COUNT}"
#
BYTE_SIZE=$(ffprobe $INPUT -show_format -v quiet | grep size |sed "s/size=//g" );
#
logit "Byte size :  ${BYTE_SIZE}";
#
# Determining amount of i-frames per second :
#
IFRAME_SPEED=$(echo $IFRAME_COUNT/$DURATION_TS | bc );
#
#
logit  "Duration :  ${DURATION_TS} seconds";
logit  "I-frame speed : ${IFRAME_SPEED} iframes per second";
#
# Calculating desired segment size to amount of i-frames :
#
SEG=$(echo $IFRAME_SPEED*$CHUNK | bc );
#
logit  "Segment size : ${SEG} iframes";
# Preparing m3u8 playlist file :
#
cat > "${BASENAME_TS}.m3u8" << EOF
#EXTM3U
#EXT-X-VERSION:4
#EXT-X-TARGETDURATION:$CHUNK
EOF
#
# Defining working array :
#
getArray() {
    X=0
    while read line 
    do
        IFRAMEPOSITIONS[X]=$line 
        X=$(($X + 1))
    done < $1
}
getArray "/tmp/iframes_$BASENAME_TS.tmp"

#
# Itterating through the array for needed parameters and constructing segment entries :
#
for (( I=0; $I < ${#IFRAMEPOSITIONS[@]}; I+=$SEG ));
do
#
#
logit  "previous ${IFRAMEPOSITIONS[I-1]} current ${IFRAMEPOSITIONS[I]} - ${I} next ${IFRAMEPOSITIONS[I+$SEG]} ";
#
# Determining current segment byte position :
#
BYTE_CURRENT=${IFRAMEPOSITIONS[I]};
#
logit  "current byte position ${BYTE_CURRENT}"
#
if [ $I = 0 ]  && [ $(echo "$BYTE_CURRENT>0" | bc) -eq 1 ];
then BYTE_CURRENT=0 ;
fi
# Determining next segment byte position :
#
BYTE_NEXT=${IFRAMEPOSITIONS[I+$SEG]}
#
#
logit "next byte position ${BYTE_NEXT}"
#
# Calculating current segment byte size : 
#
BYTE_SEG=$(echo $BYTE_NEXT-$BYTE_CURRENT | bc);
#
logit "segment size ${BYTE_SEG}"
#
if  [ $(echo "$BYTE_SEG<0" | bc) -eq 1 ]
then break
fi
#
# Determining current PTS time at current byte position :
#
TIME_CURRENT=$(/usr/local/bin/jq -r --arg POS $BYTE_CURRENT '.packets[] | select(.codec_type="video") | select(.flags=="K") | select (.pos !=null) | select(.pos == $POS)|.pts_time' "/tmp/packetinfo_${BASENAME_TS}.json" );
#
if [ $I = 0 ];
then TIME_CURRENT=0 ;
fi

# Determining next segment PTS time at next segment byte position :
#
TIME_NEXT=$(/usr/local/bin/jq -r --arg POS2 $BYTE_NEXT '.packets[] | select(.codec_type="video") | select(.flags=="K") | select (.pos !=null) | select(.pos == $POS2)|.pts_time' "/tmp/packetinfo_${BASENAME_TS}.json");
#
# Calculating current segment time :
#
TIME_SEG=$(echo $TIME_NEXT-$TIME_CURRENT | bc -l);
#
# Filling m3u8 with current segment parameters :
#
echo "#EXTINF:${TIME_SEG}," >> ${BASENAME_TS}.m3u8
echo "#EXT-X-BYTERANGE:${BYTE_SEG}@${BYTE_CURRENT}" >> ${BASENAME_TS}.m3u8
echo "$INPUT" >> ${BASENAME_TS}.m3u8
#
done
#
#
#
TIME_SEG_LAST=$(echo $DURATION-$TIME_CURRENT | bc -l);
echo "#EXTINF:${TIME_SEG_LAST}," >> ${BASENAME_TS}.m3u8
BYTE_SEG_LAST=$(echo $BYTE_SIZE-$BYTE_CURRENT | bc -l);
#
logit "Last segment : ${BYTE_SEG_LAST}"
#
echo "#EXT-X-BYTERANGE:${BYTE_SEG_LAST}@${BYTE_CURRENT}" >> ${BASENAME_TS}.m3u8
echo "$INPUT" >> ${BASENAME_TS}.m3u8
echo "#EXT-X-ENDLIST" >>  ${BASENAME_TS}.m3u8
#
# CLEAN UP TEMP FILES
#
rm /tmp/packetinfo_$BASENAME.json
rm /tmp/iframes_$BASENAME.tmp
