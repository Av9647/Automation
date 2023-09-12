
import os, re, shutil

# Declaring folder and file paths
vid_path = r'D:\Extra\Videos'
folder_sorted = ['Akshat Shrivastava', 'Animalogic', 'Aperture', 'Be Smart', 'Insider Business', 'IGN', 'Into the Shadows', 'Nucleus Medical Media', 'Think School', 'Veritasium', 'Vox', 'WIRED']
folder_sorted_yearly = ['ColdFusion', 'Kurzgesagt – In a Nutshell', 'Real Science', 'SciShow']
year = '2022'

# Performing folder and file renaming operations
for folder in os.listdir(vid_path):
    if os.path.isdir(os.path.join(vid_path, folder)):
        level1 = os.path.join(vid_path, folder)
        
        if folder in folder_sorted_yearly:
            year_path = os.path.join(level1, year)
            if not os.path.exists(year_path):
                os.makedirs(year_path)
            for file in os.listdir(level1):
                level2 = os.path.join(level1, file)
                if not os.path.isdir(level2):
                    shutil.move(level2, os.path.join(year_path, file))
                    
        if folder not in folder_sorted and folder not in folder_sorted_yearly:
            if not os.path.exists(os.path.join(vid_path, "# Extras")):
                os.makedirs(os.path.join(vid_path, "# Extras"))
            if os.path.isdir(level1):
                for file in os.listdir(level1):
                    level2 = os.path.join(level1, file)
                    shutil.move(level2, os.path.join(vid_path, "# Extras", folder + " - " + file))
                shutil.rmtree(level1)

# Replacing '–' character in files with '-'
for folder in os.listdir(vid_path):
    if os.path.isdir(os.path.join(vid_path, folder)):
        renamed_folder = re.sub('–', '-', folder)
        level1 = os.path.join(vid_path, renamed_folder)
        os.rename(os.path.join(vid_path, folder), level1)
