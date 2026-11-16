# ptvencoder 2.2.1-rc10

**Release candidate for 2.2.1 = 2.2.1-rc9 + the post-event sync check's step reaches the air; the slow corrector acts on
drift only (T-488, the 2.2.1 blocker found on the rc8 sandbox soak).**
Source: `adaptive-2.2` @ `7925c4ca47` (tag `ptv-2.2.1-rc10`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc9, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc9):** on rc6–rc9 the sound walked away from the picture at every source event that the sync check
stepped (sandbox, measured on air against the source: live TruBLU −3716 → −4420 ms in 20 min, ~−4 s after 8 h; cow-1
WildTV −4.9 s; lipsync= read ~0 between events, so sync_check could not see it). Cause: the record door (2.1 T-409)
replaces glue_off, so the step was booked in both sensors but never on air; lipsync= read the booked step as an error and
the slow corrector, whose correction IS on air, steered it out — one step's worth per event, always the same sign. Now the
step is applied at the door beside the corrector (on air on every path), and at each sync-check verdict (single input) the
averaged sensor is calibrated to the verdict, so the corrector keeps drift only. `PTV_NO_RSCAL=1` disables the
calibration. New log text: the calibration line under `[PTV-SYNCCHK]`, `cal=` on `[PTV-RSYNC]`, `[PTV-VMDOOR]` (PTV_DIAG
only). No status-line token changed; `lipsync=` now agrees with the sync check's verdict.

**Verification:**
- Full gate on the fix (kit `a7e94a5`, frozen copy `tests/kit-run-a7e94a5`, media-v37 `8067bf87d0d7`,
  `tests/results/full-t488d`): **378 keys, 376 PASS**; the 2 FAILs are the accepted SCTE-35 "KNOWN lead-outage" keys, the
  same two as rc8's gate (`full-rc8cand`). Zero new or unexplained FAILs. The eight log-reading keys (apause, vt-info-a85,
  vt-fpsflip, renumber_return, reshaped_return, loopsplice std + vt-loopov, rich2997long-t471st) PASS; pinchk.py PASS on
  all 377 ptvencoder logs. The gate binary differs from rc10 only in the version string, legend and changelog text.
- New keys on the real TruBLU capture (media `cap-trublusplice`, content-domain judge contentsync.py): vt-tbsplice
  (40 min of looped live splices) PASS; vt-tbseed (a corrector offset present at a splice) PASS on rc10 (+1.7 ms) and
  **FAIL on rc8** (+194 ms, 16 of 16 windows; `tests/results/rc8-tbseed-kit`) — the failing key for T-488.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `6ea799a675` (2026-11-16):
  `2.2.1-rc10  FFmpeg N-128955-g6ea799a675`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary kept as
  tests/media/bin/ptv-2.2.1-rc10).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing rc8. Watch: `corr=` on TruBLU / WildTV /
Biohackingville must stay bounded across loop splices (rc8: −4 s and growing), the share of |lipsync| > 25 ms back to rc5
levels, and the new calibration lines. **Rollback:** 2.2.1-rc8 (or `PTV_NO_B2STEP=1` on rc8 = rc5 step behaviour) / 2.2.0.
