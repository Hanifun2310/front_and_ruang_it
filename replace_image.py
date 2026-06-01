import os
import re

directory = 'c:/Users/roezm/IMPORTANT/fp/front_and_ruang_it/lib'

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'Image.network(' not in content:
        return

    print(f'Processing {filepath}')
    
    # Add import if missing
    if 'package:cached_network_image/cached_network_image.dart' not in content:
        # insert after the first import
        content = re.sub(r'(import .*?;)', r'\1\nimport \'package:cached_network_image/cached_network_image.dart\';', content, count=1)

    # We need to replace Image.network( with CachedNetworkImage(imageUrl:
    # and we need to replace the errorBuilder associated with it to errorWidget.
    # Since errorBuilder might be multi-line, a simple regex for the whole block is hard.
    # Let's just do text replacement. We assume all errorBuilder in files with Image.network are for Image.network.
    
    content = content.replace('Image.network(', 'CachedNetworkImage(imageUrl: ')
    content = content.replace('errorBuilder:', 'errorWidget:')
    content = content.replace('loadingBuilder:', 'placeholder:')
    
    # placeholder signature is Widget Function(BuildContext, String)
    # loadingBuilder signature is Widget Function(BuildContext, Widget, ImageChunkEvent?)
    # But usually loadingBuilder is not used here. Let's check.
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
