import os
import re

def fix_project(directory):
    # Regex to find widget constructors that should be const but lost it
    # These are classes that extend StatelessWidget/ConsumerWidget/StatefulWidget and have a constructor starting with Name({
    # We'll use a broad approach for common widgets first.
    
    widget_files = [
        'lib/widgets/gold_app_bar.dart',
        'lib/widgets/gold_button.dart',
        'lib/widgets/gold_card.dart',
        'lib/widgets/gold_text_field.dart',
        'lib/widgets/shimmer_loader.dart',
        'lib/widgets/status_badge.dart',
        'lib/features/home/screens/home_screen.dart',
        'lib/features/product/screens/catalog_screen.dart',
        'lib/features/auth/screens/login_screen.dart',
        'lib/features/auth/screens/otp_screen.dart',
    ]
    
    for relative_path in widget_files:
        path = os.path.join(os.getcwd(), relative_path)
        if not os.path.exists(path): continue
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Restore const to class constructors: Name({ ... })
        # Match class name from the file and then look for constructor
        class_match = re.search(r'class\s+([A-Z][a-zA-Z0-9]*)', content)
        if class_match:
            class_name = class_match.group(1)
            def_pattern = re.compile(fr'(^|\s)({class_name})\s*\({{', re.MULTILINE)
            content = def_pattern.sub(r'\1const \2({', content)
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Restored const to constructor: {class_name}")

    # Now remove const from CALL SITES using AppColors.
    # A call site is usually 'const Name(' but crucially NOT followed by '{' (which is a definition)
    # Actually, call sites are just 'const ' followed by Name and parentheses.
    # We will use the same regex but ensure it's not a definition.
    
    call_site_pattern = re.compile(r'const\s+([A-Z][a-zA-Z0-9]*)\((.*?AppColors\..*?)\)', re.DOTALL)
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = call_site_pattern.sub(r'\1(\2)', content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed call sites in: {path}")

if __name__ == "__main__":
    fix_project('lib')
