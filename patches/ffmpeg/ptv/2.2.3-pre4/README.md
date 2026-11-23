# ptvencoder 2.2.3-pre4

**Pre-release (dev) = 2.2.3-pre3 + a whole-program half-wrap step stays one step (T-530).** Source: `adaptive-2.2` @
`997edfba0a` (tag `ptv-2.2.3-pre4`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order. `0002`–`0008` are
byte-identical to 2.2.2 / 2.2.3-pre1..pre3; `0001` carries the change. This sets `dev`; `stable` stays 2.2.2.

**What changes (vs pre3):**
- **T-530: a source that steps its whole program by ~2^32 ticks no longer splits video and audio 2^33 apart.**
  - Seen in production on glo-4 ENT-Epic_Company_EPIC_BHARAT with 2.2.0 and 2.2.2. The source steps its PCR and every label
    by about half the 33-bit wrap: "PCR jump +47720.6 s". The ingest copies the TS bytes unchanged, so the step is the source's.
  - The per-stream unwrap decided ±half for each stream on its own. After a short hole or interleave, video and audio landed
    on opposite sides: `[PTV-TL]` video +95443.758 s, audio MUTED, wire A/V offset −15 s, and a sync_check restart every
    5–9 h. The +95443 s step is chronic on EPIC_BHARAT and EPIC_MUSIC.
  - Now a step within 600 s of half takes the wrap count that puts it nearest the other video or audio stream delivered last,
    so the program steps once. Each such step is logged:
    `[PTV-DISCONT] stream N: a half-wrap step (… s) — wrap taken by the program (…)`.

**Verification:**
- **New keys** (kit `86c3312`, media-v48 `b1a91b69a32a` = v47 + 4 synthetic files):
  - `vt-t530` / `std-t530` (`sync_halfwrap`, 1.6 s hole): FAIL on 2.2.3-pre3, as in production (audio 2^33 off, the A/V PID
    dark for 60 s, exit). PASS on pre4.
  - Guards: `vt-t530s` (1.2 s hole), `vt-t530n` (no hole), and `vt-t530r` / `-x` / `-y` (a repeated-segment step back with a
    one-packet bit-32 label after or before it). These pass on both pre3 and pre4.
- **Full gate** on the fixed integration build (12 lanes, kit 86c3312, media-v48, `tests/results/full-223pre4`): 421 keys,
  compared key by key against pre3's gate (`full-t503c`).
  - The 7 new keys PASS.
  - 2 FAILs: the accepted SCTE-35 KNOWN lead-outage keys (rich25b/sync_flapping, rich2997long-settle/sync_burst_once_6), as in pre3.
  - 13 mosaic keys were INVALID "lane busy before the start". On lanes 12 and 14, ports 51202 / 51402 were held by another
    lane's mosaic regulator (kit issue T-531: lanes 10–14 lie in the macOS ephemeral port range).
  - Those 13 were rerun on lanes 3–6 (`tests/results/full-223pre4-rr`): 13/13 PASS (fixed in the kit by T-531, 300fdaa: lanes >= 10 on 21001..).
  - Otherwise identical to pre3. Baselines `tests/results/baselines/2.2.3-pre4/b1a91b69a32a/{gate,keys}`.
- **Upstream build:** strict `git apply` of all eight patches + `make ptvencoder` on upstream master `05c674c913` (2026-11-23):
  `2.2.3-pre4  FFmpeg N-129241-g05c674c913`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.3-pre4).
- **Smoke** on that binary (`tests/results/smoke-223pre4`): 6/6 PASS, baseline `baselines/2.2.3-pre4/b1a91b69a32a/smoke` (vt-t530, std-t530 sync_halfwrap; vt-nowall,
  rich2997b sync_vnull_20; rich2997long-t471s, mv01 sync_clean).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre3. The pre3 watch list still holds. Also watch:
- `[PTV-DISCONT] … half-wrap step` lines appear on a channel with a source half-wrap step.
- No `[PTV-TL]` step of ±95443 s.
- No audio MUTED after a PCR jump of ±47720 s.

**Rollback:** 2.2.3-pre3, or 2.2.2 (`stable`).
