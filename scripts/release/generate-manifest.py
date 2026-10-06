#!/usr/bin/env python3
import datetime, hashlib, json, os, subprocess
from pathlib import Path

def env(name, default=None): return os.getenv(name, default)
def read(path):
    p=Path(path)
    return p.read_text(encoding='utf-8').strip() if p.exists() else None
def sha256(path):
    p=Path(path)
    if not p.exists() or not p.is_file(): return None
    h=hashlib.sha256(); h.update(p.read_bytes()); return h.hexdigest()

def git(*args):
    try: return subprocess.check_output(['git',*args],text=True,stderr=subprocess.DEVNULL).strip()
    except Exception: return None

out=Path(env('RELEASE_MANIFEST_PATH','artifacts/release/release-manifest.json'))
out.parent.mkdir(parents=True,exist_ok=True)
package_id=read(env('PACKAGE_ID_FILE','artifacts/package/package-id.txt'))
version_id=read(env('PACKAGE_VERSION_ID_FILE','artifacts/package/package-version-id.txt'))
verify_file=Path(env('PRODUCTION_VERIFY_FILE','artifacts/post-deploy/production/verification-summary.json'))
verify=json.loads(verify_file.read_text(encoding='utf-8')) if verify_file.exists() else None
manifest={
  'schemaVersion':'1.0',
  'releaseId':env('RELEASE_ID') or env('BUILD_BUILDNUMBER') or f"manual-{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
  'generatedAtUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'git':{
    'commit':env('BUILD_SOURCEVERSION') or git('rev-parse','HEAD'),
    'branch':env('BUILD_SOURCEBRANCH') or git('rev-parse','--abbrev-ref','HEAD'),
  },
  'azureDevOps':{
    'buildId':env('BUILD_BUILDID'),
    'buildNumber':env('BUILD_BUILDNUMBER'),
    'definition':env('BUILD_DEFINITIONNAME'),
  },
  'package':{
    'name':env('PACKAGE_NAME','CaseEscalationCore'),
    'packageId':package_id,
    'subscriberPackageVersionId':version_id,
  },
  'delta':{
    'fromRef':env('DELTA_FROM_REF'),
    'toRef':env('DELTA_TO_REF'),
    'changesManifestSha256':sha256('artifacts/delta/changes.manifest.json'),
  },
  'verification':verify,
  'rollback':{
    'snapshotPath':read('artifacts/rollback/latest-path.txt'),
    'strategy':'feature-disable + unpackaged restore + package roll-forward',
  },
  'evidence':{
    'telemetrySummarySha256':sha256('artifacts/telemetry/summary.json'),
    'codeAnalyzerSarifSha256':sha256('artifacts/code-analyzer/results.sarif'),
  },
}
out.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(manifest,indent=2))
