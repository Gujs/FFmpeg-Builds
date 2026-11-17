# ptvencoder 2.2.1-rc12

**Release candidate for 2.2.1 = 2.2.1-rc11 + copied subtitle tracks follow the source's PMT (T-493).**
Source: `adaptive-2.2` @ `1516356b62` (tag `ptv-2.2.1-rc12`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.0 / 2.2.1-rc1..rc11, `0001` carries the ptvencoder changes (+ version and
changelog). `dev` set; `stable` stays 2.2.0.

**What changes (vs rc11):** glo-2 2.2.0, NOCTOCODE GB_News / Euronews AI subs: the encoder started while the source came
back from an outage; the source's first PMT gave a language for one of twelve DVB subtitle tracks and the full PMT came
62 ms after the bind — eleven tracks went out as "und" (with the muxer's default page ids) until a restart. Now a copied
subtitle track takes its language, subtitling type / page ids, teletext pages and hearing-impaired flag from the source's
current PMT, and the output PMT version goes up so receivers read it again. PIDs stay as planned at start; not when
`-metadata` or a selection rule set the track's language; a track that first appears in a later PMT is still not added.
New log lines (in the legend): `[PTV-SRC] inK pid 0xP (codec): the source's PMT says LANG (was OLD) — the output follows`,
`[PTV-MUX] output PMT version a → b: N copied track(s) take the source's language / page data`.

**Verification:**
- Full gate (kit `b1b7c23`, frozen copy `tests/kit-run-b1b7c23`, media-v39 `ddf2e647a8e6`, 6 lanes on one shared key
  queue, `tests/results/full-rc12cand`, binary = the rc12 source on int220): **378 keys; 360 PASS, 1 FAIL, 17 INVALID**
  (the Mac slept on battery 16:07–17:20). The 17 INVALID keys re-run on AC (`tests/results/full-rc12cand-rerun`, same kit,
  media, binary): 16 PASS, 1 FAIL. **In all: 376 PASS + the 2 accepted SCTE-35 "KNOWN lead-outage" keys**
  (`rich2997long-settle/sync_burst_once_6`, `rich25b/sync_flapping`) = the same two as rc11. Zero new or unexplained
  FAILs. pinchk.py PASS on all 395 ptvencoder logs.
- Failing key for T-493: gate28 `vt-cin/pmtlate_15` (cap-cinestar with three subtitle PIDs listed language-less until
  content 15 s; LANGS judge = langcheck.py): rc11 FAIL (hrv + und und und), rc12 PASS (output PMT v0 → v1, one `[PTV-MUX]`
  line). The kit now accepts an output PMT version change with the same PIDs only as the encoder's own `[PTV-MUX]` line.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `f1d4dd2bd0` (2026-11-17):
  `2.2.1-rc12  FFmpeg N-129001-gf1d4dd2bd0`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary kept as
  tests/media/bin/ptv-2.2.1-rc12).

**Known, open (2.2.1 blocker T-489):** after a source return too short to end the audio's hold fill (live: ~1 s; kit
`sync_blip_20` with a 2.5 s return), a second hold's return counts the hole twice (+20 s at the resampler, the sound
silent that long, house_skew latency left behind). Same in rc11 / 2.2.0; fix in progress for the next rc.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing rc11; NOCTOCODE AI subs channels benefit
most (glo-2 is production — owner's call). Watch: `[PTV-MUX] output PMT version` lines (should appear only when a source
PMT changes a copied subtitle track). **Rollback:** 2.2.1-rc11.
