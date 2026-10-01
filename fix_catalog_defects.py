import os

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

catalog_defects_code = '''
  Widget _buildCatalogDefects(Color textColor) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedDefects.isNotEmpty)
          Column(
            key: const Key('dvir_defect_cards'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in _selectedDefects)
                DefectCard(
                  key: Key('dvir_defect_card_\'),
                  defect: d,
                  textColor: textColor,
                  readOnly: _readOnly,
                  onRemove: () {
                    setState(() {
                      _selectedDefects = _selectedDefects.where((x) => x != d).toList();
                      if (_selectedDefects.isEmpty) {
                        _selectedStatus = 'Vehicle Condition Satisfactory';
                      }
                    });
                  },
                ),
            ],
          ),
        if (!_readOnly)
          TextButton.icon(
            onPressed: _openDefectCatalog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              loc.addDefects,
              style: context.styles.body.copyWith(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
'''
content = content[:-2] + catalog_defects_code
with open(source_file, 'w', encoding='utf-8') as f:
    f.write(content)
print('Restored _buildCatalogDefects.')
