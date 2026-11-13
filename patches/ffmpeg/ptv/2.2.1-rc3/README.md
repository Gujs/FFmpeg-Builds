# ptvencoder 2.2.1-rc3

**Release candidate for 2.2.1 = 2.2.1-rc2 + T-464 + T-466 + T-467.** Source: `adaptive-2.2` @ `55109f433e` (tag `ptv-2.2.1-rc3`,
Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1 /
2.2.1-rc2, `0001` adds the changes to `fftools/ptvencoder_timeline.c` (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes** (T-464 found by a code review of rc2, T-466 / T-467 by its control keys; every case got a gate key that
FAILs before the fix):
- **T-464 — the awaited audio is judged against where its paths are now.** rc2's 5 s await (an audio left on its old clock
  after the video's big step) compared a returning packet with frozen path ends: a 3 s step back + the audio silent 2 s →
  its new-clock return went out on the old offset and was repaired as a clock of its own (lip sync −3 s for good); forward, an
  own-clock audio pausing on an 8 s step read as crossed (−8 s); a second restart inside the await re-awaited the audio on a
  stale path (flashes without sound). Both paths now move on by the video's content progress (capped by the audio's own
  silence); an audio on its own cadence without a silence is old; later events accumulate into the await.
- **T-466 — a forward clock step of the video alone shorter than the window's wait + 2 s.** Rule C's "video hole" veto read
  where the audio was after the window waited for it: a 3 s step of the video with an own-clock audio went out "labels as
  sent", lip sync −3 s. The veto now uses where the audio was when the window opened.
- **T-467 — damage at a big step is judged where the event began (pre-existing since 2.2; found by the T-464 key
  vt-ap-ownp).** A big step's window waits up to 3 s for its partner; the damage test counted from its close, so in a long
  window the corrupt datagram at the step aged out and its lost picture was erased with the step: an own-clock audio +40 ms
  late for good. The damage flag and the keep floor's "audio undamaged" test now count from the window's open.

**Verification:**
- Kit `5388c3f` (frozen copy `tsw-run-5388c3f`), media-v23 `ad8227fc54c9` (= media-v18 byte-identical + the T-464 files).
  New keys: vt-ap-ctl / vt-ap-own8 (controls, PASS on rc2), vt-apause / vt-apause3 / vt-ap-ownp / vt-v2 / vt-ap-own (FAIL on
  rc2; vt-apause3 — Fable's round-6 edge — FAILed on rc3-dev1 too; vt-ap-ownp FAILed on rc3-dev1/dev2 = T-467). Targeted on rc3-dev1: 47/48 (all T-463 / T-451 / T-431 /
  T-433 / copied-AC-3 keys + the vnull keys R1 protects).
- Full gate28 on rc3-dev2 (T-464 + T-466, `test-results/full-rc3d2`): 315 runs, 308 PASS, 0 regressions vs rc2, only new FAIL
  vt-ap-ownp (→ T-467).
- Full gate28 (rc3-dev3 = this code, version string only differs; 6 lanes, `test-results/full-rc3d3`): 315 runs, 309 PASS
  (+ the wrap-off WRAPCHECK line), 0 INVALID, **0 regressions** vs rc2 (`full-rc2`) and vs rc3-dev2; the 5 FAILs are the
  long-standing ones that fail on rc2 / rc1 too (vt-info-a85 sync_bstep, rich25b sync_flapping + rich2997long-settle
  burst_once_6 SCTE-35 known lead-outage, std-info-t084 sync_ac3_clean not measured, std reshaped_return); all 7 T-464 /
  T-466 / T-467 keys PASS (vt-ap-ownp: "(damaged), kept 0.040 s", offset 0.0 ms).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `f8bb61cd57` (2026-11-13):
  `2.2.1-rc3  FFmpeg N-128900-gf8bb61cd57`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc3).
- The gate ran the int220 binary `2.2.1-rc3-dev3` (identical ptvencoder sources, version string only); its results stay
  unpruned in `test-results/full-rc3d3` (baseline.sh stores release-stamped binaries only).
- Code reviewed by Fable 5.2 (four rounds on this change; every finding adopted or given its own key; one follow-up without
  a key yet is T-468, not changed blind).

**Rollout:** soak tier first (live-transcoder + cow-1/2). **Rollback:** 2.2.1-rc2 / 2.2.0.
