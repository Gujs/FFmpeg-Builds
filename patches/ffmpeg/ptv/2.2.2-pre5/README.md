# ptvencoder 2.2.2-pre5

**Pre-release (dev) = 2.2.2-pre4 + every hold's return is classified (T-502) + a dropped silence-fill frame moves the fill
on (T-505).** Source: `adaptive-2.2` @ `e608602538` (tag `ptv-2.2.2-pre5`, Gujs/FFmpeg). Eight patches for FFmpeg
`master`, applied in order; `0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1..pre4, `0001` carries the change. `dev`
set; `stable` stays 2.2.1.

**What changes (vs pre4):** the last two 2.2.2 blockers, both old intermittents (2.2.1 has them too), both root-caused by
measurement under load (8 instances at once: pre4 T-502 12 of 24 runs FAIL, T-505 6 of 24).
- **T-502 — the rejoin classifier is armed for every hold.** It was re-armed only by a video packet read while the source
  was LIVE; a ~1 s return ends its hold as its last picture is read, so the next hold's return was never classified, the
  audio waited for the class with its frames buffered (the hold fill had stopped) and the 4 s cap released them: the audio
  PID dark 4.1 s (`blip1000/sync_blip_20`). A class now belongs to one hold (re-armed when the next hold begins, as the
  audio's rejoin buffer is since T-489). Same load: 0 of 40.
- **T-505 — a dropped silence-fill frame moves the fill on.** The T-478 door snapshot was also taken for the track's own
  silence fill; when house_skew stepped back under a running fill (+240 ms -> 0) every fill frame was dropped whole and
  "restored", the fill's label never advanced. Under 10 % loss this happened on every run (the "normal" 1.2 s audio
  silence) and a second time by chance (up to 2.3 s, over the 1.5 s bar). Snapshot for real frames only: Cinestar 10 %
  loss audio silence 1.2-2.3 s -> 0.36-0.51 s, largest door drop 1386-2290 ms -> 240 ms; 0 of 40.

**Verification:**
- Full gate on 12 lanes (kit `0003cc7`, media-v44 `70e3521b7ad1`, binary = this source on the ptv-v2-2.2 tree,
  `tests/results/full-222pre5cand`): **397 keys, 395 PASS**; the 2 FAILs are the accepted SCTE-35 KNOWN keys. Against
  the pre4 baseline: 0 regressions, fixed `blip1000/sync_blip_20` + `std-cin/loss_100`. pinchk 397/397. Baseline
  `tests/results/baselines/2.2.2-pre5/70e3521b7ad1/gate`.
- New keys (kit `0c42945`): `*-cin/loss_100` PID-dark bar 1.0 s (T-505: pre4 std 1.3 s / vt 1.4 s FAIL, pre5 PASS);
  blip keys require one `rejoin class` line per hold (T-502: pre4's failing runs had 1 of 2; race-triggered, pre5 PASS).
- Neighbour subset (129 hold / rejoin / loss / storm / return keys, 10 lanes): 128 PASS + the KNOWN.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `7ddf7bc8a4` (2026-11-20):
  `2.2.2-pre5  FFmpeg N-129150-g7ddf7bc8a4`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.2-pre5);
  smoke std/clean, blip1000, std-cin/loss_100 PASS.

**Known, not in this pre:** the rejoin buffer's 4 s cap can still go dark if a class never comes (no key reaches it; a
design change), `sync_dupsend_5` audio silence bimodal 0.36 / 1.33-1.46 s (under the bar, every gate since rc7),
T-503 / T-504 / T-509 / T-510, T-511 (WildTV ~400 8 ms step-backs per hour on every 2.2.x — to classify), the listening
test of the T-499 slew.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre4. Watch: `[PTV-SRC] ... rejoin class`
once per hold return, no `frames held 4.0` lines, `[PTV-ATRIM]` sizes, SYNCCHK clean. **Rollback:** 2.2.2-pre4, or 2.2.1
(`stable`).
