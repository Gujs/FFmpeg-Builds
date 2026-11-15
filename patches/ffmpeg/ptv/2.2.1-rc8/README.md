# ptvencoder 2.2.1-rc8

**Release candidate for 2.2.1 = 2.2.1-rc7 + the rc7 review's fixes (Fable 5.2) + TruBlue's loop splices.** Source:
`adaptive-2.2` @ `f0a140c937` (tag `ptv-2.2.1-rc8`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order;
`0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc7, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc7):**
- **Loop splices keep lip sync again (TruBlue; rc7 regression).** rc7 erased each stream of a joint backward step by its
  own step (a85). That is right for a stitched source's sub-second relabel and wrong at a cut / loop splice, where each
  stream was cut at its own point (TruBlue's outgoing audio runs 47–97 ms past its last frame, Metropolitan capture): rc7
  left the sound −219 / +208 ms off. The per-stream erase is now bounded to a sub-second joint step; a step of seconds
  takes the program erase as in rc6. Keys `sync_loopsplice_120` std / vt-loop / vt-loopov: rc7 −219 / −219 / +208 ms →
  rc8 0.0 ms.
- **The per-stream erase is sensor-neutral** (a judged relabel): the sync check no longer steps it a second time
  (rc7 printed `STEPPED +35 ms` after each a85 erase; a85 STEPPED 3 → 0).
- **T-484 audio PID take-over needs evidence of a move:** video flowing, the new stream born after the bound one's last
  packet, a mapped bound stream, the same language when both carry one, the first match. A paused PID with added PIDs
  present is no move (new key `apause`: rc7 took 0x102 over; renumber_return still PASS).
- **T-471 PCR clock follow arms only when the rate clears 5000 ppm by 2 standard errors of its fit**; a measure older
  than 30 s counts as none.
- A mosaic slot that comes back with added streams is retried as in rc6 (type-only check there).
- The door trim keeps its 15 s cap while a trim is under way; DIAG `[PTV-LIPSYNC]` returns to `--` without a pairing.

**Verification:**
- Kit `f6797a9` (frozen copy `tsw-run-f6797a9`), media-v36, full gate on the rc8 binary (`test-results/full-rc8cand`):
  **375 runs, 373 PASS**. vs rc7 (`full-rc7cand`): **0 regressions**; 4 new keys all PASS (apause, sync_loopsplice_120
  std / vt-loop / vt-loopov); 2 FAIL → PASS = rc7's kit false counts (t471st, fpsflip; kit `61f8d8b`). Non-passes: the 2
  owner-accepted SCTE-35 lead-outage keys (rich25b sync_flapping, rich2997long-settle burst_once_6).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `ebf7955a63` (2026-11-15; also on `0834db5163`):
  `2.2.1-rc8  FFmpeg N-128945-gebf7955a63`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc8).

**Rollout:** soak tier (live-transcoder + cow-1/2), replacing rc7; watch `lipsync=` after TruBlue's splices,
`[PTV-SRC] … audio moved to pid` (should now appear only on real moves), `[PTV-CLOCK] … (measured on its PCR)`.
**Rollback:** 2.2.1-rc7 / 2.2.0.
