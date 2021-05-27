#!/bin/bash

audio_channels=2
audio_samplerate=48000
audio_bitrate=40000
async_ms=700
highpass=1
lowpass=3500
vheight=720
vwidth=1280
rotation=0
exposure=nightpreview
timeformat="%c"
pitube_dir=$PWD
picam_dir=$HOME/picam
pidfile=$pitube_dir/stream.pid

echo $$ > $pidfile

[ ! -d ffmpeg-logs ] && mkdir $PWD/ffmpeg-logs

if [ -z "$1" ];
  then
    echo "Usage: first argument must be the key found in your Youtube Classic Studio"
    exit 0
fi

cancelled() {
  touch $picam_dir/hooks/stop_record
  pkill ffmpeg; pkill picam
  echo "Beendet um $(date). Gelaufen fuer $SECONDS Sekunden." >> $pitube_dir/zeit.log
  rm $pidfile
  exit 0
}

error() {
  echo "Fehler auf Zeile $LINENO. Datum: $(date)" > $pitube_dir/error.log
}

trap cancelled EXIT
trap error ERR

if [ -d /run/shm ]; then
  $picam_dir/make_dirs.sh
fi

FFREPORT=file="$pitube_dir/ffmpeg-logs/ffreport-$(date +%m-%d-%y---%H-%m).log":level=32 ffmpeg \
  -re \
  -i tcp:127.0.0.1:8181?listen \
  -f:a "aresample=async=$async_ms,
        highpass=f=$highpass, lowpass=f=$lowpass,
        afftdn=nt=v|w" \
  -c:a aac \
  -c:v copy \
  -f flv rtmp://a.rtmp.youtube.com/live2/$1 &

$picam_dir/picam \
  --alsadev plughw:1,0 \
   -c $audio_channels \
   -r $audio_samplerate \
   -a $audio_bitrate \
  --rotation $rotation \
  --time \
  --timeformat "$timeformat" \
  --hflip \
  --vflip \
   -w $vwidth \
   -h $vheight \
  --ex $exposure \
  --tcpout tcp://127.0.0.1:8181

touch $picam_dir/hooks/start_record

