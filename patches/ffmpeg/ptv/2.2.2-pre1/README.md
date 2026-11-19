# ptvencoder 2.2.2-pre1

**Pre-release (dev) = 2.2.1 + one emit decision for the whole ABR ladder (T-498, from the T-497 lip-sync hunt).**
Source: `adaptive-2.2` @ `99c176324b` (tag `ptv-2.2.2-pre1`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order;
`0002`–`0008` are byte-identical to 2.2.1, `0001` carries the change. `dev` set; `stable` stays 2.2.1.

**What changes:** every rung ran the house clock on its own frame queue and decided its own repeats at a delivery
starvation; only rung 0 drives house_skew, the sensors and the (shared) audio. A lower rung could stay whole ticks off rung 0
for good — on that rung the lip sync was off by a frame while every log read 0 (sandbox 2026-11-18: Nothing_But_Sportz
lowest rung +30/+36 ms, WildTV ~-68 ms, Mysteria +31 ms, measured source-vs-output). Now rung 0 alone decides: per tick it
records the picture it shows (a picture serial `ptv_seq` stamped in frame metadata + source time), the output tick and the
form (picture / rendered hold picture / black); every other rung emits its own copy of that picture on that tick (older
pictures dropped, newer ones wait, a missing one repeats). Rung 0 never waits for a follower. Mosaic and offline paths
unchanged. `PTV_NO_RUNG_FOLLOW=1` reverts. New log tag `[PTV-RUNG]` (legend; WARNING events only, a DIAG line per 60 s) —
a healthy ladder logs nothing new. Implemented by Fable 5.2, reviewed and independently verified.

**Verification:**
- Full gate on 12 lanes (kit `54c4c56`, media-v39 `ddf2e647a8e6`, `tests/results/full-222pre1cand`, binary = the same
  source on upstream a5ed44135f): **383 keys, 379 PASS**; the 2 accepted SCTE-35 KNOWN lead-outage keys (as rc12 / rc13 / 2.2.1);
  2 **intermittent pre-existing** FAILs, not caused by this change (both keys run one rung, where T-498 is inert):
  `blip1000/sync_blip_20` (T-502: the post-rejoin audio buffer leaves the PID dark up to 4.1 s while it waits for a late
  video — released 2.2.1 fails it too) and `vt-nowall/sync_vnull_20` (T-503: a one-frame race at the video's return, 3
  flashes without their beep — released 2.2.1 fails it 2 of 4 runs). Both PASS in re-runs on 2.2.2-pre1
  (`tests/results/rerun-222pre1-2keys`, `rerun-vnull-221`). INVALID 0.
- New key `prod-t498/rung_starve` (rungkey.sh: production 6-rung ladder on cap-awe, 8 feed pauses, every lower rung judged
  against rung 0 by content, 3-window rule): 2.2.1 FAIL (5 of 5 rungs +30 ms, one rung ~2 min), 2.2.2-pre1 PASS, no-pause
  control PASS. Production-graph replays (bio capture, loudlive): starvations 3/3 PASS (2.2.1 3 of 4 FAIL), clean run lip
  sync vs source -1 ms flat on rung 0 and the lowest rung (= 2.2.1).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `4da74f9513` (2026-11-19):
  `2.2.2-pre1  FFmpeg N-129126-g4da74f9513`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary tests/media/bin/ptv-2.2.2-pre1).

**Not in this pre (2.2.2 plan, ROADMAP):** T-501 output video PTS holes at a forward source label step (GOALS #1, live in
2.2.1), T-499 the sound follows the picture's sub-frame snap (splices + slow-walk sources), T-502 / T-503.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2). Watch: `[PTV-RUNG]` WARNING lines (should be none), any
lower-rung A/V vs rung 0. **Rollback:** 2.2.1 (`stable`).
