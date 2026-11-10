# ptvencoder 2.2.0-rc4

Release candidate for 2.2.0 = 2.2.0-rc3 + the T-453 fix. Source: `adaptive-2.2` @ `1d865013db` (tag `ptv-2.2.0-rc4`,
Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; only `0001` differs from rc3.

**What changed (T-453):** SCTE-35 survives a large erased step back. cor-3 GYF (rc3) carried no SCTE-35 on air after its
source stepped back 41523 s on 2026-11-09 09:06 CST, and the mux interleave buffer grew until a restart. Cause: the copy wait
queue's lag exemption (T-332: a section read within 2 video packets of a step is new content) moved a cue of the OLD content,
read 33 ms before the step's window, by the full step. That cue headed the FIFO queue unshown for good; every later cue waited
behind it and went out chained behind a label ~41500 s ahead, held forever in the dts-sorted interleave buffer. The exemption
now also needs the cue's time within 10 s of the new content's start; a small step (gate `sync_bstep`, -120 ms) is unchanged.

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `7b6d4e75cf` (2026-11-10):
  `2.2.0-rc4  FFmpeg N-128732-g7b6d4e75cf`. First verified on `49a3b1f259` (same day).
- Local repro (real GYF source capture, step re-created): rc3 0 SCTE-35 after the step, rc4 440 of 443 source cues.
- Kit gate vs rc3 (kit 5d72d5b, media e32a8dba29e4; binary = the `ptv-v2-2.2` build, same fftools + series, upstream
  base adfe258a6a; keys + smoke on the `49a3b1f259` build): 267 runs, 262 PASS, 0 regressions, 0 INVALID (the 5 FAIL fail on rc3 too: 2 known SCTE-35 lead-outage keys,
  vt-info-a85/sync_bstep, std/reshaped_return, std-info-t084/sync_ac3_clean). T-451 keys 6/6 PASS; new key `vt-t453/clean` (kit d38bb95, media-v13
  `cap-gyfstep`): rc3 FAIL (SCTE-35 stops at the step), rc4 PASS (3.71 cues/s to the end). Smoke 36/0/0.
- Not yet on a canary.

**Rollback:** 2.2.0-rc3 (`patches/ptv/2.2.0-rc3`, tag `ptv-2.2.0-rc3`).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh` (`SV_REGULATE`,
T-446 moving-reading rule).
