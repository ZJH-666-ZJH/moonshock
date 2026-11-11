#!/usr/bin/env python3
"""Reproducible conservative production MoonBit inventory (no examples/tests)."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
rows=[]
for path in sorted(root.glob('*.mbt')):
    if 'test' in path.name:continue
    lines=path.read_text(encoding='utf-8').splitlines()
    substantive=[line for line in lines if line.strip() and not line.lstrip().startswith(('//','pub extend '))]
    rows.append({'file':path.name,'physical':len(lines),'nonblank_noncomment_without_extensions':len(substantive)})
result={'files':rows,'physical':sum(x['physical'] for x in rows),'conservative':sum(x['nonblank_noncomment_without_extensions'] for x in rows)}
print(json.dumps(result,ensure_ascii=False,indent=2))
assert result['conservative']>=1500
