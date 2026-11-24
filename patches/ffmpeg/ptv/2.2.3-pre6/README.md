# ptvencoder 2.2.3-pre6

**Pre-release (dev) = 2.2.3-pre5 + a mosaic slot's sound stays with its pictures after a source PCR step back (T-532).**
Source: `adaptive-2.2` @ `cc1fe7deab` (tag `ptv-2.2.3-pre6`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.2 / 2.2.3-pre1..pre5; `0001` carries the change. This sets `dev`; `stable`
stays 2.2.2.

**What changes (vs pre5):**
- **T-532: a mosaic slot re-locks to the lag its pictures show once they stay late by more than 2 ticks (was 0.5 s).**
  - Seen on cow-2 MV_2x2_TruBlue_Law&Crime. TruBlue steps its PCR back about 0.7 s every 4–10 minutes, and the input
    regulator holds it (`PCR jump -0.7 s — schedule continued (1.2 s held)`).
  - At about one step in three, the slot's buffer ran empty. Its pictures then showed 0.23–0.26 s past the lag for about
    10 s.
  - The sound follows the shown pictures only through a slow smoothing (~15 ms a second). Result: it played up to 0.27 s
    EARLY on air for 5–7 s (measured against the source), then about +40 ms for ~8 s. Present in 2.2.2 and every 2.2.3 pre.
  - Now: once the pictures stay late by more than 2 ticks for 1 s at real-time pace, the slot re-locks to the lag they show.
    So the sound joins them at the step. The primed margin is added only beyond 0.5 s, as before.
  - Mosaic only; single-input channels are unchanged. Log: the existing
    `[PTV-MV] inN re-locked: picture +NNN ms (late for 1 s)` line, now also for steps of 2 ticks to 0.5 s.
- No other change.

**Verification:**
- **New key** `mv-t532` (kit `20fdf0e`, media-v49 `aad0bd3dfa05`).
  - Setup: the production 2×2 mosaic. Slot 1 is the cow-2 TruBlue source capture (600 s), replayed on its recorded arrival
    times. Slot 1 is judged against the source in 3 s windows; it FAILs when two consecutive windows are beyond ±100 ms.
  - FAIL on 2.2.2 and 2.2.3-pre5 (−244 / −243 ms at output 156 s, 5 consecutive windows).
  - PASS on pre6: no two consecutive windows beyond ±100 ms. The 2 single windows beyond sit next to static-scene false
    matches, which pre5 shows too.
- **Also new:** `vt-t530real`, the T-530 key on real bytes (glo-4 EPIC_BHARAT capture, two +47720 s PCR jumps). FAIL on
  2.2.2, PASS on pre5 and pre6.
- **Full gate** of the candidate (12 lanes, kit 20fdf0e, media-v48, `tests/results/full-t532b`). Compared key by key against
  pre5's behaviour (pre4 + calibration off, `full-223pre4-norscal`):
  - 0 regressions.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys.
  - `mv-t532` / `vt-t530real` INVALID there, because their media is in v49 only. Both are run in the smoke below.
- **Upstream build:** strict `git apply` of all eight patches + `make ptvencoder` on upstream master `9ec5cf1aac`
  (2026-11-24) gives `2.2.3-pre6  FFmpeg N-129267-g9ec5cf1aac`, with CONFIG_DVB_TELETEXT_ENCODER 1 (binary
  tests/media/bin/ptv-2.2.3-pre6).
- **Smoke** on that binary (`tests/results/smoke-223pre6`, media-v49): 15/15 PASS: `mv-t532` tbstep (465 reliable windows, no two consecutive beyond ±100 ms), `vt-t530real` clean, the mosaic keys prod-mv / mv01 sync_clean, mv25-t514 sync_clean, mv02-t520 sync_catchup_8, and pre5's smoke (vt-t534, std-t534 loss_100; vt-tbseed loopcap_3, vt-tbsplice loopcap_40; vt-t530, std-t530 sync_halfwrap; vt-nowall, rich2997b sync_vnull_20; rich2997long-t471s sync_clean). No `calibrated` line in any log; baseline `baselines/2.2.3-pre6/aad0bd3dfa05/smoke`.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre5. The pre5 watch list still holds. Also:
- On cow-2 MV_2x2_TruBlue_Law&Crime, a `PCR jump -0.7 s` on in1 may now be followed within ~2 s by
  `[PTV-MV] in1 re-locked: picture +2xx ms (late for 1 s)`. That is the fix working.
- The mosaics' lipsync= / sync_check stay as before; no new restarts.

**Rollback:** 2.2.3-pre5 (or 2.2.2, `stable`).
