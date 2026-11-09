# ptvencoder 2.2.0-rc3

Release candidate for 2.2.0 = 2.2.0-rc2 + the T-451 fix. Source: `adaptive-2.2` @ `4690a1faec` (tag `ptv-2.2.0-rc3`,
Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; only `0001` differs from rc2.

**What changed (T-451):** a source whose clock steps away and comes back (cor-3 Curiosity: PCR + PTS back 14768 s, back
2 s later) keeps its sync. rc2 ended such an output ~4 h off and sync_check restarted it. A step the input's silence does not
explain waits up to 3 s for its partner streams; a partner already more than 2 s past the crossing did not cross; a program
event's audio partner must cross by the video's amount. One deliberate change: a video-only forward PTS jump with no silence
waits ~1.9 s before it is classified (rc2: 0.2 s).

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `b2b543c079` (2026-11-09):
  `2.2.0-rc3  FFmpeg N-128718-gb2b543c079`. First verified on `0f89d936b3` (2026-11-08).
- Kit gate vs pre12: 267 runs, 262 PASS, 0 regressions; the 4 T-451 keys FAIL on rc2, PASS on rc3; smoke 36/0/0.
- Canaries (live-transcoder + cor-3) since 2026-11-09 06:53 CET: the T-451 excursion recurred on rc3 and was handled
  (output A/V +0.0 / +2.4 ms, no restart).

**Rollback:** 2.2.0-rc2 (tag `ptv-2.2.0-rc2`). It is not published under `patches/ptv/`; its set is in
`patches/v2/pre-2.2.0-rc2/`.

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh` (`SV_REGULATE`,
T-446 moving-reading rule).
