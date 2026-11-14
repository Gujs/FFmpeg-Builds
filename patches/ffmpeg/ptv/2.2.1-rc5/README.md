# ptvencoder 2.2.1-rc5

**Release candidate for 2.2.1 = 2.2.1-rc4 + T-480 (steps 2–4) + T-481 + T-482 + T-472.** Source: `adaptive-2.2` @ `1111b43bb4`
(tag `ptv-2.2.1-rc5`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical
to 2.2.0 / 2.2.1-rc1..rc4, `0001` carries the ptvencoder changes (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes** (every case has a gate key that FAILs before the fix):
- **T-482 — GPU memory bounded (owner).** Each rung's frame queue holds GPU pictures (after hwupload / scale_cuda) and the
  CUDA pools never shrink: fleet VRAM = 315 MB + 12.2 MB × the deepest the queue has ever been (194 channels, r = 0.99).
  One stall with a catch-up burst parked 160 pictures for good (cor-1 after 600 h: median 2.2 GB per channel; cow-1 same
  channels after 6 h: 0.9 GB; live Fashion 484 → 1362 MB after one glitch on rc4). The decoder now waits while the master
  queue holds the setpoint + 8 ticks; the backlog stays compressed in the packet queue, nothing is dropped, latency /
  repeats / lip sync unchanged (the house-clock servo counts the waiting backlog). After 2 s without an output pull the
  wait is released until the queue drains (`[PTV-FQBP]`, never seen in the 360-run gate). `PTV_FQ_BP=0` reverts.
  Expected on the sandbox: VRAM stays near 315 MB + 12.2 MB × (cushion + 8) — no step after a glitch.
- **T-480 — audio off the program clock is muted (golden rule, owner).** Frame-synchronizer style: silence until the audio
  is back on the program clock; still off steadily after 10 s (or when the await ends) its offset is adopted — at most
  10 s of silence, never a silent channel. Rule B ("a clock of its own" repair) deleted: on the sandbox it fired 19× in
  2–3 days, never on a real own-clock audio. `PTV_TL_NO_MUTE=1` reverts.
- **lipsync= no longer reads an adopted offset as desync** (it showed +10313001 ms for 50 s while in sync — sync_check
  would have restarted a correct channel).
- **[PTV-SYNCCHK] (observe only):** after an event, once the source is clean, logs the offset a bounded correction would
  step out. Nothing is changed yet (rc6 arms it). `PTV_NO_SYNCCHK=1` off.
- **T-481 — a clock step right after an outage is one program event:** 2.2.0..rc4 put out a 4.6 s video PTS hole (input
  silent ~3 s, then video + PCR +3 s and the audio's +3 s a moment later).
- **T-472 — rejoin:** a LIVE LOSS / NEW DOMAIN return's first picture waits one base cushion; no RE-PRIME while no video
  arrives for 0.5 s (`PTV_REPRIME_QUIET=1` reverts).
- Logs: every `[PTV-TL]` line names its input / slot (`in%d`).

**Verification:**
- Kit `eb8fb57` (frozen copy `tsw-run-eb8fb57`), media-v32. New keys since rc4: T-482 std-t482 / vt-t482 sync_stop_10
  (frame queue ≤ 36), rich5994b-t482 bursty_10 (≤ 70), rich2997long-t482 bursty_10 (≤ 42) — rc4 160 / 160 / 136 / 160,
  rc5 33 / 33 / 67 / 37; T-479 hole keys (single + mosaic), aflip60 / tl003 / vfirst, T-481 vt-t479v.
- Full gate28 (int220 binary with identical ptvencoder sources; 6 lanes, `test-results/full-rc5d8`): 360 runs, 348 strict
  PASS, 0 INVALID, **0 regressions vs rc4 (`full-rc4`) and vs dev6 (`full-rc5d6`)**. FAILs = rc4's long-standing ones
  (vt-info-a85 sync_bstep, rich25b sync_flapping + rich2997long-settle burst_once_6 SCTE-35 known lead-outage,
  std-info-t084 sync_ac3_clean not measured, std reshaped_return; open-issue keys vt-holes / vt-holes-u, vt-vsw-bars,
  rich2997long-t471s / -t471f) + rich2997ru sync_flapping = a judge chance match (markers 74+75 read as 8+9 at +63 s);
  kit `9b73bb0` fixed the judge, the same capture rejudged = PASS with rc4's counts.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `bcbc183264` (2026-11-14):
  `2.2.1-rc5  FFmpeg N-128911-gbcbc183264`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc5).

**Rollout:** soak tier first (live-transcoder + cow-1/2), replacing rc4; watch per-channel VRAM after source glitches.
**Rollback:** 2.2.1-rc4 / 2.2.0.
