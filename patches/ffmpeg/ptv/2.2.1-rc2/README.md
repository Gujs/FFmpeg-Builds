# ptvencoder 2.2.1-rc2

**Release candidate for 2.2.1 = 2.2.1-rc1 + T-463 + the copied-AC-3 fix.** Source: `adaptive-2.2` @ `f9902f7796` (tag
`ptv-2.2.1-rc2`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to 2.2.0 /
2.2.1-rc1, `0001` adds the changes to `fftools/ptvencoder_timeline.c` and `fftools/ptvencoder_demux.c` (+ version and changelog).
`dev` set; `stable` stays 2.2.0.

**What changes:**
- **T-463 — a source clock step that video and audio take at different moments is one consistent offset.** Found on the rc1
  soak: PATRIOT-World_Harvest_Television (cow-2, 2026-11-12 23:00 CST) — clock restart −41789 s, video first, audio 0.5 s later
  after a +0.12 s hiccup → the video went out "labels as sent": hs +8.6 h and growing, ~12 dups/s, audio dropped by the mux guard;
  Fashion (live-transcoder, 2026-11-13 01:01 CET) — the audio alone on a clock +10313 s for 3 s → padded as a 10313 s loss, hs
  +10313 s for good. Now the video decides a big step alone (the late audio keeps its sound on the old offset until it crosses),
  and an audio stepping alone by > 2 s while the pictures run on is a clock of its own (repaired on the stream, undone by its
  return leg or by the video's same step; a dead audio PID stays loss).
- **Copied AC-3 dead after a joint clock step (pre-existing).** The copy gap watch filled ahead of copies queued for the video,
  and every real AC-3 frame was then dropped for good. A copy with queued packets is no absence.

**Verification:**
- Kit `250ef4e` (frozen copy `tsw-run-250ef4e`), media-v18 `c4e28cebefab` (= media-v11..v14 byte-identical + the T-463 files):
  22 new T-463 keys (PWHT-faithful restart, audio 0.5 / 3.5 s late, audio first by 4 s (back and forward), audio J ±, late copied
  AC-3, Fashion flip with and without wall evidence, video hole / dead audio without wall evidence, window during the await,
  unrelated audio run, video-only restart, mosaic slot 0) — rc1 FAILs every repro key; rc2 passes all 22, the T-451 / T-431 /
  T-433 keys and all 14 copied-AC-3 keys (39/39).
- Full gate28 (rc2, 6 lanes, `test-results/full-rc2`): 308 runs, 300 PASS, 0 INVALID; against the rc1 gate 27 rc1 FAILs now
  PASS (rich2997ru / rich5994ru sync set, vt-t329), all 41 new keys PASS, 6 FAILs as on rc1. Two rc1-PASS keys FAIL, neither a
  product regression: `vt-heartland/clean` = an id3check window-edge artefact (all 34 ID3 items present once, the 31 judged
  ones 0.0 ms on their picture; the last item's source time is 0.3 s past the judged window, its output time 0.4 s inside it,
  so it counts "extra" — the capture ends 0.13 s later than rc1's); `rich2997long-t389/sync_storm_2` = an old flake at the
  1.5 s dark limit (A/B 3+3 runs: rc1 1.35 / 1.42 / **1.62 FAIL**, rc2 1.42 / 1.42 / 1.49; the [PTV-TL] decisions are
  identical to the ms in every run).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `88c46fce27` (2026-11-13):
  `2.2.1-rc2  FFmpeg N-128889-g88c46fce27`.
- Code reviewed in three rounds by Fable 5.2 (all findings adopted): `analysis/t463-fable-review-20261113.md` (docs repo).
  A fourth read (2026-11-13 afternoon) confirmed no rc2 path changes the storm_2 audio timing and found two OPEN edges in
  the new await, for rc3: (1) the old/new-path test ignores elapsed time — a 2–10 s step back, then the audio silent for more
  than half the step before it follows, reads as old content and is repaired as a clock of its own after 5 s (a lasting
  offset of the step); (2) a second program event within the 5 s await reuses a stale old-path offset. No gate key reaches
  either; rc1 mishandles every T-463 case anyway.

**Rollout:** soak tier first (live-transcoder + cow-1/2: PWHT on cow-2, Fashion on live). **Rollback:** 2.2.1-rc1 / 2.2.0.
