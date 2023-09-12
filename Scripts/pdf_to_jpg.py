
# pip install "pypdfium2>=3,<4"

import pypdfium2 as pdfium

# Load a document
filepath = r'C:\Users\athul\Downloads\jpg2pdf\Exam 1 510 Extra Credit Fall 2022.pdf'
pdf = pdfium.PdfDocument(filepath)

# render a single page (in this case: the first one)
page = pdf.get_page(0)
pil_image = page.render_to(
    pdfium.BitmapConv.pil_image,
)
pil_image.save("output.jpg")

# render multiple pages concurrently (in this case: all)
page_indices = [i for i in range(len(pdf))]
renderer = pdf.render_to(
    pdfium.BitmapConv.pil_image,
    page_indices = page_indices,
)
for image, index in zip(renderer, page_indices):
    image.save("output_%02d.jpg" % index)
