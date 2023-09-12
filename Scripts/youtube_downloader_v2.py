
# youtube_downloader_v2.py downloads video and audio tracks from a given playlist inside subfolders based on channel name.

# Requires FFmpeg and MKVToolNix on desktop.

# 1. Run in cmd : 
# pip install pytube --no-cache-dir

# 2. Code in .bat file :
# ::Requires MKVToolNix to be installed. Specify path of mkvmerge.exe
# :.mp4 and .m4a files having same names get merged to .mkv
# for %%a in (*.mp4) do "C:\Program Files\MKVToolNix\mkvmerge.exe" --ui-language en --output ^"%cd%\%%~na.mkv^" --language 0:und ^"^(^" ^"%cd%\%%~na.mp4^" ^"^)^" --language 0:en ^"^(^" ^"%cd%\%%~na.m4a^" ^"^)^" --track-order 0:0,1:0

# 3. Ensure youtube playlist has Public access

# 4. Specify correct values for variables - bat_path, vid_path, playlist_url

import os, shutil, subprocess
from pytube import Playlist, YouTube, exceptions

bat_path = r'C:\Users\Anagha Vinod\Documents'
vid_path = r'C:\Users\Anagha Vinod\Documents\Videos'
playlist_url = 'https://www.youtube.com/playlist?list=PLNBplMUUl_RaDrtuzEg2ExL8_ynbYwT5V'

if not os.path.exists(vid_path):
    os.makedirs(vid_path)

p = Playlist(playlist_url)

for url in p.video_urls:
    try:
        yt = YouTube(url, use_oauth=True, allow_oauth_cache=True)
        subfolder = yt.author
        location = os.path.join(vid_path, subfolder)
        if not os.path.exists(location):
            os.makedirs(location)
    except exceptions.VideoUnavailable:
        print(f'Video {yt.title} is unavailable, skipping..')
    else:
        vid_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='video',res='1080p').first()
        audio_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='audio',abr='128kbps').first()

        if not vid_stream:
            print(f'Required video stream - {yt.title} is unavailable.')
        else:
            print(f'Downloading video - {yt.title}')
            vid_stream.download(output_path=location)

        if not audio_stream:
            print(f'Required audio stream - {yt.title} is unavailable.')         
        else:
            print(f'Downloading audio - {yt.title}')
            audio_stream.download(output_path=os.path.join(location, 'audio'))

for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):
        for file in os.listdir(level1):
            level2 = os.path.join(level1, file)
            if ('audio' in level2):
                for filename in os.listdir(level2):
                    if (filename.endswith(".mp4")):
                        actual_filename = filename[:-4]
                        os.system('ffmpeg -i "{0}\{1}" -vn -c:a copy "{0}\{2}.m4a"'.format(level2, filename, actual_filename))
                    else:
                        continue

for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):
        for file in os.listdir(level1):
            level2 = os.path.join(level1, file)
            if ('audio' in level2):
                for filename in os.listdir(level2):
                    if (filename.endswith(".m4a")):
                        shutil.copyfile(os.path.join(level2, filename), os.path.join(level1, filename))
                    else:
                        continue

for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):
        shutil.copyfile(os.path.join(bat_path, "mkv_batch_merge.bat"), os.path.join(level1, "temp.bat"))
        os.chdir(level1)
        subprocess.run("temp.bat")

for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):       
        for file in os.listdir(level1):
            level2 = os.path.join(level1, file)
            if (os.path.isdir(level2)):
                shutil.rmtree(level2)
            elif (file.endswith((".mp4",".m4a",".bat"))):
                os.remove(level2)
            else:
                continue
