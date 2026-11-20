# ptvencoder 2.2.2-pre6

**Pre-release (dev) = 2.2.2-pre5 + the source picture period is the median step, not the shortest (T-512).** Source:
`adaptive-2.2` @ `e9b4705454` (tag `ptv-2.2.2-pre6`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order;
`0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1..pre5, `0001` carries the change. `dev` set; `stable` stays 2.2.1.

**What changes (vs pre5):**
- **T-512 — one short label step is not the picture rate.** An HLS-origin source re-stamps sound and pictures together at
  every segment join (WildTV, provider HLS -> SRT: -8 / -8 / +15.3 ms every 6 s, content contiguous). The T-413 learner
  took the shortest picture step of each 2 s window, so after a -8 ms join it read 25.4 ms for a 33.37 ms source; T-499
  then measured the picture phase on a 25.4 ms circle, and when the join also carried the picture across the half tick
  the sound stood a whole 25.4 ms from the picture with its phase term on target — clean for the post-event sync check,
  which stepped it (`[PTV-SYNCCHK] STEPPED` ±25-32 ms on cow-1 WildTV: pre3 34, pre4 6, pre5 8 in its first ~11 h; 2.2.1
  and pre2 0). The period is now the median step of the window (lost pictures, the longer steps, are ignored as before).
  Median = shortest on every kit source class except LVTV 25p, where the shortest read 39.3-39.5 ms and the median 40.00
  (the T-510 rule flip goes too). New `[PTV-SRCPER]` DIAG line; `PTV_SRCPER_MIN=1` = the shortest step, as before.

**Verification:**
- WildTV capture replay (tests/media/captures/t512-wildtv-20261120, production command): phase lines on the wrong circle
  44 of 169 -> 0 of 18, sync-check readings beyond 21 ms 12 -> 2 (both at source damage). With sync-check watches forced
  every 7 s (probe build): STEPPED 4 in 14 decisions (pre5 learner) -> 0 in 77.
- Full gate on 12 lanes (kit `d991480`, media-v45 `7e00e283920c` = v44 + the T-512 class media, binary = this source on
  the ptv-v2-2.2 tree, `tests/results/full-222pre6cand`): **400 keys, 398 PASS** (397 + `mv01-t397/sync_clean` re-run after "lane busy before the start": PASS); the 2 FAILs are the accepted SCTE-35 KNOWN keys**. Against the pre5 baseline (v45 = v44 +
  additions only): 0 regressions. pinchk 399/399. Baseline `tests/results/baselines/2.2.2-pre6/7e00e283920c/gate`.
- New keys `prod-t512/hlsjoin`, `hlsjoin_drop`, `hlsjoin_ad` (synthetic HLS segment-join sawtooth on cap-bioclean, plus a
  lost picture at a join, plus "ad joins"): pre5 FAIL (10-11 phase lines on the 25.38 ms circle, sync-check readings at
  -25 ms), pre6 PASS. Kit judge fix: contentsync.py / ptsdomain.py read the picture's own PTS (libavcodec's best-effort
  timestamp fell back to DTS after one backward PTS step: a false -67 ms on every build).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `7ddf7bc8a4` (2026-11-20): `2.2.2-pre6  FFmpeg N-129150-g7ddf7bc8a4`,
  CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.2-pre6); smoke std/clean, blip1000, prod-t512/hlsjoin PASS.

**Known, not in this pre:** the ±34 ms steps seen once on pre3 were not reproduced; T-511 (WildTV's 8 ms audio cuts at
each join: not audible, owner 2026-11-20) -> 2.3; following a phase that hops every 6 s (two brief 25 ms transients per
5 min on the synthetic, not a sync-check trigger) -> 2.3 candidate; T-503 / T-504 / T-509, T-500.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre5. Watch: WildTV `[PTV-SYNCCHK]` no
STEPPED, `[PTV-VPHASE]` never 'of 25.40'; LVTV_Portugal no one-tick repeats from the period flip; everything else as pre5.
**Rollback:** 2.2.2-pre5, or 2.2.1 (`stable`).
