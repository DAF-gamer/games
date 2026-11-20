#!/bin/bash
# Copies the latest Prop Pilot and High Command into this repo and pushes.
# Cloudflare Pages redeploys fightscramble.com automatically after each push.
set -euo pipefail
cd "$(dirname "$0")"
SRC=".."
# Rebuild Prop Pilot if its source was edited since the last build.
if [ "$SRC/flight_sim/prop_pilot.src.html" -nt "$SRC/flight_sim/prop_pilot.html" ]; then
  perl "$SRC/flight_sim/build.pl"
fi
cp "$SRC/flight_sim/prop_pilot.html" prop-pilot.html
cp "$SRC/war_sim/high_command.html" high-command.html
git add -A
if git diff --cached --quiet; then echo "No changes to publish."; exit 0; fi
git commit -qm "Update games $(date '+%Y-%m-%d %H:%M')"
git push -q -u origin main
echo "Pushed. Cloudflare will redeploy fightscramble.com in about a minute."
