# ptvencoder 2.2.3-pre5

**Pre-release (dev) = 2.2.3-pre4 + the sync check's sensor calibration off by default (T-534).** Source: `adaptive-2.2` @
`adbce6e0b8` (tag `ptv-2.2.3-pre5`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order. `0002`–`0008` are
byte-identical to 2.2.2 / 2.2.3-pre1..pre4; `0001` carries the change. This sets `dev`; `stable` stays 2.2.2.

**What changes (vs pre4):**
- **T-534: a sync check no longer recalibrates the averaged lip-sync sensor (lipsync=, the slow corrector).**
  - Since 2.2.1-rc10 (T-488) every post-event verdict stored `calibrated A -> B ms` = the sensor minus the check, without
    testing that the averaged sensor had settled. After a loss burst it is still decaying, so a transient became a
    permanent bias, and the slow corrector (dwell 300 s + 180 s quiet) moved the sound by it.
  - Seen on cow-1 Fintech_247 (2026-11-23): `calibrated +0 -> +210 ms` 14 s after a 1.5 s near-total loss; the corrector
    steered −203 ms; the sound ran ~0.2 s EARLY on air (measured against the source) while lipsync= read about 0.
    Present since 2.2.1 (2.2.2 fails the same key).
  - Now off. `PTV_RSCAL=1` turns it back on (A/B only); `PTV_NO_RSCAL` is unchanged. No new log line; the
    `[PTV-SYNCCHK] … calibrated A -> B ms` line no longer appears.
  - T-488 (the reason for the calibration) stays fixed by rc10's door actuator alone: its keys `vt-tbseed` and
    `vt-tbsplice` (40 min) PASS without the calibration.

**Verification:**
- **New keys** (kit `0fedcf2`, media-v48 `b1a91b69a32a`): `vt-t534` / `std-t534` (Cinestar 10 % loss for 200 s; every
  lipsync= reading of the last 60 s within ±25 ms). FAIL on 2.2.3-pre4 and 2.2.2 (calibrated +99 ms, the reading −97 ms
  at the end); PASS on pre5.
- **Full gate with the calibration off** (pre4's own gate binary + `PTV_NO_RSCAL=1`, 12 lanes, kit 0fedcf2, media-v48,
  `tests/results/full-223pre4-norscal` + `-rr`): 423 keys, compared key by key against pre4's gate (`full-223pre4` + `-rr`).
  - 0 regressions. The 2 T-534 keys PASS. The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys, as in pre4.
  - 2 keys INVALID from a 7 s Mac sleep, rerun: PASS.
  - No key calibrated (0 of 423 logs). In pre4's gate 12 keys calibrated (4 by 50 ms or more); all PASS without it.
- **Upstream build:** strict `git apply` of all eight patches + `make ptvencoder` on upstream master `f9145f2284`
  (2026-11-24): `2.2.3-pre5  FFmpeg N-129266-gf9145f2284`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary
  tests/media/bin/ptv-2.2.3-pre5).
- **Smoke** on that binary (`tests/results/smoke-223pre5`): 10/10 PASS (vt-t534, std-t534 loss_100; vt-tbseed loopcap_3, vt-tbsplice loopcap_40; vt-t530, std-t530 sync_halfwrap; vt-nowall, rich2997b sync_vnull_20; rich2997long-t471s, mv01 sync_clean), no `calibrated` line in any log; baseline `baselines/2.2.3-pre5/b1a91b69a32a/smoke`.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre4. The pre4 watch list still holds. Also:
- No `[PTV-SYNCCHK] … calibrated` lines.
- A STEPPED sync check is not steered back by `[PTV-RSCORR]` afterwards (lipsync= returns to about 0 and stays).
- After a loss burst, no slow `[PTV-RSCORR] ENGAGE` minutes later on a channel whose sync check said "in sync".

**Rollback:** 2.2.3-pre4 (or `PTV_RSCAL=1` on pre5 = pre4's behaviour), or 2.2.2 (`stable`).
