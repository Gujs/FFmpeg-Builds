# ptvencoder 2.2.1-rc9

**Release candidate for 2.2.1 = 2.2.1-rc8 + the log legend and `-h` made true to the code (T-487). No behaviour change.**
Source: `adaptive-2.2` @ `7fb41d9226` (tag `ptv-2.2.1-rc9`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc8, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc8), text only — owner rule "logs must be perfect":** the operator-guide rewrite read every log line
against `-log-legend` and found lines the code prints that the legend did not explain. Now explained: the `[PTV-SRC]`
returns (renumbered / incomplete / without its declared SCTE-35), the in-process PID and codec moves (video/audio moved to
pid, audio pid flows again, decoder swapped, SCTE-35 appeared on the declared PID or NOT on the output), the damaged-input
hold end and every exit line (exiting 4 / 5, PROBING, `-wait_input`); `[PTV-REG]` 'PCR moved' and 'no PCR in 5 s';
`[PTV-AF]` and `[PTV-CONV]`; the single input's `[PTV-REOPEN]` lines; the mosaic's per-slot `cc=` and the fields its line
does not carry (src= except the start-up heartbeat, hs=, cf=, unreg=, dlvdrop=). `cf=` says when it is shown and that the
follow arms at 5000 ppm + 2 standard errors with a measure at most 30 s old (rc8). `-h`: `-pid_plan` describes v2 as the
default (it showed the v1 packed layout); `PTV_VIDEOQ` default 512. No status-line token and no event line changed, so
sync_check reads exactly what it read on rc8.

**Verification:**
- `-log-legend`: 440 lines, every new line present, all stamped under `PTV_LOG_TS=1` (largest legend chunk 2.6 KB of
  the 8 KB log buffer).
- Kit `659306b` (frozen copy `tests/kit-run-659306b`, first run from the new tests/ layout), media-v36, the
  log-reading keys on the rc9 binary (`tests/results/rc9-logkeys`): **8 / 8 PASS** — apause (`audio moved to pid=0`),
  vt-info-a85 (`STEPPED=0`), vt-fpsflip (`SELFHEAL=0`), renumber_return, reshaped_return, loopsplice std + vt-loopov,
  rich2997long-t471st; pinchk.py on every run. Behaviour = rc8 (gate 375/373, `full-rc8cand`).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `33a5956d8b` (2026-11-15):
  `2.2.1-rc9  FFmpeg N-128946-g33a5956d8b`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as tests/media/bin/ptv-2.2.1-rc9).

**Rollout:** soak tier, replacing rc8 when convenient (logs only — no hurry). **Rollback:** 2.2.1-rc8 / 2.2.0.
