# ptvencoder 2.2.1-rc7

**Release candidate for 2.2.1 = 2.2.1-rc6 + T-476 completed + every in-scope gate FAIL fixed (owner 2026-11-15: zero
unexplained FAILs).** Source: `adaptive-2.2` @ `821515edcb` (tag `ptv-2.2.1-rc7`, Gujs/FFmpeg). Eight patches for FFmpeg
`master`, applied in order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc6, `0001` carries the ptvencoder
changes (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes:**
- **T-471 — the source clock is locked on its PCR, in front (owner: the professional way).** The regulator measures the
  source clock from its PCR (earliest arrival per 2 s, 16–60 s fit, used only when the minima do not scatter), feeds it
  forward into its schedule and the house follows it at once beyond 5000 ppm. A 1.9 % fast / 1.5 % slow source locks in
  10–15 s (was ~3 min); the delay moves ±0.21 s (was +2.2 / −1.2 s). Unregulated inputs and mosaics keep the old estimate.
  Replayed on 9 production delivery traces: no false follow; TOLLY's real 0.67 % run followed; bursty SYRIA not trusted.
- **T-486 — logs sync_check can trust (Fable 5.2 review of every line).** `lipsync=` no longer shows an adopted own-clock
  offset (rc5/rc6 printed e.g. `+10313001ms` in sync: sync_check's PIN probe would restart the channel — 8 gate keys); the
  sync check pairs sound with the picture shown nearest it (after a backward clock step it read −11680 ms in sync; pairings
  > 5 s apart rejected); STEPPED lines print the sensor's value; `async=` is not fed by a step; DIAG `[PTV-LIPSYNC]` = the
  paired offset; stale texts corrected; levels; legend covers every always-on tag; long log calls no longer cut under
  `PTV_LOG_TS`.
- **T-476 / T-484 — returns.** A source that comes back reshaped rejoins in-process (new size fitted, added track ignored;
  exit 4 only when a mapped stream is gone / changes codec, type or language). A source that comes back with every PID
  moved keeps its sound (the audio's PID move is followed in-process like the video's). A joint backward step is erased
  per stream (a85). A rejoin's queued pictures take the slots after the prime (T-472).
- **T-474 — no frozen picture after bars:** after a kept hole the decoder input waits for a keyframe (the first returning
  P-frame decoded against the pre-outage reference).
- **T-478 — the audio PID never goes dark in a stall storm (owner: professional behaviour):** returning audio behind a
  fill no longer moves the door back; 1.5 s dark → 0.26 s.
- An own-clock audio's adopted offset no longer depends on a one-picture rounding of the damage span (40 ms).

**Verification:**
- Kit `c9c7374` (frozen copy `tsw-run-c9c7374`), media-v33, full gate28 on the rc7 binary (`test-results/full-rc7cand`):
  **371 runs, 367 PASS**. vs rc6 (`full-rc6d1`): **9 FAIL → PASS** (storm_2, t471f, t471s, t084, reshaped_return,
  vt-holes, vt-holes-u, a85, vsw-bars), **8 new keys all PASS** (renumber/epg/long_return, dupsend ×3, gapdmg ×2), **0 real
  regressions**. Non-passes: the 2 owner-accepted SCTE-35 lead-outage keys (rich25b sync_flapping, rich2997long-settle
  burst_once_6) + 2 kit false counts (the new legend names `[PTV-SELFHEAL]`; 0 real lines) — re-run on kit `61f8d8b`
  (event lines only): vt-fpsflip PASS, rich2997long-t471st PASS (`test-results/rc7cand-recheck`).
- New kit checks: `pinchk.py` on every run (sync_check's PIN probe replayed + every `[PTV-SYNCCHK]` reading agrees with
  its lipsync), drift `--lock 0.5` for off-clock sources.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `afa6f90897` (2026-11-15):
  `2.2.1-rc7  FFmpeg N-128917-gafa6f90897`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc7).

**Rollout:** soak tier (live-transcoder + cow-1/2), replacing rc6; watch `[PTV-CLOCK] … (measured on its PCR)`,
`[PTV-SRC] … audio moved to pid`, `lipsync=` after events. **Rollback:** 2.2.1-rc6 / 2.2.0.
