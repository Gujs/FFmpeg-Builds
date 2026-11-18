# ptvencoder 2.2.1

**Release.** Same code as 2.2.1-rc13; only `PTVENCODER_VERSION` changes. Source: `adaptive-2.2` @ `a886f36f99` (tag
`ptv-2.2.1`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to rc13
(and to 2.2.0), `0001` differs from rc13 only in the version define and the changelog entry. Sets `stable` and `dev`.

**What 2.2.1 is** (the full list: `fftools/ptvencoder-changelog.md`, 2.2.1-rc1 … rc13), on top of 2.2.0: the post-event
sync check that corrects A/V once after an event (T-480, the golden rule; T-488, T-491), a source clock step taken by one
stream at a time (T-463) and PCR-locked clock follow (T-471), the returning picture and sound after an outage reshaped
(T-472, T-476, T-484, T-489), audio off the program clock muted (T-480), a source without audio carries silence (T-470),
an ABR size switch survived (T-469), GPU memory bounded (T-482), copied subtitle tracks follow the source's PMT (T-493),
logs safe for sync_check (T-486) and a true legend / -h (T-487).

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `9aa0ad8985` (2026-11-18):
  `2.2.1  FFmpeg N-129062-g9aa0ad8985`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (0007 300/300; binary kept as
  tests/media/bin/ptv-2.2.1).
- **Soak of rc13** (identical code), 2026-11-17 ~21:00 → 11-18 15:35 CET (18.6 h), soak tier live-transcoder (8) +
  tmtg-cow-transcoder-1 (64) + tmtg-cow-transcoder-2 (29) = 101 channels: 0 cores, 0 program exits, 0 sync_check restarts
  or desync verdicts (the one standing error = TMTG_Earning_Calls, source gone the whole soak); RSS max +7.1 MB/h and
  falling (a mosaic, 1024 → 1155 MB), threads and fds flat everywhere. 24 source returns, all clean (hold fill ends 2–5 s
  after the picture returns; the post-event sync check in sync within ±25 ms) — T-489's case confirmed on air.
  Independent source-vs-output A/V captures on 8 cow channels (PTS-domain match): 7 within ±5 ms; PATRIOT-Outdoor +31 ms
  (T-497, below).
- rc13 gate (12 lanes, kit 41b036c, media-v39): 382 keys, 380 PASS, the 2 accepted SCTE-35 KNOWN lead-outage keys;
  0 regressions vs rc12. Details: `patches/ptv/2.2.1-rc13/README.md`. Baselines: same code as rc13 (no separate 2.2.1 gate).

**Known, not blocking (2.3 plan, ROADMAP.md):** T-496 a mosaic slot takes 30–60 s to re-sync after a small source step
(pre-existing, also on 2.2.0); T-497 one-frame (+31 ms) audio lag on PATRIOT-Outdoor that the encoder's sensor does not
see — a fixed offset (steady for 4 h+, no drift), cause event not yet found.

**Rollback:** 2.2.1-rc13 (same code) or 2.2.0 (`patches/ptv/2.2.0`, the previous stable).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh`.
