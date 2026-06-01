import os

directory = 'c:/Users/roezm/IMPORTANT/fp/front_and_ruang_it/lib'

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if '\\\'package:cached_network_image' in content:
        content = content.replace('\\\'package:cached_network_image', '\'package:cached_network_image')
        content = content.replace('.dart\\\'', '.dart\'')
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
            print(f'Fixed {filepath}')

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))
