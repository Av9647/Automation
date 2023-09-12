
import openpyxl
import pandas as pd
from datetime import datetime, timedelta
from pytube import Playlist, YouTube

# Define the YouTube playlist URLs
video_playlist_url = 'https://www.youtube.com/playlist?list=PLNBplMUUl_RYETaQnZ76diljSh5Io04Bt'
music_playlist_url = 'https://www.youtube.com/playlist?list=PLNBplMUUl_RZOJUc6XFnRbQw0NaVuJ9n2'

# Create Playlist objects for video and music playlists
video_playlist = Playlist(video_playlist_url)
music_playlist = Playlist(music_playlist_url)

# Create an empty list to store video and music data
video_data = []
music_data = []

# Function to format the length of videos
def format_length(length):
    seconds = timedelta(seconds=length)
    hours = seconds // timedelta(hours=1)
    minutes = (seconds % timedelta(hours=1)) // timedelta(minutes=1)
    seconds = (seconds % timedelta(minutes=1)).seconds
    if hours > 0:
        return f'{hours} hour {minutes} min {seconds} sec'
    elif minutes > 0:
        return f'{minutes} min {seconds} sec'
    else:
        return f'{seconds} sec'

# Function to extract video data
def extract_video_data(video_url):
    video = YouTube(video_url, use_oauth=True, allow_oauth_cache=True)
    date_published = video.publish_date.date()
    channel_name = video.author
    video_title = video.title
    length = format_length(video.length)
    return {'Date published': date_published,
            'Channel Name': channel_name,
            'Video Title': video_title,
            'Length': length}

# Extract video data from video playlist
for video_url in video_playlist.video_urls:
    video_data.append(extract_video_data(video_url))

# Extract video data from music playlist
for video_url in music_playlist.video_urls:
    music_data.append(extract_video_data(video_url))

# Create a DataFrame for video data
video_data = pd.DataFrame(video_data)

# Convert 'Date published' column to datetime type
video_data['Date published'] = pd.to_datetime(video_data['Date published'])

# Sort the video data by 'Date published' in descending order
video_data = video_data.sort_values(by='Date published', ascending=False)

# Format 'Date published' column as desired
video_data['Date published'] = video_data['Date published'].dt.strftime('%d-%m-%Y')

# Generate the date string in the desired format
date_string = datetime.now().strftime("%d-%m-%Y")

# Concatenate the date to the filename for video data
video_excel_file_path = f'E:\\Python\\archive_07_sync_to_drive\\data\\video_data_{date_string}.xlsx'

# Save the video data to an Excel file
video_data.to_excel(video_excel_file_path, index=False)

print(f"Video data saved to {video_excel_file_path}")

# Create a DataFrame for music data
music_data = pd.DataFrame(music_data)

# Convert 'Date published' column to datetime type
music_data['Date published'] = pd.to_datetime(music_data['Date published'])

# Sort the music data by 'Date published' in descending order
music_data = music_data.sort_values(by='Date published', ascending=False)

# Format 'Date published' column as desired
music_data['Date published'] = music_data['Date published'].dt.strftime('%d-%m-%Y')

# Concatenate the date to the filename for music data
music_excel_file_path = f'E:\\Python\\archive_07_sync_to_drive\\data\\music_data_{date_string}.xlsx'

# Save the music data to an Excel file
music_data.to_excel(music_excel_file_path, index=False)

print(f"Music data saved to {music_excel_file_path}")

# Auto-adjusting width of columns for video data
video_wb = openpyxl.load_workbook(video_excel_file_path)
video_ws = video_wb.active

for column_cells in video_ws.columns:
    length = max(len(str(cell.value)) for cell in column_cells)
    video_ws.column_dimensions[column_cells[0].column_letter].width = length

# Saving the updated video workbook
video_wb.save(filename=video_excel_file_path)

# Auto-adjusting width of columns for music data
music_wb = openpyxl.load_workbook(music_excel_file_path)
music_ws = music_wb.active

for column_cells in music_ws.columns:
    length = max(len(str(cell.value)) for cell in column_cells)
    music_ws.column_dimensions[column_cells[0].column_letter].width = length

# Saving the updated music workbook
music_wb.save(filename=music_excel_file_path)
