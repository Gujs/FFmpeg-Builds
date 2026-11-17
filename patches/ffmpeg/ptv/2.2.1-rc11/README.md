# ptvencoder 2.2.1-rc11

**Release candidate for 2.2.1 = 2.2.1-rc10 + the sync check's picture times on the exact clock (T-491, the 2.2.1 blocker
found on the rc10 sandbox soak).**
Source: `adaptive-2.2` @ `30f292efd7` (tag `ptv-2.2.1-rc11`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc10, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc10):** on rc10 the post-event sync check stepped the sound late on TruBLU (sandbox, measured on air
against the source: +67 ms, then +107 ms after one more step = the sum of the check's STEPPED values; cow-1 TruBLU / WildTV
the same, while lipsync= read ~0 because the rc10 calibration had set it to the check's reading). Cause: the check pairs
each sound frame with the picture of the same label and kept each picture's output time on the integer tick (33367 µs for
a 29.97 frame of 33366.67 µs) — the one output-time map left off the exact-rational axis. Its reading crept +10 ppm
(+1 ms per 100 s) while air stayed put, and at the next splice the creep plus the splice went over 25 ms and was stepped
onto air. Now the exact axis, like every other map and the mosaic. One line in `ptvencoder_clock.c`; no log line added or
changed.

**Verification:**
- Full gate (kit `42e5a48`, frozen copy `tests/kit-run-42e5a48`, media-v37 `8067bf87d0d7`, 6 lanes on one shared key
  queue, `tests/results/full-rc11cand`, binary = the rc11 source on int220): **377 keys, 375 PASS**; the 2 FAILs are the
  accepted SCTE-35 "KNOWN lead-outage" keys, the same two as rc10's (`full-t488d`) and rc8's gates. Zero new or
  unexplained FAILs (rc10's gate listed `std/sync_gap_20` twice; the kit now runs it once). pinchk.py PASS on all 377
  ptvencoder logs. Lanes ended 23:31:41–23:33:40.
- Failing key for T-491: gate28 `vt-tbsplice` (40 min of the real TruBLU splices, PTV_DIAG=1) now also judges VDRIFT
  (the check's picture lag must not creep between events, ≤ 3 ms per segment) and SCREAD (post-event readings within
  20 ms): rc11 VDRIFT PASS (+0 ms in 435 s), SCREAD PASS (worst −13 ms), CONTENTSYNC PASS (worst +18.5 ms); rc10 VDRIFT
  FAIL (+4 ms in 430 s, vlag +12 → +16 ms; same kit, `tests/results/t491/key-rc10-kit42e`).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `11337618b2` (2026-11-16):
  `2.2.1-rc11  FFmpeg N-128970-g11337618b2`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary kept as
  tests/media/bin/ptv-2.2.1-rc11).

**Known, not a blocker (T-492, 2.2.2):** after a splice that is not a whole number of frames the check reads the
pictures' sub-frame tick phase (up to one frame, constant; on air ~2–3 ms).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing rc10. Watch: the STEPPED values on
TruBLU / WildTV (rc10: always one sign, +30…+41 ms) and the calibration lines (`cal` should stay near 0 instead of walking
one way). **Rollback:** 2.2.1-rc10 with `PTV_NO_B2STEP=1` / 2.2.0.
