import os

filepath = 'd:/Flutter projects/golden_feather_eld/lib/routes.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = lines[:234]

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
