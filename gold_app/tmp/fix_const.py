import os
import re

def fix_const_errors(directory):
    # Regex to find 'const WidgetName(' and check if it contains 'AppColors.' before the closing parenthesis
    # We'll use a simpler approach: any line containing 'const ' and 'AppColors.' 
    # will have 'const ' removed prefixing a word.
    
    pattern = re.compile(r'const\s+([A-Z][a-zA-Z0-9]*)\((.*?AppColors\..*?)\)', re.DOTALL)
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern.sub(r'\1(\2)', content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed: {path}")

if __name__ == "__main__":
    fix_const_errors('lib')
