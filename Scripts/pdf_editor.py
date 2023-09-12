
import PyPDF2 

pdf1File = open(r'C:\Users\athul\Downloads\Unofficial Transcript SI.pdf', 'rb')
reader1 = PyPDF2.PdfReader(pdf1File, strict=False)

writer = PyPDF2.PdfWriter()

writer.add_page(reader1.pages[0])

outputFile = open(r'C:\Users\athul\Downloads\Unofficial Transcript S1.pdf', 'wb')
writer.write(outputFile)
outputFile.close()
pdf1File.close()
