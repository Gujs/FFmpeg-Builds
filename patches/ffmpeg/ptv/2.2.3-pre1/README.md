# ptvencoder 2.2.3-pre1

**Pre-release (dev) = 2.2.2 + mosaic catch-up (T-518, T-519), film through a hold (T-517), mosaic sensor (T-515), mosaic
lag step (T-523).** Source: `adaptive-2.2` @ `fab0fc6b3e` (tag `ptv-2.2.3-pre1`, Gujs/FFmpeg). Eight patches for FFmpeg
`master`, applied in order; `0002`–`0008` are byte-identical to 2.2.2, `0001` carries the change. `dev` set; `stable` stays
2.2.2. All five fixes are pre-existing defects (the same on 2.2.1 and 2.2.2); four are in the mosaic, T-517 is single input.

**What changes (vs 2.2.2):**
- **T-518 — a mosaic slot catching up is no lip-sync reading.** A picture more than 0.5 s late (a backlog at ~2.5x after an
  outage) is neither measured nor a sample of the realized lag: AmericanStories read `lipsync=` +5540 ms for ~3 min on the
  2.2.2 soak and its sound was re-placed up to 116 ms late for ~6 s.
- **T-519 — a slot's catch-up no longer leaves its sound dark.** The silence fill continues at wall pace until the returning
  sound reaches it: the slot's audio PID was dark 2.3–2.7 s and the whole mosaic's video PID 1.6–1.7 s.
- **T-517 — film through a hold.** After a hold's rejoin the sound is placed with the house_skew its picture was shown with
  plus the phase term: no more `[PTV-ATRIM] input stepped back 17 ms` ~6 times a second on 3:2 content.
- **T-515 — the mosaic sensor reads the sound's real place** (delay line counted, each picture once, the realized lag):
  `lipsync=` / `[PTV-AVSYNC]` read a slot up to ~21 ms early (Curiosity +20 ms for 9 h on the soak) while the content ruler
  measured ±2 ms. Reading only — nothing steers differently; arming a mosaic correction on it = T-524 (2.3).
- **T-523 — a mosaic lag step: picture and sound skip the same content**, to the sample (was +33 ms for one marker, under
  a second). Test-only `PTV_TEST_MVSTEP_AT` (off unless set).

**Verification:**
- Full gate on the same code (kit 3725e2b, media-v46 `5a093dfbd154`, `tests/results/t515/full-t523cand`): 412 keys,
  0 regressions vs the T-517 build's gate, 5 new keys PASS (each FAILs on the old code), the 2 accepted SCTE-35 KNOWN keys.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `f5867d96b8` (2026-11-22): `2.2.3-pre1  FFmpeg N-129220-gf5867d96b8`,
  CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.3-pre1).
- Smoke (lane 9, kit 3725e2b, media-v46): std/clean, blip1000/sync_blip_20, prod-t516/tele_stall, prod-t518/sync_catchup_8,
  mv25-t523/sync_clean — 5/5 PASS, pinchk 5/5 (`tests/results/smoke-223pre1`, on the same code before the rebase onto the
  released 2.2.2; the rebase changed only the changelog).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing 2.2.2-pre7. Watch: the mosaics
(AmericanStories, RAV, Curiosity, TruBlue, Grid_2x1) — `lipsync=` per slot should now sit near 0 where it read +20..+48 ms;
no audio-PID gap at a slot return; film channels (OAN_Plus, AWE_Plus, PATRIOT-OAN) 0 `[PTV-ATRIM]` 17 ms steps after a hold;
no sync-check restart (wire or lipsync; the new lipsync ALERT rule, T-525, runs in alert mode).
**Rollback:** 2.2.2 (`stable`).
