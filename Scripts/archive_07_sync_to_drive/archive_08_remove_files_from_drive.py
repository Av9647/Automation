
import os
import datetime
from pydrive.auth import GoogleAuth
from pydrive.drive import GoogleDrive

# Get the absolute path of the directory containing the script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Change the current working directory to the script's directory
os.chdir(script_dir)

# Authenticate with Google Drive API
gauth = GoogleAuth()
drive = GoogleDrive(gauth)

# Define the ID of the folder where you want to delete files
folder_id = "105mfnSPUknE_hKyviB8W-I8untHJNBwz"

file_list = drive.ListFile({'q': f"'{folder_id}' in parents and trashed=false"}).GetList()

# Get the local timezone offset
local_timezone_offset = datetime.datetime.now(datetime.timezone.utc).astimezone().utcoffset()

# Average seconds in a month
average_seconds_in_month = 30 * 24 * 60 * 60

# Iterate over each file and calculate the seconds passed
for file in file_list:

    # Retrieve the created date
    created_date_str = file['createdDate']
    created_date = datetime.datetime.strptime(created_date_str, "%Y-%m-%dT%H:%M:%S.%fZ") + local_timezone_offset

    # Calculate the seconds passed since the created date
    seconds_passed = (datetime.datetime.now() - created_date).total_seconds()

    # print(f"Seconds passed: {seconds_passed}")

    # Deleting files older than a month
    if int(seconds_passed/average_seconds_in_month) > 1:

        # Delete the file
        file.Delete()
