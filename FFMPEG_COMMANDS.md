# FFmpeg Commands Reference — Quran Reels

## توليد خلفية بلون ثابت (9:16)
```bash
ffmpeg -f lavfi -i color=c=#0D1B2A:s=1080x1920:r=30:d=20 -y background.mp4
```

## دمج خلفية + نص + صوت
```bash
ffmpeg \
  -loop 1 -i background.png \
  -i text.png \
  -i audio.mp3 \
  -filter_complex "[0:v]scale=1080:1920,setsar=1[bg];[1:v]format=rgba,fade=t=in:st=0:d=1:alpha=1[text];[bg][text]overlay=x=(W-w)/2:y=(H-h)/2:format=auto" \
  -t 20 -r 30 -c:v libx264 -pix_fmt yuv420p -c:a aac -af apad -shortest -y output.mp4
```

## دمج التلاوات (Concatenate)
```bash
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy combined_audio.mp3
```

## إعادة ترميز الصوت عند الحاجة
```bash
ffmpeg -f concat -safe 0 -i concat_list.txt -c:a libmp3lame -q:a 3 combined_audio.mp3
```

## ملاحظات
- استخدم `-stream_loop -1` عند إدخال فيديو خلفية لتكراره.
- استخدم `-shortest` لإنهاء الفيديو عند أقصر مسار صوت/صورة.
