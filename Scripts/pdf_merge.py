
import os
from PyPDF2 import PdfWriter, PdfReader

out = PdfWriter()

pdf_path = r'C:\Users\athul\Downloads\jpg2pdf'

for filename in os.listdir(pdf_path):
    file = PdfReader(r'{0}/{1}'.format(pdf_path, filename), 'rb')
    for idx in range(len(file.pages)):
        page = file.pages[idx]
        out.add_page(page)
    with open(r'{0}/{1}.pdf'.format(pdf_path, "temp"), "wb") as f:
        out.write(f)
        print(r"{0} file merged successfully.".format(filename))           
