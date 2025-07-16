#!/usr/bin/env bash

set -e

if [[ "$1" != "" ]]; then
    TITLE_TYP="$1"
else
    TITLE_TYP="./title.typ"
fi

if [[ "$2" != "" ]]; then
    READING_VIDEO="$2"
else
    READING_VIDEO="./reading.mkv"
fi

if [[ "$3" != "" ]]; then
    END_PNG="$3"
else
    END_PNG="./assets/end-screen-300ppi.png"
fi

# Listing will fail if a file doesn't exist, and the script will quit because of the -e flag.
ls "$TITLE_TYP" "$READING_VIDEO" > /dev/null

# Create symlink to typst template's assets folder.
if [ ! -L "./assets" ]; then
    ln -s /home/gambhiro/prods/sites/pali-sutta-readings-project/pali-sutta-readings.github.io-source/scripts/assets ./assets
fi

ls "$END_PNG" > /dev/null

# Test is reading video is 1920x1080 resolution.
resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$READING_VIDEO")
# 1280x720
# 1366x768
# 1920x1080

if [ $? -ne 0 ]; then
    echo "Error: Could not determine resolution"
    exit 1
fi

# NOTE: Some videos are 1364, not 1366 ??

if [ "$resolution" != "1920x1080" -a "$resolution" != "1366x768" -a "$resolution" != "1364x768" -a "$resolution" != "1280x720" ]; then
    echo "Reading video is $resolution"
    echo "Error: Reading video must be 1920x1080 or 1366x768 resolution."
    exit 2
fi

res_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "$READING_VIDEO")

typst compile --ppi 300 --format png "$TITLE_TYP" title-300ppi.png

magick title-300ppi.png -resize "$res_width"x title_1.png
magick "$END_PNG" -resize "$res_width"x end_1.png

# Case: 1364x768
# Pad the image with black
magick title_1.png -resize "$resolution" -background black -gravity center -extent "$resolution" title.png
magick end_1.png -resize "$resolution" -background black -gravity center -extent "$resolution" end.png

rm title-300ppi.png
rm title_1.png
rm end_1.png

# Extract the first keyframe (iframe) from the reading video.
ffmpeg -y \
    -i "$READING_VIDEO" \
    -vf "select=eq(pict_type\,I)" \
    -frames:v 1 \
    first.png

# Extract the last keyframe.
# https://stackoverflow.com/a/61801943
ffmpeg -y -sseof -3 \
    -i "$READING_VIDEO" \
    -vsync "passthrough" \
    -q:v 31 \
    -update true \
    last.png

# Use the reading video's audio encoding, e.g. aac or vorbis.
# -of csv=p=0: Outputs in plain format.
audio_enc=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$READING_VIDEO")
# 'vorbis' is used as 'libvorbis'
if [[ "$audio_enc" == "vorbis" ]]; then
    audio_enc="libvorbis"
fi

# Generate a 4sec title-fade video:
# 3sec title image, 1sec cross-fade to reading keyframe
# 30fps (same as the reading recording)
ffmpeg -y \
    -loop 1 -t 4 \
    -i title.png \
    -loop 1 -t 1 \
    -i first.png \
    -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=3,format=yuv420p" \
    -r 30 \
    title-fade-video-only.mkv

# Add a silent audio stream
ffmpeg -y -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -i title-fade-video-only.mkv \
    -c:v copy \
    -c:a "$audio_enc" \
    -shortest \
    title-fade.mkv

ffmpeg -y \
    -loop 1 -t 1 \
    -i last.png \
    -loop 1 -t 10 \
    -i end.png \
    -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=0,format=yuv420p" \
    -r 30 \
    end-fade-video-only.mkv

ffmpeg -y -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -i end-fade-video-only.mkv \
    -c:v copy \
    -c:a "$audio_enc" \
    -shortest \
    end-fade.mkv

# Concatenate
name=$(basename "$READING_VIDEO")
echo -e "file 'title-fade.mkv'\nfile '$name'\nfile 'end-fade.mkv'" > filelist.txt

# movflags +faststart: Optimizes the file for streaming by moving metadata to the start.

ffmpeg -y -f concat -i filelist.txt -c copy -movflags +faststart output.mkv

# With re-encoding:
# -crf 18: Controls quality (lower = better, 18 is visually lossless).

# ffmpeg -y -f concat -safe 0 -i filelist.txt \
#     -c:v libx264 \
#     -preset slow \
#     -crf 18 \
#     -c:a "$audio_enc" \
#     -movflags +faststart \
#     -r 30 \
#     output.mkv

# Clean up
rm \
    filelist.txt \
    title-fade-video-only.mkv \
    title-fade.mkv \
    end-fade-video-only.mkv \
    end-fade.mkv \
    first.png \
    last.png

