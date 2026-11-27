# ptvencoder 2.2.4-pre5

**Pre-release (dev) = 2.2.4-pre4 + a stream whose labels flip bit 32 lands back next to its partner (T-537).**
Source: `adaptive-2.2` @ `f1681dfc44` (tag `ptv-2.2.4-pre5`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.3 / 2.2.4-pre1..pre4; `0001` carries the change. This sets `dev`; `stable`
stays 2.2.3.

**What changes (vs pre4):**
- **T-537: a half-wrap step is undone in half wraps.**
  - Case: glo-4 EPIC_MUSIC (2.2.3, 2026-11-27 02:57 and 03:22 GMT). Only the video's labels and its PCR flipped bit 32
    (−2^32 ticks for 0.7 s, back, −2^32 for 0.3 s, back), right after a 3.2 s stall; the audio never moved.
  - Before: the T-530 rule (2.2.3-pre4) took a step of about half the 33-bit wrap to the wrap count nearest the other
    stream, but counted in whole 2^33 wraps, so a 2^32 error stayed 2^32. The timeline took one step as a new domain and
    the return as sent: video and sound 2^32 ticks (13.3 h) apart, `lipsync=` +4.77e7 ms, sync_check restarts, ~33 min
    with the sound lost. The EPIC_TV MUXGUARD exit (T-537's first report) is the same rounding.
  - Now: the correction is counted in half wraps. The stepped stream lands back next to the other one at every step; only
    the real part of the step reaches the timeline. A whole-program step of about half (T-530) is still undone on each
    stream as it crosses.
  - Log: `[PTV-DISCONT] stream N: a half-wrap step (...) — wrap taken by the program (+-1 half wraps, nearest the other
    stream)`.
- No other change.

**Verification:**
- **New keys** `vt-t537` / `vt-t537n` / `vt-t537g` (`sync_hwflip`: the video PID's labels + PCR flip bit 32 twice in 1.5 s,
  the audio unmoved; kit `9f4afe8`, media-v55 `4e9fd1272c9e`).
  - `vt-t537` (3.2 s stall, the first step just under half, as at 03:22): 2.2.4-pre4 FAIL (lip sync −47679144 ms, video
    PTS hole 47718 s) → PASS.
  - `vt-t537n` (no stall, steps at exactly half): pre4 FAIL (video PTS holes up to 1 s) → PASS.
  - `vt-t537g` (stall, steps just over half): PASS on both.
- **Smoke** on media-v55 (`tests/results/keys-v55-224pre5`): **23/23 PASS**, pinchk 18/18.
  - The three T-537 keys and the 8 T-530 keys (half-wrap, HLS repeat, `vt-t530real`).
  - The pre4 smoke set: `mv-t536 slide` (worst −19.7 ms), `vt-t533` move/back, `mv-t532 tbstep`, the T-535 and four
    T-504 keys, controls `mv01 sync_clean`, `rich2997long-t471s sync_clean`.
  - Baseline `tests/results/baselines/2.2.4-pre5/4e9fd1272c9e/smoke`.
- **Full gate** of this binary (12 lanes, kit 9f4afe8, media-v48 `b1a91b69a32a`, `tests/results/full-224pre5`), compared
  key by key against the pre4 gate (`full-224pre4b`, same media):
  - 434 runs, 411 PASS, **0 regressions**, 2 fixed (`mv04-t449 sync_gap_40`, `mv04-t451 sync_excursion`). pinchk 403/403.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys.
  - 7 INVALID = keys whose media is only in v49–v55 (all PASS in the smoke). `vt-t534 loss_100` was not started (lane
    busy) and PASSes on its own run (`tests/results/keys-t534-224pre5`).
  - Baseline `tests/results/baselines/2.2.4-pre5/b1a91b69a32a/gate`.
  - The gate and the smoke ran on the build on upstream `d119b626ca`.
- **Upstream build:** upstream master moved to `25bf077615` (20 commits: AMF hwcontext, MXF/MOV/CAF/DV muxing, VC-1 x86
  inverse transforms, MJPEG encoder sampling, AAC USAC 4:1 SBR; none on the production path).
  - Strict `git apply` of all eight + `make ptvencoder` there gives `2.2.4-pre5  FFmpeg N-129336-g25bf077615`,
    CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.4-pre5-up25b).
  - 4 keys re-run on that binary (`tests/results/keys-v55-224pre5-up25b`): 4/4 PASS, pinchk 4/4 (`vt-t537n sync_hwflip`,
    `mv-t536 slide` worst −19.7 ms, `vt-t533 move` worst −13 ms, `mv01 sync_clean`).

**Known, open:** T-538 (single-input status `lipsync=` decays over ~4 min after a whole-source hole that returns in a new
time domain; meter only). T-539 (a source whose audio labels run 24 s behind its PCR: restart loop; design question).
T-504 damage-era 2:1 part. A film lip-sync judge.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2). The pre1–pre4 watch lists still hold. Also: any
`[PTV-DISCONT] ... half-wrap step` line should read `+-1 half wraps` with lip sync unchanged after it (EPIC channels).

**Rollback:** 2.2.4-pre4, or 2.2.3 (`stable`).
