#!/bin/sh

# Help text
usage="$(basename "$0") -w -f -i -o -s -h -- Convert videos to GIFs

where:
    -w width
    -f framerate
    -i input file (required)
    -o output file
    -s target size
    -h help"

# Size calc function
function videosize {
    duration=$(ffmpeg -i $input 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,// | sed 's@\..*@@g' | awk '{ split($1, A, ":"); split(A[3], B, "."); print 3600*A[1] + 60*A[2] + B[1] }')
    bitrate=$((filesize / duration))
    echo $bitrate
}

# Defining defaults
fps=15
scale=200
output=converted_video.gif

# Options tree
while getopts ':h:w:f:i:o:s:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    w) scale=$OPTARG
       ;;
    f) fps=$OPTARG
       ;;
    i) input=$OPTARG
        filename=$(basename "$input")
        output="${filename%.*}.gif"

       ;;
    o) output=$OPTARG
       ;;
    s) filesize=$OPTARG
       targetsize=$(videosize $filesize)
       echo $targetsize
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

# Conversion function
function convert {
    palette="/tmp/palette.png"

    filters="fps=10,scale=$scale:-1:flags=lanczos"

    ffmpeg -v warning -i $input -vf "$filters,palettegen" -y $palette

    if [ -n "$targetsize" ]; then
        echo "\n with bitrate"
        ffmpeg -v warning -i $input -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -b:v 125k -pass 1 -y -f mp4 /dev/null && \
        ffmpeg -v warning -i $input -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -b:v 125k -pass 2 -y $output
    else
        ffmpeg -v warning -i $input -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $output
    fi
}

exec 3>&1;
input=$(dialog --title "Magic gif maker" --backtitle "Import any file supported by ffmpeg and convert it into a gif" --inputbox "Enter filename or drag and drop file" 8 50 2>&1 1>&3);
exitcode=$?;
exec 3>&-;
echo $result $exitcode;

convert
