#!/bin/bash
# Rål Ena en BD; imagen subida como Bjørn Ena.png
src="/opt/eternalxi/players/Bjørn Ena.png"
dst="/opt/eternalxi/players/Rål Ena.png"
if [ -f "$src" ] && [ ! -f "$dst" ]; then
  cp "$src" "$dst"
  echo "Copied Bjorn image to Rål Ena.png"
elif [ -f "$dst" ]; then
  echo "Already exists: Rål Ena.png"
else
  echo "Missing source: $src"
fi
