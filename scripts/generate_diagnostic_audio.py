"""Generate the diagnostic voice clips with Jakob's Qwen3 voice clone.

Run from the Voice project so its environment and `voice` package are used:
  cd "C:/Users/jakob/Documents/Cursor projects/Voice"
  uv run --no-sync python "C:/Users/jakob/StudioProjects/Math_App/scripts/generate_diagnostic_audio.py"

One batch job, so the 1.7B model loads once (the same engine and German
reference `voice speak --lang de --engine qwen3` uses). Incremental:
manifest.json maps file -> spoken text; unchanged texts are skipped.
Set ONLY=1,24,55 to generate just those items (smoke runs).
"""
import csv, json, os, pathlib, subprocess, sys, tempfile

MATH_APP = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(MATH_APP / 'scripts'))
from german_numbers import spoken  # noqa: E402

from voice.jobs import Item, build_job, run_in_engine_env  # noqa: E402

VOICE_ROOT = pathlib.Path.cwd()
CSV = MATH_APP / 'math_app/Research/diagnostic_v4_master.csv'
OUT = MATH_APP / 'math_app/assets/audio/diagnostic'
SLOTS = [('Sprechtext', 'frage'), ('Hilfe1', 'hilfe1'), ('Hilfe2', 'hilfe2'), ('Hilfe3', 'hilfe3')]


def wanted() -> dict[str, str]:
    only = os.environ.get('ONLY')
    files = {}
    for r in csv.DictReader(open(CSV, encoding='utf-8')):
        if only and r['ListNumber'] not in only.split(','):
            continue
        for col, slot in SLOTS:
            text = (r.get(col) or '').strip()
            if text:
                files[f"q{r['ListNumber']}_{slot}.mp3"] = spoken(text)
    return files


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    if not (VOICE_ROOT / 'src/voice').exists():
        sys.exit('run this from the Voice project folder')
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
    want = wanted()
    todo = {f: t for f, t in want.items() if manifest.get(f) != t or not (OUT / f).exists()}
    print(f'{len(want)} clips, {len(todo)} to generate', flush=True)
    if todo:
        with tempfile.TemporaryDirectory() as tmp:
            items = [Item(id=f.removesuffix('.mp3'), text=t, lang='de') for f, t in todo.items()]
            job = build_job(engine='qwen3', items=items, dataset_dir=VOICE_ROOT / 'data/dataset',
                            checkpoint=None, out_dir=tmp)
            run_in_engine_env('qwen3', job)
            for f, t in todo.items():
                wav = pathlib.Path(tmp) / f.replace('.mp3', '.wav')
                if not wav.exists():
                    print(f'FEHLT: {f}')
                    continue
                subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(wav),
                                '-af', 'silenceremove=start_periods=1:start_threshold=-50dB,'
                                       'areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,'
                                       'loudnorm=I=-16:TP=-1.5:LRA=11',
                                '-ar', '44100', '-ac', '1', '-b:a', '64k', str(OUT / f)], check=True)
                manifest[f] = t
    if not os.environ.get('ONLY'):
        for stale in set(manifest) - set(want):
            (OUT / stale).unlink(missing_ok=True)
            manifest.pop(stale)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True), encoding='utf-8')
    print('fertig')


if __name__ == '__main__':
    main()
