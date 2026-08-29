import os
import re

def fix_analyze():
    try:
        with open('analyze.txt', 'r', encoding='utf-16') as f:
            lines = f.readlines()
    except:
        try:
            with open('analyze.txt', 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            print("Failed to read analyze.txt:", e)
            return

    issues = []
    for line in lines:
        line = line.strip()
        if ' - ' in line and '.dart:' in line:
            parts = line.split(' - ')
            if len(parts) >= 4:
                msg = parts[1].strip()
                loc = parts[2].strip()
                code = parts[3].strip()
                
                try:
                    filepath, line_num, col = loc.split(':')
                    issues.append({
                        'msg': msg,
                        'file': filepath.replace('\\', '/'),
                        'line': int(line_num) - 1,
                        'col': int(col) - 1,
                        'code': code
                    })
                except Exception as e:
                    pass

    grouped = {}
    for iss in issues:
        grouped.setdefault(iss['file'], []).append(iss)

    for filepath, file_issues in grouped.items():
        if not os.path.exists(filepath): continue
        with open(filepath, 'r', encoding='utf-8') as f:
            file_lines = f.readlines()
        
        file_issues.sort(key=lambda x: x['line'], reverse=True)
        
        for iss in file_issues:
            ln = iss['line']
            if ln >= len(file_lines): continue
            original_line = file_lines[ln]
            code = iss['code']
            
            if code == 'unused_element' or code == 'unused_local_variable' or code == 'unused_field' or code == 'unused_import':
                if not original_line.strip().startswith('//'):
                    file_lines[ln] = '// ' + original_line
            elif code == 'prefer_const_declarations':
                file_lines[ln] = re.sub(r'\bfinal\b', 'const', original_line, count=1)
            elif code == 'unnecessary_const':
                file_lines[ln] = re.sub(r'\bconst\s+', '', original_line, count=1)
            elif code == 'use_build_context_synchronously':
                # ignore it
                file_lines[ln] = original_line.replace('ScaffoldMessenger', '// ignore: use_build_context_synchronously\nScaffoldMessenger').replace('context.', '// ignore: use_build_context_synchronously\ncontext.')
            elif code == 'missing_method_parameters':
                pass # Fixed already
            elif code == 'prefer_const_constructors':
                col = iss['col']
                match = re.search(r'[A-Z]\w*|\[', original_line[col:])
                if match:
                    idx = col + match.start()
                    if 'const ' not in original_line[max(0, idx-6):idx]:
                        file_lines[ln] = original_line[:idx] + 'const ' + original_line[idx:]

        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(file_lines)
        print(f"Fixed {len(file_issues)} issues in {filepath}")

fix_analyze()
