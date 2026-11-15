# ptvencoder 2.2.1-rc6

**Release candidate for 2.2.1 = 2.2.1-rc5 + T-480 step 5 (the golden rule's correction).** Source: `adaptive-2.2` @ `8c5bc44a3f`
(tag `ptv-2.2.1-rc6`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical
to 2.2.0 / 2.2.1-rc1..rc5, `0001` carries the ptvencoder changes (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes** (the case has gate keys that FAIL on rc5):
- **T-480 step 5 — after an event the sync check corrects A/V once (golden rule, owner: ±25 ms within 10 s of a clean
  source, by the encoder itself).** rc5's `[PTV-SYNCCHK]` only logged the offset. rc6 acts on it: once the source has been
  clean 3 s and ledger and vring agree for 2 s (≥ 20 paired frames), an offset of 25 ms .. 5 s is stepped out of the
  audio labels in one bounded step (`STEPPED -511 ms`), once per event. Not stepped (logged as `would step … not stepped`,
  left to the corrector): when an erase in that event got no relabel/repeat verdict (steady tone or silence — a relabel
  cannot be ruled out, T-087), on a mosaic slot (observe only until a mosaic key exists), beyond 5 s.
  `PTV_NO_B2STEP=1` = observe only (rc5 behaviour); `PTV_NO_SYNCCHK=1` off.
- Everything else as rc5 (T-482 GPU frame queue bounded, T-480 steps 2–4 mute, T-481, T-472).

**Verification:**
- Kit `43835f7` (frozen copy `tsw-run-43835f7`), media-v32. New golden keys (`T056_GOLDEN=1`: lip sync within ±25 ms in
  R+10..30 s, R+30..60 s and late): rich2997long-t480g sync_arepeat_300 / sync_arepeat_600 / sync_arelabel_600,
  std-t480g sync_arelabel — rc5 FAIL on both arepeat keys (−511 / −341 ms held), rc6 PASS all four; relabel keys unmoved.
- Full gate28 (int220 binary with identical ptvencoder sources; 6 lanes, `test-results/full-rc6d1`): 364 runs, 352 strict
  PASS, 0 INVALID, **0 regressions vs the published rc5 (`full-rc5pub`, 360 / 348)** — the same 12 non-passes (rc4's
  long-standing ones + rich2997long-t389 sync_storm_2, audio PID dark 1.51 s vs 1.5 s, borderline since rc2). Sync-check
  decisions over the whole gate: 823 in sync, 4 STEPPED (all in the arepeat keys), 2 would step (steady-tone rule), 1 beyond cap.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `bcbc183264` (2026-11-15):
  `2.2.1-rc6  FFmpeg N-128911-gbcbc183264`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc6).

**Rollout:** soak tier (live-transcoder + cow-1/2), replacing rc5; watch `[PTV-SYNCCHK] … STEPPED` lines and lipsync= after events.
**Rollback:** 2.2.1-rc5 / 2.2.0.
