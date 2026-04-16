import os
import re

target_dir = r"c:\Users\LENOVO\Crop-APP\lib"
changes = 0

for root, dirs, files in os.walk(target_dir):
    for f in files:
        if f.endswith('.dart'):
            filepath = os.path.join(root, f)
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # Replace .withOpacity(x) with .withValues(alpha: x)
            new_content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                changes += 1

print(f"Replaced withOpacity in {changes} files.")
