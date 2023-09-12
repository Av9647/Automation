
import os
from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

# Get the absolute path of the directory containing the script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Change the current working directory to the script's directory
os.chdir(script_dir)

gauth = GoogleAuth()
drive = GoogleDrive(gauth)

# folder name taken from url of Google drive
folder = "105mfnSPUknE_hKyviB8W-I8untHJNBwz"

directory = r"E:\Python\archive_07_sync_to_drive\data"

# Uploading files to drive
for f in os.listdir(directory):
    filename = os.path.join(directory, f)
    gfile = drive.CreateFile({'parents' : [{'id' : folder}], 'title' : f})
    gfile.SetContentFile(filename)
    gfile.Upload()

# # Printing list of files in drive
# file_list = drive.ListFile({'q' : f"'{folder}' in parents and trashed=false"}).GetList()
# print('Files in the directory : ')
# for file in file_list:
#     print(file['title'])

# # Downloading files from drive
# file_list = drive.ListFile({'q' : f"'{folder}' in parents and trashed=false"}).GetList()
# for index, file in enumerate(file_list):
#     print('file ', index+1, ' downloaded : ', file['title'])
#     file.GetContentFile(file['title'])
