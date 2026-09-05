#!/usr/bin/env bash
# Downloads the pinned Flutter Linux SDK used by the prozedia-app Vercel git
# build. Keep the version in sync with the local Flutter in math_app/
# (check: flutter --version). Runs in the Vercel build container at the
# project root directory (math_app/).
set -euo pipefail

FLUTTER_ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.35.1-stable.tar.xz"

curl -fsSL "$FLUTTER_ARCHIVE_URL" -o .vercel_flutter.tar.xz
mkdir -p .vercel_flutter
tar -xJf .vercel_flutter.tar.xz -C .vercel_flutter --strip-components=1
rm .vercel_flutter.tar.xz

.vercel_flutter/bin/flutter config --no-analytics >/dev/null
.vercel_flutter/bin/flutter --version
