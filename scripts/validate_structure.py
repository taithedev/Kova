from pathlib import Path
root=Path(__file__).resolve().parents[1]
required=['Package.swift','xtool.yml','Assets/AppIcon.png','Sources/Kova/App/KovaApp.swift','Sources/Kova/Core/Network/APIClient.swift','backend/package.json','database/migrations/001_initial.sql']
for rel in required:
    assert (root/rel).is_file(), f'Missing: {rel}'
assert len(list(root.rglob('*.swift')))>=35
assert len([p for p in root.rglob('*') if p.is_dir()])>=20
print('Kova structure validated:',len(list(root.rglob('*.swift'))),'Swift source files')
