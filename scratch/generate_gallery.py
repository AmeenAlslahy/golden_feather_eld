import os

files = [f for f in os.listdir('دليل التصميم') if f.endswith('.jpg')]
html = '<html><head><style>img { max-width: 300px; margin: 10px; border: 1px solid #ccc; }</style></head><body>'
for f in files:
    html += f'<div><h3>{f}</h3><img src="../دليل التصميم/{f}"></div>\n'
html += '</body></html>'

with open('scratch/gallery.html', 'w', encoding='utf-8') as f:
    f.write(html)
