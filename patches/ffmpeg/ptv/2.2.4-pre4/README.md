# ptvencoder 2.2.4-pre4

**Pre-release (dev) = 2.2.4-pre3 + the sound of a mosaic slot with a sliding phase stays in place (T-536).**
Source: `adaptive-2.2` @ `e9408f4226` (tag `ptv-2.2.4-pre4`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.3 / 2.2.4-pre1..pre3; `0001` carries the change. This sets `dev`; `stable`
stays 2.2.3.

**What changes (vs pre3):**
- **T-536: a mosaic slot whose picture phase slides against the house no longer drags its sound after each picture jump.**
  - Case: a 30.00 fps source in a 29.97 mosaic, or a source clock off ours (cow-2 `MV_1x2_REVn_RacerNetwork` in0: a
    30.00 source at +1000..+1800 ppm). Its pictures walk through the pick window ~1 ms/s and jump back a whole picture
    every ~33 s.
  - Before: the sound followed the pictures' 1/32 average (re-placed in 10.7 ms steps) and took each jump over ~3 s:
    +21..+29 ms on air at every jump. On air this showed as single status readings of −31..−54 ms on REVn.
  - Now: the slot's realized lag = its lag + the **mean** of where the shown pictures landed in the pick window over the
    last 60 s. It is kept in 6 bins of 10 s and re-seeded at a re-lock, not at a drift step.
    - As in a frame sync, the error left is the picture's own phase, within half a picture. The sound is not re-placed
      for it.
    - A slot whose phase stands still keeps its sound exactly on its pictures, as before.
  - A first version used the min/max middle of the window instead of the mean. One late picture under a loaded CPU moved
    it, and 2 mosaic keys failed in the 12-lane gate (`full-224pre4`, not published). The mean fixes both.
- No other change.

**Verification:**
- **New key** `mv-t536 slide` (t536key.sh, kit `6481171`, media-v54 `11f7402e2bb7`).
  - Setup: the production 1x2 mosaic (29.97). Slot 0 is an exact 30.000 fps flash+beep ruler, every sender 1100 ppm fast,
    300 s.
  - Judge: every slot-0 marker from 30 s must be within ±21 ms (half a picture + 4 ms).
  - 2.2.4-pre3: FAIL, 12 of 264 markers beyond ±21 ms, worst +29.0 ms, 16 sound re-placement lines.
  - Here: PASS, 264 markers, worst −19.7 ms, mean −0.7 ms; 4 beyond 17 ms, 5 re-placement lines.
- **All 61 mosaic keys** PASS (`tests/results/keys-mv-pre4b`). That includes `mv01 sync_gap_20` and `mv04-aflip60 sync_aflip`,
  the two the min/max version failed.
- **Full gate** of this binary (12 lanes, kit 6481171, media-v48 `b1a91b69a32a`, `tests/results/full-224pre4b`), compared
  key by key against the pre3 gate (`full-224pre3`, same media):
  - 434 runs, 411 PASS, **0 regressions**. Log checker (pinchk) 426/426 PASS.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys. Their cue numbers moved slightly: −5572 vs −5439 ms
    and −1920 vs −1880 ms.
  - `prod-t517 lv_walk400_pause` still PASS (88 % vs 92 % of windows within ±8 ms).
  - 7 keys + the new `mv-t536` have their media only in v49–v54; they ran in the smoke below.
  - Baseline `tests/results/baselines/2.2.4-pre4/b1a91b69a32a/gate`.
- **Smoke** on media-v54 (`tests/results/keys-v54-224pre4b`): **13/13 PASS**.
  - `mv-t536 slide`, `vt-t533` move (worst −13 ms) / back (worst −3 ms), `mv-t532 tbstep`, `vt-t530real clean`.
  - `rich2997b-t535` / `rich25b-t535 sync_vnull_40`.
  - The four `prod-t504` keys.
  - Controls: `mv01 sync_clean`, `rich2997long-t471s sync_clean`.
  - Baseline `baselines/2.2.4-pre4/11f7402e2bb7/smoke`.
  - The gate and the smoke ran on the build on upstream `17de9f8597`.
- **Upstream build:** upstream master moved to `d119b626ca` (8 commits: VC-1 decoder clean-ups, MOV HEIF iloc extents,
  QSV / MediaCodec decoders; none on the production path).
  - Strict `git apply` of all eight + `make ptvencoder` there gives `2.2.4-pre4  FFmpeg N-129316-gd119b626ca`,
    CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.4-pre4-upd119).
  - 4 smoke keys re-run on that binary (`tests/results/keys-v54-224pre4-upd119`): 4/4 PASS (`mv-t536 slide` worst
    −19.8 ms, `vt-t533 move` worst −13 ms, `prod-t504 tele_vstep50`, `mv01 sync_clean`).

**Known, open:** T-537 (EPIC_TV half-wrap flip-flop → MUXGUARD exit; capture running). T-538 (single-input status
`lipsync=` decays over ~4 min after a whole-source hole that returns in a new time domain; meter only). T-504 damage-era 2:1
part. A film lip-sync judge.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2). The pre1–pre3 watch lists still hold. Also: cow-2
`MV_1x2_REVn_RacerNetwork` in0 should no longer show the −31..−54 ms single readings every ~33 s.

**Rollback:** 2.2.4-pre3, or 2.2.3 (`stable`).
