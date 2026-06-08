#!/bin/bash
# Bjørn Falkenberg en BD; imagen subida como Bjørn Ena.png
src="/opt/eternalxi/players/Bjørn Ena.png"
dst="/opt/eternalxi/players/Bjørn Falkenberg.png"
if [ -f "$src" ] && [ ! -f "$dst" ]; then
  cp "$src" "$dst"
  echo "Copied Bjorn image to Bjørn Falkenberg.png"
elif [ -f "$dst" ]; then
  echo "Already exists: Bjørn Falkenberg.png"
else
  echo "Missing source: $src"
fi
