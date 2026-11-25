# ptvencoder 2.2.3

**Release.** Same code as 2.2.3-pre7; only `PTVENCODER_VERSION` changes. Source: `adaptive-2.2` @ `9cd0ccfac1` (tag
`ptv-2.2.3`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to pre7
(and to 2.2.2), `0001` differs from pre7 only in the version define and the changelog entry. Sets `stable` and `dev`.
Released by the written criteria (owner 2026-11-20: "release needs to keep channels stable and in a/v sync"), not by
sign-off.

**What 2.2.3 is** (the full list: `fftools/ptvencoder-changelog.md`, 2.2.3-pre1 … pre7), on top of 2.2.2:
- mosaic catch-up without losing the slot's sound (T-518, T-519);
- film through a hold (T-517);
- the mosaic sensor counts the follow delay (T-515);
- a mosaic lag step keeps the marker's sound with its picture (T-523);
- two mosaic slots never share a regulator port (T-526);
- sound through a rejoin after a video-only hole (T-503, T-528);
- a half-wrap source step keeps sound and picture together (T-530);
- the sensor calibration is off by default (T-534; `PTV_RSCAL=1` turns it on for A/B);
- a mosaic slot's sound stays with its pictures after a source PCR step back (T-532);
- a video that moves to a new PID continues the program's timeline, and a move back is taken over too (T-533).

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `35ef294f5d` (2026-11-25):
  `2.2.3  FFmpeg N-129306-g35ef294f5d`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as tests/media/bin/ptv-2.2.3).
- **Soak of pre7** (identical code), 2026-11-24 ~21:39 CET → 11-25 21:45 CET (24 h incl. the US night), soak tier
  live-transcoder (8) + tmtg-cow-transcoder-1 (64) + tmtg-cow-transcoder-2 (29) = 101 channels, every one on its first
  start:
  - 0 fatal, 0 rung divergence, 0 SELFHEAL, 0 unclean, 0 held-4 s, 0 half-wrap / timeline-wrap events, 0 calibrations.
  - 1153 sync-check verdicts, 0 `[PTV-SYNCCHK] STEPPED`; 0 of 101 channels beyond ±25 ms at the end.
  - 1 unexpected exit, by design: cow-1 Nothing_But_Sportz was started under the fallback while its source was gone, and
    exited 5 for the re-probe 60 s after the source came back (`-fallback_rebind`; ~41 s off air).
  - Every lip-sync reading beyond ±25 ms is explained:
    - source events seen the same on the 2.2.2 / 2.0.2 controls: TVP_World corruption at the deploy minute, the GBN source
      outage, a Biohackingville audio gap, one 44 ms reading each on Curiosity_* / Catholic_History at a source frame loss;
    - the mosaic meter's one-frame readings on cow-2 REVn in0 (T-536: isolated −31..−33 ms samples with no correction
      between them, the per-track meter at −7..+1 ms, the same rate on 2.2.3-pre3; owner 2026-11-25: not blocking).
- pre7 full gate (12 lanes, kit 2230d28, media-v48 + the v50 keys): 427 keys, 0 regressions vs pre6; the only FAILs are
  the 2 accepted SCTE-35 KNOWN lead-outage keys. Results `tests/results/full-t533a` (the candidate build, same code).
- **Smoke** on that binary (`tests/results/smoke-223`, kit eb8b351, media-v50 `60d5496d714f`): 3/3 PASS — `vt-t533 move`
  (28 reliable windows, worst −13 ms), `mv01 sync_clean`, `rich2997long-t471s sync_clean`. Baseline
  `tests/results/baselines/2.2.3/60d5496d714f/smoke`.

**Known, not blocking:**
- T-533 has not been exercised live yet (no Western Bound PID-move break during the soak); its synthetic keys PASS.
- T-536: the REVn mosaic meter's one-frame samples (above).
- T-529 (since 2.1): a video-only hole silences sound that keeps arriving. Fixed in the next `dev`, 2.2.4-pre1.

**Rollout:** production in the usual order (cor-1/2, then one glo box for ~24 h, then the rest). Watch: no sync-check
restart (wire or lipsync) and the sync_check lipsync ALERT lines (T-525).
**Rollback:** 2.2.3-pre7 (same code) or 2.2.2 (`patches/ptv/2.2.2`, the previous stable).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh`.
