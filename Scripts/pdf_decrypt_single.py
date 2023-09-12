
import os
from PyPDF2 import PdfFileWriter, PdfFileReader

pdf_path = r'C:\Users\Anagha Vinod\Downloads\jpg2pdf'
password = "1819009@02111996"

for filename in os.listdir(pdf_path):
    file = PdfFileReader(r'{0}/{1}'.format(pdf_path, filename), 'rb')
    if file.isEncrypted:
        out = PdfFileWriter()
        file.decrypt(password)
        for idx in range(file.numPages):
            page = file.getPage(idx)
            out.addPage(page)
        with open(r'{0}/{1}'.format(pdf_path, filename), "wb") as f:
            out.write(f)
            print(r"{0} file decrypted successfully.".format(filename))           
    else:
        print("File already decrypted.")
