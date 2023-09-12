
import os, subprocess

application_path = r'C:\Program Files (x86)\Spek\spek.exe'
song_path = os.path.abspath(os.path.dirname(__file__))

for filename in os.listdir(song_path):
    if (filename.endswith((".flac", ".opus", ".m4a", ".mkv"))):
        subprocess.run(r'"{0}" "{1}\{2}"'.format(application_path, song_path, filename))
        print(os.path.join(application_path, song_path, filename))
    else:
        continue
