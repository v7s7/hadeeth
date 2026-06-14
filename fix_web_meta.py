#!/usr/bin/env python3
"""Run this AFTER: flutter create . --platforms=web
Updates web/index.html with correct Arabic title and green theme color."""

import re, sys, os

path = os.path.join(os.path.dirname(__file__), 'web', 'index.html')
if not os.path.exists(path):
    print("web/index.html not found. Run 'flutter create . --platforms=web' first.")
    sys.exit(1)

html = open(path).read()

# Set <title>
html = re.sub(r'<title>.*?</title>', '<title>الحديث المهجور</title>', html)

# Set meta theme-color
if 'name="theme-color"' in html:
    html = re.sub(r'(<meta name="theme-color" content=")[^"]*(")', r'\g<1>#1F6F5C\2', html)
else:
    html = html.replace('</head>', '  <meta name="theme-color" content="#1F6F5C">\n</head>')

# Set apple-mobile-web-app-title if present
html = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*(")', r'\g<1>الحديث المهجور\2', html)

open(path, 'w').write(html)
print("✓ web/index.html updated with Arabic title and green theme color.")
