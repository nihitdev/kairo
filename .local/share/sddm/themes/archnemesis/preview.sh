#!/usr/bin/env bash
set -euo pipefail
theme_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec sddm-greeter-qt6 --test-mode --theme "$theme_dir"
