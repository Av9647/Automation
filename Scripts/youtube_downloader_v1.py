
# youtube_downloader.py downloads video and audio tracks from a given playlist within same directory.

# Requires FFmpeg and MKVToolNix on desktop.

# 1. Run in cmd : 
# pip install pytube --no-cache-dir

# 2. Code in .bat file :
# ::Requires MKVToolNix to be installed. Specify path of mkvmerge.exe
# :.mp4 and .m4a files having same names get merged to .mkv
# for %%a in (*.mp4) do "C:\Program Files\MKVToolNix\mkvmerge.exe" --ui-language en --output ^"%cd%\%%~na.mkv^" --language 0:und ^"^(^" ^"%cd%\%%~na.mp4^" ^"^)^" --language 0:en ^"^(^" ^"%cd%\%%~na.m4a^" ^"^)^" --track-order 0:0,1:0

# 3. Ensure youtube playlist has Public access

# 4. Specify correct values for variables - bat_path, vid_path, playlist_url

import os, ffmpy, shutil, subprocess
from pytube import Playlist, YouTube, exceptions

audio_path = r'C:\Users\Anagha Vinod\Documents\Audio'
destination = r'C:\Users\Anagha Vinod\Documents'
playlist_url = 'https://www.youtube.com/playlist?list=PLNBplMUUl_RaDrtuzEg2ExL8_ynbYwT5V'

if not os.path.exists(audio_path):
    os.makedirs(audio_path)

p = Playlist(playlist_url)

for url in p.video_urls:
    try:
        yt = YouTube(url, use_oauth=True, allow_oauth_cache=True)
    except exceptions.VideoUnavailable:
        print(f'Video {yt.title} is unavailable, skipping..')
    else:
        print(f'Downloading video: {yt.title}')
        yt.streams.filter(adaptive=True,file_extension='mp4',type='video',res='1080p').first().download(output_path=destination)
        print(f'Downloading audio: {yt.title}')
        yt.streams.filter(adaptive=True,file_extension='mp4',type='audio',abr='128kbps').first().download(output_path=audio_path)

for filename in os.listdir(audio_path):
    if (filename.endswith(".mp4")):
        actual_filename = filename[:-4]
        os.system('ffmpeg -i "{0}\{1}" -vn -c:a copy "{0}\{2}.m4a"'.format(audio_path, filename, actual_filename))
    else:
        continue

for filename in os.listdir(audio_path):
    if (filename.endswith(".m4a")):
        shutil.copyfile(os.path.join(audio_path, filename), os.path.join(destination, filename))
    else:
        continue

shutil.rmtree(audio_path)

os.chdir(destination)
subprocess.run("mkv_batch_merge.bat")

for filename in os.listdir(destination):
    if (filename.endswith((".mp4",".m4a"))):
        os.remove(os.path.join(destination, filename))
    else:
        continue
