
import os
from PIL import Image
import PyPDF2

image_path = r'C:\Users\Anagha Vinod\Downloads\jpg2pdf'
image_list = []

for filename in os.listdir(image_path):
    if (filename.endswith((".jpg",".JPG",".png",".PNG"))):
        actual_filename = filename[:-4]
        image_1 = Image.open(r'{0}\{1}.jpg'.format(image_path, actual_filename))
        im_1 = image_1.convert('RGB')
        image_list.append(im_1)
    else:
        continue

temp = "temp"

im_1.save(r'{0}\{1}.pdf'.format(image_path, temp), resolution=100.0, save_all=True, append_images=image_list)
        
for filename in os.listdir(image_path):
    if (filename.endswith(".jpg")):
        os.remove(os.path.join(image_path, filename))
    else:
        continue

pdf1File = open(r'{0}\{1}.pdf'.format(image_path, temp), 'rb')
reader1 = PyPDF2.PdfFileReader(pdf1File, strict=False)

writer = PyPDF2.PdfFileWriter()

for pageNum in range(1, reader1.numPages):
    page = reader1.getPage(pageNum)
    writer.addPage(page)

print("Type PDF name : ")
pdf_name = input() 

outputFile = open(r'{0}\{1}.pdf'.format(image_path, pdf_name), 'wb')
writer.write(outputFile)
outputFile.close()
pdf1File.close()

os.remove(os.path.join(image_path, temp+".pdf"))
