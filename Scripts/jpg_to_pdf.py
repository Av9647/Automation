
import os
from PIL import Image

image_path = r'C:\Users\Anagha Vinod\Downloads\jpg2pdf'

for filename in os.listdir(image_path):
    if (filename.endswith((".jpg",".JPG",".png",".PNG"))):
        actual_filename = filename[:-4]
        image_1 = Image.open(r'{0}\{1}'.format(image_path, filename))
        im_1 = image_1.convert('RGB')
        im_1.save(r'{0}\{1}.pdf'.format(image_path, actual_filename))
    else:
        continue
        
for filename in os.listdir(image_path):
    if (filename.endswith((".jpg",".JPG",".png",".PNG"))):
        os.remove(os.path.join(image_path, filename))
    else:
        continue
