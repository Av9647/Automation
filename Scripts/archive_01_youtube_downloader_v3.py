
# youtube_downloader_v3.py downloads video and audio tracks from a given playlist inside subfolders based on channel name.
# furthermore, it skips existing files within the subfolders and downloads only the files which are pending to be downloaded.
# logging is implemented.

# Requires FFmpeg and MKVToolNix on desktop.

# 1. Run in cmd : 
# pip install pytube --no-cache-dir

# 2. Code in .bat file :
# ::Requires MKVToolNix to be installed. Specify path of mkvmerge.exe
# :.mp4 and .m4a files having same names get merged to .mkv
# for %%a in (*.mp4) do "C:\Program Files\MKVToolNix\mkvmerge.exe" --ui-language en --output ^"%cd%\%%~na.mkv^" --language 0:und ^"^(^" ^"%cd%\%%~na.mp4^" ^"^)^" --language 0:en ^"^(^" ^"%cd%\%%~na.m4a^" ^"^)^" --track-order 0:0,1:0

# 3. Ensure youtube playlist has Public access

# 4. Specify correct values for variables - bat_path, vid_path, playlist_url

import os, re, shutil, subprocess
from pytube import Playlist, YouTube

import logging
# Creating log file in the same directory as of script
logging.basicConfig(filename=os.path.join(os.path.abspath(os.path.dirname(__file__)), 'youtube_downloader_v3.log'), filemode='a', level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logging.disable(logging.DEBUG)

logging.info('================================RUN STARTED================================')

# Declaring folder and file paths
bat_path = r'D:\Extra\mkv_batch_merge.bat'
vid_path = r'D:\Extra\Videos'
playlist_url = 'https://www.youtube.com/playlist?list=PLNBplMUUl_RZMKQFka29clvOud3Qxnp7S'
existing_vid = []

# Creating Videos folder if it doesn't exist
if not os.path.exists(vid_path):
    logging.info(f'Creating path - {vid_path}')
    os.makedirs(vid_path)
else:
    logging.info(f'Path - {vid_path} already exists.')

# Adding existing videos to a list
for folder, subfolders, files in os.walk(vid_path):
    if folder != vid_path:
        for file in files:
            if file.endswith(".mkv"):
                actual_filename = file[:-4]
                existing_vid.append(actual_filename)
                logging.warning(f'Video - {actual_filename} already downloaded and merged, will be skipped.')

# Creating playlist object
p = Playlist(playlist_url)

# Creating subfolders for each youtube channel then downloading video and audio stream
for url in p.video_urls:
    yt = YouTube(url, use_oauth=True, allow_oauth_cache=True)
    file_name = re.sub('[\/*?"<>|]',"", yt.title)
    file_name = re.sub(':'," -", file_name)
    subfolder = yt.author
    location = os.path.join(vid_path, subfolder)

    if not os.path.exists(location):
        logging.info(f'Creating path - {location}')
        os.makedirs(location)
        
    if file_name in existing_vid:
        print(f'WARNING : Video - {yt.title} already downloaded and merged, skipping..')
    else:
        vid_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='video',res='1080p').first()
        audio_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='audio',abr='128kbps').first()
        
        if not vid_stream:
            vid_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='video',res='720p').first()
        
        if not vid_stream:
            vid_stream = yt.streams.filter(adaptive=True,file_extension='mp4',type='video',res='480p').first()

        if not vid_stream:
            print(f'ERROR : Required video stream - {yt.title} is unavailable.')
            logging.error(f'Required video stream - {yt.title} is unavailable.')
        else:
            print(f'INFO : Downloading video - {yt.title}')
            logging.info(f'Downloading video - {yt.title}')
            vid_stream.download(output_path=location, filename=file_name+".mp4")

        if not audio_stream:
            print(f'ERROR : Required audio stream - {yt.title} is unavailable.')
            logging.error(f'Required audio stream - {yt.title} is unavailable.')             
        else:
            print(f'INFO : Downloading audio - {yt.title}')
            logging.info(f'Downloading audio - {yt.title}')
            audio_stream.download(output_path=os.path.join(location, 'audio'), filename=file_name+".mp4")

# Looping through .mp4 audio files and converting them to .m4a using ffmpeg
for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):
        for file in os.listdir(level1):
            level2 = os.path.join(level1, file)
            if ('audio' in level2):
                for filename in os.listdir(level2):
                    if (filename.endswith(".mp4")):
                        actual_filename = filename[:-4]
                        os.system('ffmpeg -i "{0}\{1}" -vn -c:a copy "{2}\{3}.m4a"'.format(level2, filename, level1, actual_filename))
                        logging.info(f'Audio file - {actual_filename} converted to .m4a')
                    else:
                        continue

# Copying and running mkv_batch_merge.bat inside each youtube channel subfolder
for file in os.listdir(vid_path):
    level1 = os.path.join(vid_path, file)
    if os.path.isdir(level1):
        shutil.copyfile(bat_path, os.path.join(level1, "temp.bat"))
        os.chdir(level1)
        logging.info(f'Running temp.bat in path - {level1}')
        subprocess.run("temp.bat")

# Removing .mp4, .m4a and .bat files within each youtube channel subfolder
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

logging.info('================================RUN COMPLETED================================')
