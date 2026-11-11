# ptvencoder 2.2.0-rc5

Release candidate for 2.2.0 = 2.2.0-rc4 + the T-453 forward-jump fix. Source: `adaptive-2.2` @ `87cdf65cc5` (tag
`ptv-2.2.0-rc5`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; only `0001` differs from rc4.

**What changed (T-453, the forward case):** SCTE-35 survives a large forward jump, and no single cue can block the cue
stream any more. rc4 fixed the step-back variant; a source that jumps FORWARD tens of thousands of seconds (GYF capture,
J +45980 s) still lost every cue after the jump on rc4: a new-content cue read just before the jump's window was classified
as old content and not moved, headed the FIFO copy wait queue unshown, and every later cue chained behind it into the
dts-sorted interleave buffer (0 SCTE-35 on air, growing buffer). Two changes in `ptvencoder_demux.c`:
- **A (rebase rule):** a copy at or past the old content's end and within 10 s before the new content's start is new
  content and moves with the jump.
- **B (backstop in the wait-queue drain):** a SCTE-35 cue labelled more than 10 s past the newest video read is relabelled
  to that read (`[PTV-VMAP] a SCTE-35 cue labelled … s past the newest video read — relabelled to the video read`); a cue
  still unshown after 60 s goes out at the newest mapped video time (the T-335 path). 60 s, not less: real cue
  bursts lead their video by up to ~29 s (SCTE lead is kept, owner 2026-10-15).

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `67d2f0820b` (2026-11-11):
  `2.2.0-rc5  FFmpeg N-128799-g67d2f0820b`. First verified on `9bee1e603c` (same day; the smoke ran on that build).
- Local repros (real GYF source capture): forward jump, with and without a PTS wrap — rc4 651 cues then none, rc5 1305
  = the no-jump control; B alone also 1305 (one relabel); the rc3 step-back repro still 1305.
- Kit gate vs rc4 (kit 5d72d5b, media-v11; binary = the `ptv-v2-2.2` build, same fftools + series): 267 runs,
  0 regressions, 0 INVALID; the FAIL set is rc4's (2 known SCTE-35 lead-outage keys, vt-info-a85/sync_bstep,
  std/reshaped_return, std-info-t084/sync_ac3_clean, and the rich*ru teletext keys run without the T-319 caption delay —
  re-run on kit 4744388, which now defaults it: 27/27 PASS). Step/jump/kill + T-451/T-453 keys 21/21 PASS, SCTE-35 and
  DVB-sub placement identical to rc4.
- New key `vt-t453f/jump_return_50` (kit dbcc2ee, media-v14 `cap-gyffwd`): rc4 FAIL (73 cue packets, the last 89 s
  before the end), rc5 PASS (221, 2.04/s to the end).
- Smoke (kit 4744388, media-v14): 35 PASS, 1 FAIL, 0 INVALID. The FAIL (up-mv04/sync_flapping cross-slot: slots 2+3
  wire gap 100.5 ms at the same instant, limit 60 ms + 1 frame; no data streams in that mosaic, so the rc5 code does not
  run there; slot status clean) re-ran 3× on rc5 and 2× on rc4: all PASS, untouched-slot max gaps rc5 74–86 ms,
  rc4 71–80 ms — a one-off host-timing blip.
- Not yet on a canary. cor-3 FNF/BIO (rc4) carry no SCTE-35 until restarted.

**Rollback:** 2.2.0-rc4 (`patches/ptv/2.2.0-rc4`, tag `ptv-2.2.0-rc4`).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh` (`SV_REGULATE`,
T-446 moving-reading rule).
