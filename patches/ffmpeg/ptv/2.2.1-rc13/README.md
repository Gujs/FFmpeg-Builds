# ptvencoder 2.2.1-rc13

**Release candidate for 2.2.1 = 2.2.1-rc12 + the post-rejoin audio buffer armed for every hold (T-489, the last 2.2.1
blocker from the rc11 sandbox soak).**
Source: `adaptive-2.2` @ `25be11cc9d` (tag `ptv-2.2.1-rc13`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc12, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc12):** cow-1 TVP_World on rc11 (2026-11-17): after a 320 s loss the source came back for ~1 s, then
went away for 25.6 s more; at the second return the audio entered the resampler +26 s ahead — the hole counted twice
(the label jump plus the house_skew the hold had grown) — ~30 s without sound, and ~19 s of extra latency stayed until a
restart; an earlier 315 s loss gave +317 s and 295 s of silence after the picture was back. Cause: the buffer that holds
the returning audio until the rejoin's house_skew is shown was armed only when a hold fill started from zero; a real frame
fed while the fill ran but no hold was declared (a return too short to end the fill, or the seconds between the fill's
start and STALLED) released it, and the fill went on into the next hold. Now it is armed again at the start of every hold;
frames still buffered from the short return are dropped (the fill covers their time; the existing `real frames during the
hold are dropped` line). One function in `ptvencoder_audio.c`; no new log line. Also contains rc12 (T-493).

**Verification:**
- Full gate on **12 lanes** (first gate at 12; kit `41b036c`, frozen copy `tests/kit-run-41b036c`, media-v39
  `ddf2e647a8e6`, one shared key queue, `tests/results/full-rc13cand`, binary = the rc13 source on int220): **382 keys,
  380 PASS**; the 2 FAILs are the accepted SCTE-35 "KNOWN lead-outage" keys (`rich25b/sync_flapping` −1920 ms,
  `rich2997long-settle/sync_burst_once_6` −5506 ms), the same two as rc12 / rc11. Zero INVALID, zero new or unexplained
  FAILs; pinchk.py PASS on all 382 logs. Lanes ended 20:34:26–20:36:22 (97 min for the gate; 6 lanes ≈ 3 h 45 m). Against
  the rc12 6-lane gate (compare22.py): 0 regressions. CPU idle mean 68 % (2 of 92 one-minute samples under 20 %).
- Failing key for T-489: gate28 `blip2500/sync_blip_20` (a hold, the source back for 2.5 s, a second 20 s hold, the
  return): rc11 FAIL (ACOMP +20978 ms, 20 flashes without their beep), rc13 PASS (`13 frames held 0.10 s for the
  post-rejoin mapping`, +938 ms = the kept hole's W−A); `blip1000`, `blip5000` and `vt-blip2500` (production graph +
  VideoToolbox) PASS (`tests/results/t489-blip`).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `98f2c633f4` (2026-11-17):
  `2.2.1-rc13  FFmpeg N-129018-g98f2c633f4`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary kept as
  tests/media/bin/ptv-2.2.1-rc13).

**Not covered:** the copied-audio park (`-c:a copy` tracks) arms by fill too but re-reads the rejoin state per packet
(no latch); an edge only for a short BURST return. 2.3 plan: T-494 (one placement for returning audio), T-495 (return
qualify time, optional).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing rc12. Watch: source returns (`STALLED →
LIVE` vs `hold fill ended` within seconds; no `[PTV-ACOMP] input pts step` of the outage's size), TVP_World (PTV_DIAG on
cow-1). **Rollback:** 2.2.1-rc12.
