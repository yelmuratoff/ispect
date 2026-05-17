#!/usr/bin/env bash
# strip-ai-chars.sh: deterministic typographic cleanup. stdin -> stdout.
# Ported from https://github.com/Nordth/humanize-ai-lib (MIT).

set -euo pipefail

exec perl -CSDA -pe '
  # Cf format chars, C0/C1 controls, tag-character watermarks
  s/[\x{0000}-\x{0008}\x{000E}-\x{001B}\x{007F}-\x{009F}\x{00AD}\x{0600}-\x{0605}\x{061C}\x{06DD}\x{070F}\x{0890}-\x{0891}\x{08E2}\x{180E}\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{206F}\x{FEFF}\x{FFF9}-\x{FFFB}\x{110BD}\x{110CD}\x{13430}-\x{13438}\x{1BCA0}-\x{1BCA3}\x{1D173}-\x{1D17A}\x{E0001}\x{E0020}-\x{E007F}]//g;
  # decorative symbols not on any keyboard (math alnums, arrows, math ops, box/block, enclosed alnums, dingbat bullets)
  s/[\x{2190}-\x{21FF}\x{2200}-\x{22FF}\x{2400}-\x{243F}\x{2440}-\x{245F}\x{2460}-\x{24FF}\x{2500}-\x{257F}\x{2580}-\x{259F}\x{2768}-\x{27BE}\x{27C0}-\x{27EF}\x{27F0}-\x{27FF}\x{2900}-\x{297F}\x{2980}-\x{29FF}\x{2A00}-\x{2AFF}\x{2B00}-\x{2BFF}\x{1D400}-\x{1D7FF}]//g;
  s/\x{00A0}/ /g;
  s/[\x{2013}\x{2014}\x{2015}]/-/g;
  s/[\x{201C}\x{201D}\x{201E}\x{00AB}\x{00BB}]/"/g;
  s/[\x{2018}\x{2019}\x{02BC}]/\x27/g;
  s/\x{2026}/.../g;
  s/[ \t\x0B\f]+$//;
'
