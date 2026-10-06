#!/usr/bin/env python3
import csv, json, sys
from pathlib import Path
src=Path(sys.argv[1] if len(sys.argv)>1 else 'artifacts/telemetry/events.jsonl')
out=src.parent
rows=[]
if src.exists():
    for line in src.read_text(encoding='utf-8').splitlines():
        if line.strip(): rows.append(json.loads(line))
summary={
    'eventCount':len(rows),
    'passed':sum(r.get('status')=='passed' for r in rows),
    'failed':sum(r.get('status')=='failed' for r in rows),
    'totalDurationSeconds':sum(int(r.get('durationSeconds',0)) for r in rows),
    'events':rows,
}
(out/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
with open(out/'events.csv','w',newline='',encoding='utf-8') as f:
    cols=['releaseId','targetOrgAlias','step','status','exitCode','durationSeconds','startUtc','endUtc']
    w=csv.DictWriter(f,fieldnames=cols); w.writeheader()
    for r in rows: w.writerow({k:r.get(k) for k in cols})
print(json.dumps(summary,indent=2))
