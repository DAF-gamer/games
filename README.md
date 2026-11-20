# Fight Scramble games

Live at https://fightscramble.com. Cloudflare Pages deploys every push to `main`.

| Game | Edit this | Then |
|---|---|---|
| Prop Pilot | `src/prop_pilot.src.html` | `perl src/build.pl` (writes `prop-pilot.html`) |
| High Command | `high-command.html` | nothing to build |

## Update workflow
1. `git switch main && git pull` then `git switch -c feature/<name>`
2. Make the change on the feature branch and commit it (pushing the branch is fine; it doesn't deploy).
3. Test locally: `open prop-pilot.html` (or `high-command.html`).
4. Only after it has been tested: `git switch main && git merge feature/<name> && git push`. That deploys to production.
