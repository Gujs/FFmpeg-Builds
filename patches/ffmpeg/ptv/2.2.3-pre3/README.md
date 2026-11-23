# ptvencoder 2.2.3-pre3

**Pre-release (dev) = 2.2.3-pre2 + sound through a rejoin after a video-only hole (T-503, T-528).** Source: `adaptive-2.2` @
`e00dfab600` (tag `ptv-2.2.3-pre3`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are
byte-identical to 2.2.2 / 2.2.3-pre1 / pre2, `0001` carries the change. `dev` set; `stable` stays 2.2.2.

**What changes (vs pre2):**
- **T-503 — a rejoin's wait after a video-only hold no longer skips live sound** (since 2.2.1-rc4). When the source's
  video stops while its sound keeps flowing, the returning first picture waits about a base cushion for its slot (T-472,
  3.88 s at a 4 s pre-roll). Because the video was being read again, those ticks went into house_skew: the sound jumped
  ahead by up to the cushion (`[PTV-ASTEP]` +80..+600 ms) and the next seconds were dropped as overlap (`[PTV-ATRIM]`
  stepped back 4 s) — 1-3 returning pictures without their sound. The wait now counts as a video-only repeat, like the hold.
- **T-528 — the silence fill never runs past the picture on air** (since 2.2.1-rc7, sources with the record door: subtitles /
  teletext). After a video-only hole the fallback fill started from the last real frame placed, which was before the hole;
  it read up to 1.4 s past the returning sound and dropped it as overlap. It is now bounded by where the video is on air
  (the record door's own bound), so the wire stays continuous and no returning sound is thrown away.

**Verification:**
- Keys: every `sync_vnull_20` (vt-nowall, rich2997b/5994b/25b/50b) now judged strictly (kit 0cb09fc,
  `T056_UNPAIRED_MAX=0` — no returning picture may lack its beep): 5/5 FAIL on 2.2.3-pre2, 5/5 PASS on pre3.
- Full gate on the fixed integration build (12 lanes, kit 0cb09fc, media-v47 `8f49889427fe`, `tests/results/full-t503c`):
  414 keys; key by key against pre2's gate: the 5 strict vnull keys PASS, `mv01-t479/sync_gap_3` FAIL→PASS (the T-526
  collision, fixed in pre2), `mv01-t479b/sync_gap_4` lane-busy INVALID → rerun PASS; the only FAILs are the 2 accepted
  SCTE-35 KNOWN lead-outage keys (rich25b/sync_flapping, rich2997long-settle/sync_burst_once_6), the same as pre2.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `dd86debdbc` (2026-11-23):
  `2.2.3-pre3  FFmpeg N-129225-gdd86debdbc`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.3-pre3);
  smoke on that binary: 5/5 PASS (vt-nowall, rich2997b, rich25b sync_vnull_20; rich2997long-t471s, mv01 sync_clean; `tests/results/smoke-223pre3`).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre2 — the pre2 watch list holds (mosaic
`lipsync=` per slot near 0, film channels 0 `[PTV-ATRIM]` 17 ms steps after a hold, every mosaic start four different
regulator ports, no sync-check restart). Plus: after a source video loss with sound flowing, no `[PTV-ATRIM] stepped back`
of seconds and no `[PTV-ASTEP]` +80..+600 ms run at the return.
**Rollback:** 2.2.3-pre2, or 2.2.2 (`stable`).
