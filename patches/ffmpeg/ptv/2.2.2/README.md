# ptvencoder 2.2.2

**Release.** Same code as 2.2.2-pre7; only `PTVENCODER_VERSION` changes. Source: `adaptive-2.2` @ `99dccf7187` (tag
`ptv-2.2.2`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to pre7
(and to 2.2.1), `0001` differs from pre7 only in the version define and the changelog entry. Sets `stable` and `dev`.
Released by the written criteria (owner 2026-11-20: "release needs to keep channels stable and in a/v sync"), not by
sign-off.

**What 2.2.2 is** (the full list: `fftools/ptvencoder-changelog.md`, 2.2.2-pre1 … pre7), on top of 2.2.1 — the T-497
lip-sync fixes: one emit decision for the whole ladder (T-498); no output PTS hole at a small source timing gap (T-501);
the sound follows the shown picture inside the frame (T-499); every hold's return is classified (T-502); a dropped
silence-fill frame moves the fill on (T-505); a gap-fill repeat never moves the sound (T-507); a lost picture after a hold
is a repeat (T-508); the source picture period is the median step (T-512); a delay kept after a stall no longer breaks
film cadence or walks the sound (T-516).

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `359c825152` (2026-11-22):
  `2.2.2  FFmpeg N-129219-g359c825152`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as tests/media/bin/ptv-2.2.2).
- **Soak of pre7** (identical code), 2026-11-21 ~17:13 CET → 11-22 17:17 CET (24 h incl. the US night), soak tier
  live-transcoder (8) + tmtg-cow-transcoder-1 (64) + tmtg-cow-transcoder-2 (29) = 101 channels, every one on its first
  start: 0 unexpected exits, 0 fatal, 0 rung divergence, 0 SELFHEAL, 0 unclean, 0 `[PTV-SYNCCHK] STEPPED`; held-4 s only
  inside a source outage (FaithNFreedom_TV, 90 s). Every lip-sync reading beyond ±25 ms for more than 10 s explained and
  not worse than 2.2.1: the mosaic sensor's own reading error (T-514 / T-515, ≤ 48 ms; the content ruler measures no real
  bias), a corrupt source burst on TVP_World (104 ms for 50 s, the same corruption on the cor-1 control), and the mosaic
  catch-up of AmericanStories_AWE slot 0 (T-518, pre-existing — fixed in 2.2.3).
- pre7 gate (12 lanes, kit dee59fc, media-v46 `5a093dfbd154`): 401 keys, 399 PASS, the 2 accepted SCTE-35 KNOWN
  lead-outage keys; 0 regressions vs pre6; pinchk 401/401. Baseline `tests/results/baselines/2.2.2-pre7/5a093dfbd154/gate`
  (same code). Smoke (std/clean, blip1000/sync_blip_20, prod-t516/tele_stall): 3/3 PASS on the same code (pre-amend build), pinchk 3/3; baseline `tests/results/baselines/2.2.2/5a093dfbd154/smoke`.

**Known, not blocking (pre-existing, same on 2.2.1; ROADMAP.md 2.2.3 / 2.3):** T-514 / T-515 the mosaic sensor reads up to
~21 ms early; T-517 film through a hold (17 ms step-backs); T-518 / T-519 mosaic catch-up; T-523 a mosaic lag step can put
one marker's sound a tick behind its picture for under a second. All of these are fixed in 2.2.3-pre1 (next `dev`).
T-522 (a 60p mosaic slot's delay growing) was measured: not a defect — the real delay stays bounded.

**Rollout:** production in the usual order (cor-1/2, then one glo box for ~24 h, then the rest). Watch: no sync-check
restart (wire or lipsync) and the new sync_check lipsync ALERT lines (T-525, alert mode since 2026-11-22).
**Rollback:** 2.2.2-pre7 (same code) or 2.2.1 (`patches/ptv/2.2.1`, the previous stable).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh`.
