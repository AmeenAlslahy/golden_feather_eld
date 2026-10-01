with open('lib/features/dvir/presentation/pages/dvir_form_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_line = 292  # 0-indexed = line 293
end_line = 344    # 0-indexed = line 345 (inclusive)

replacement = [
    '      final reviewed = await showDialog<bool>(\n',
    '        context: context,\n',
    '        builder: (context) => PreviousDvirReviewModal(\n',
    '          latest: latest,\n',
    '          previousDefects: previousDefects,\n',
    '        ),\n',
    '      );\n',
]

new_lines = lines[:start_line] + replacement + lines[end_line:]
with open('lib/features/dvir/presentation/pages/dvir_form_page.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Done, new length:', len(new_lines))
