# ptvencoder 2.2.1-rc4

**Release candidate for 2.2.1 = 2.2.1-rc3 + T-469 + T-470 + T-474 (partial) + T-475.** Source: `adaptive-2.2` @ `2fa0aff43d`
(tag `ptv-2.2.1-rc4`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical
to 2.2.0 / 2.2.1-rc1..rc3, `0001` carries the ptvencoder changes (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes** (each from the production scan of 2026-11-13 or a key found while fixing one; every case has a gate key
that FAILs before the fix):
- **T-475 — ⚠ fixes a regression of rc2/rc3 (the sandbox runs rc3).** After an outage long enough for bars (≳ 9 s) the
  returning audio was repaired as "a clock of its own": lip sync off by the outage for good (std sync_gap_12 −11.9 s, audio
  dark 11.5 s; cow-1 Adrenaline+ under rc2 +65 s after a source restart). After an input silence of the stall class (≥ 3 s,
  ended ≤ 3 s before the event's window) or while the input holds, the T-463 rules (video decides alone, the await, an
  audio's own clock) stay out and the rules up to rc1 decide. 2.2.0 / rc1 were right.
- **T-469 — a picture-size switch of the source is survived.** glo-3 Stingray (adaptive-bitrate origin, 256x144 … 1920x1080)
  restarted ~40 times a day (exit 4): the hold repeated a picture before it was fitted to the graph, CUDA hwupload rejected
  it. The freeze picture is now the fitted one; the first two pictures of a new size keep their place with a repeat of the
  last picture shown (no 0.12 s video gap per switch), never while holding, keeping the damage mark, without captions.
- **T-470 — a planned audio track that never decodes carries silence (owner).** glo-4 Black_Headline_News (no audio for
  hours): video-only output and a watchdog restart every 7.5 min. After 3 s of video with the track never decoded
  (`PTV_BORN_SILENT_MS`, 0 = off) it is born silent on the house axis; real audio joins later on its content time in lip
  sync. Single input (mosaic slots: follow-up).
- **T-474 (partial) — after bars no old picture flashes back.** The pre-gap PES tail lavf hands out with the first post-gap
  packet showed the old frozen picture between the bars and the returning content; it now keeps its time and carries the
  hold picture. Residual (open): a return inside a new rendition keeps one such picture (key vt-vsw-bars).
- Test parity only: `-init_hw_device videotoolbox` gives a hwupload graph its device (macOS stand-in for CUDA).

**Verification:**
- Kit `7b7fa7c` (frozen copy `tsw-run-7b7fa7c`), media-v29 `d77473cae6df`. New keys since rc3: T-469 vt-zenlife / vt-vsw
  family (7) / mv04-t469 / vt-vui / rich25b-vsw-cc; T-470 vt-bhn / vt-bhn-fb / vt-bornsil; T-473 pmt_add / pmt_remove /
  sync_pmtbump_30 ×2 / vt-pcrpid / vt-fpsflip; T-474 vt-gap12-stale / vt-vsw-bars; T-475 std sync_gap_12 / vt-vfgap;
  T-471 / T-472 keys (open issues).
- Full gate28 (int220 binary `2.2.1-rc4`, identical ptvencoder sources; 6 lanes, `test-results/full-rc4`): 344 runs, 330
  strict PASS, 0 INVALID, **0 regressions vs rc3** (`full-rc3d3`). FAILs: the long-standing ones of rc3/rc2 (vt-info-a85
  sync_bstep, rich25b sync_flapping + rich2997long-settle burst_once_6 SCTE-35 known lead-outage, std-info-t084
  sync_ac3_clean not measured, std reshaped_return); open-issue keys that fail by design (vt-holes / vt-holes-u = T-472,
  rc5; vt-vsw-bars = T-474 residual; rich2997long-t471s / -t471f = T-471 delay excursion, FAIL on rc3 too); vt-bhn /
  vt-bhn-fb = a kit judge bug, kit `ea167a8` fixed it: PASS on rc4, FAIL on rc3 (`test-results/rc4-recheck`);
  rich2997long-t389 sync_storm_2 = flaky (audio gap 1.46–1.6 s vs 1.5 s, FAILs on rc3 too with either kit).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `c02ac4a9e0` (2026-11-14):
  `2.2.1-rc4  FFmpeg N-128907-gc02ac4a9e0`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary kept as fixture-media/bin/ptv-2.2.1-rc4).

**Rollout:** soak tier first (live-transcoder + cow-1/2) — replaces rc3 on the sandbox (T-475). **Rollback:** 2.2.1-rc3 /
2.2.0.
