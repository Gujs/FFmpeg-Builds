# ptvencoder 2.2.4-pre3

**Pre-release (dev) = 2.2.4-pre2 + no output timestamp hole at a small label step on film / slower sources (T-504).**
Source: `adaptive-2.2` @ `8c163e2305` (tag `ptv-2.2.4-pre3`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.3 / 2.2.4-pre1 / pre2; `0001` carries the change. This sets `dev`; `stable`
stays 2.2.3.

**What changes (vs pre2):**
- **T-504: a small forward step of the source's video labels on the film / slower-source path no longer leaves a hole.**
  - That path (3:2 soft telecine, a source slower than the house rate) pops a picture by content time and holds it at most
    its cadence's residence (film: one tick extra).
  - Before: at that cap, a picture whose slot was still ahead (a splice, a re-phase: labels step +50 ms) was popped and
    stamped on its content index. The output skipped the ticks between: +50 ms left a 1-tick hole on every rung of the
    ladder, +120 ms a 3-tick hole (GOALS #1: never a timestamp hole). T-501 (2.2.2) filled such a step on the plain path
    only.
  - Now the same rule applies at the cap. A step under 200 ms, not made by our own queue, on a clean (undamaged) picture,
    is filled with whole-picture repeats up to its slot. This uses residence, so house_skew and the sound do not move.
  - `PTV_NO_VGAP_SRC=1` reverts.
- No other change.
- Not covered: T-504's damage-era 2:1 dup-tick part (stays open).

**Verification:**
- **New keys** `prod-t504 tele_vstep20 / tele_vstep50 / tele_vstep120 / tele_clean` (kit `472cc5d`, media-v53
  `474ab94eeeac`).
  - Setup: the production 6-rung ladder on the cap-bioclean 3:2 telecine set, with the video labels stepped +20 / +50 /
    +120 ms from 120 s. Every rung's output video PTS must step one tick through the source span.
  - FAIL on 2.2.4-pre2: `vstep50` (1-tick hole) and `vstep120` (3-tick hole) on every rung.
  - PASS here, all four. The same +120 ms step on the 30p original passes on both builds.
- **Full gate** of this binary (12 lanes, kit a1ee548, media-v48 `b1a91b69a32a`, `tests/results/full-224pre3`), compared
  key by key against the pre2 gate (`full-224pre2`, same media):
  - 433 runs, 0 regressions; log checker (pinchk) 404/404 PASS.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys (same cue numbers; −5439 / −1880 ms vs −5472 / −1920).
  - The keys whose media is only in v49–v53 ran in the smoke below.
  - Baseline `tests/results/baselines/2.2.4-pre3/b1a91b69a32a/gate`.
- **Smoke** on media-v53 (`tests/results/keys-v53-224pre3`): **12/12 PASS**.
  - `vt-t533` move (worst −13 ms) / back (worst −3 ms), `mv-t532 tbstep`, `vt-t530real clean`.
  - `rich2997b-t535` / `rich25b-t535 sync_vnull_40`.
  - The four `prod-t504` keys.
  - Controls: `mv01 sync_clean`, `rich2997long-t471s sync_clean`.
  - Baseline `baselines/2.2.4-pre3/474ab94eeeac/smoke`.
  - The gate and the smoke ran on the build on upstream `35ef294f5d`.
- **Upstream build:** upstream master moved to `17de9f8597` (2 commits; libx264 encoder flush flag, not on the production
  NVENC path).
  - Strict `git apply` of all eight + `make ptvencoder` there gives `2.2.4-pre3  FFmpeg N-129308-g17de9f8597`,
    CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.4-pre3-up17de).
  - 4 smoke keys re-run on that binary (`tests/results/keys-v53-224pre3-up17de`): 4/4 PASS (`prod-t504 tele_vstep50`,
    `vt-t533 move`, `rich2997b-t535 sync_vnull_40`, `mv01 sync_clean`).

**Known, open:** T-536 (a drifting mosaic slot's one/two-frame lag steps; small transient while the sound follows; needs a
30.00-on-29.97 key). T-504 damage-era 2:1 part. A film lip-sync judge (the kit's step/peak judges misread 3:2 cadence;
no lip-sync key on film in the gate yet).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2). The pre1 and pre2 watch lists still hold. Also: a film
/ 3:2 channel at an SSAI splice no longer shows an output PTS jump of 1–3 ticks; the picture repeats instead.

**Rollback:** 2.2.4-pre2, or 2.2.3 (`stable`).
