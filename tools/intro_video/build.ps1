# Builds out/intro_video.mp4: per-scene narration in Jakob's voice, animated
# scene recorded frame by frame, muxed with ffmpeg. Rerun-safe: existing
# scene clips are reused; delete work/scene_NN.mp3 to regenerate one.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$voice = 'C:\Users\jakob\Documents\Cursor projects\Voice'
$work = Join-Path $here 'work'; New-Item -ItemType Directory -Force $work | Out-Null
$paras = (Get-Content (Join-Path $here 'narration.txt') -Raw -Encoding utf8) -split "(?:\r?\n){2,}" | Where-Object { $_.Trim() }
Push-Location $voice
try {
  for ($i = 0; $i -lt $paras.Count; $i++) {
    $txt = Join-Path $work ('scene_{0:d2}.txt' -f $i)
    $mp3 = Join-Path $work ('scene_{0:d2}.mp3' -f $i)
    if (-not (Test-Path $mp3)) {
      [IO.File]::WriteAllText($txt, $paras[$i].Trim(), [Text.UTF8Encoding]::new($false))
      uv run --no-sync voice speak $txt --lang de --engine qwen3 -o $mp3
      if ($LASTEXITCODE -ne 0) { throw "voice speak failed for scene $i" }
    }
  }
} finally { Pop-Location }

# Durations -> timeline for the animation
$durs = Get-ChildItem $work -Filter 'scene_*.mp3' | Sort-Object Name | ForEach-Object {
  [double](ffprobe -v error -show_entries format=duration -of csv=p=0 $_.FullName)
}
if ($durs.Count -ne $paras.Count) { throw "expected $($paras.Count) scene clips, found $($durs.Count)" }
$json = ConvertTo-Json @($durs) -Compress
[IO.File]::WriteAllText((Join-Path $work 'timeline.json'), $json, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $work 'timeline.js'), "window.TIMELINE = $json;", [Text.UTF8Encoding]::new($false))

Push-Location $here
# Set SKIP_RECORD=1 to reuse existing frames (only the audio/mux changed).
if (-not $env:SKIP_RECORD) {
  try { npm install --silent; node record.mjs; if ($LASTEXITCODE -ne 0) { throw 'recording failed' } } finally { Pop-Location }
} else { Pop-Location }

# Audio track: each scene clip followed by 0.6 s silence, plus 1 s tail
$sil = Join-Path $work 'sil.wav'
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=mono -t 0.6 $sil
$list = Join-Path $work 'concat.txt'
$lines = Get-ChildItem $work -Filter 'scene_*.mp3' | Sort-Object Name | ForEach-Object {
  $wav = [IO.Path]::ChangeExtension($_.FullName, '.wav')
  ffmpeg -y -loglevel error -i $_.FullName -ar 44100 -ac 1 $wav
  "file '$($wav.Replace([char]92, '/'))'"; "file '$($sil.Replace([char]92, '/'))'"
}
[IO.File]::WriteAllLines($list, $lines)
$audio = Join-Path $work 'narration_full.wav'
ffmpeg -y -loglevel error -f concat -safe 0 -i $list -c copy $audio
$outDir = Join-Path (Resolve-Path "$here\..\..") 'out'; New-Item -ItemType Directory -Force $outDir | Out-Null
$mp4 = Join-Path $outDir 'intro_video.mp4'
ffmpeg -y -loglevel error -framerate 30 -i (Join-Path $work 'frames\f%05d.png') -i $audio `
  -af apad -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 160k -shortest $mp4
Write-Host "wrote $mp4"
