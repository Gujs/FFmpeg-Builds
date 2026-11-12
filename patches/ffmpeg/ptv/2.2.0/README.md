# ptvencoder 2.2.0

**Release.** Same code as 2.2.0-rc5; only `PTVENCODER_VERSION` changes. Source: `adaptive-2.2` @ `e603e9d972` (tag
`ptv-2.2.0`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to rc5, `0001`
differs only in the version define and the changelog entry. First `stable` set.

**What 2.2.0 is** (the full list: `fftools/ptvencoder-changelog.md`, 2.2.0-pre1 … rc5): every udp input regulated by default
(T-439/T-441/T-443/T-444), source clock excursions net to zero (T-451), a mosaic slot back from a long outage keeps the hole
(T-449), SCTE-35 survives large source time steps both ways (T-453), plus the 2.1 line.

**Verification:**
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `23c4540053` (2026-11-12):
  `2.2.0  FFmpeg N-128828-g23c4540053`; kit `seriescheck.sh`: SERIES OK.
- **Overnight soak of rc5** (identical code), 2026-11-11 20:20 → 11-12 07:33 CET, soak tier live-transcoder (8) +
  tmtg-cow-transcoder-1 (64) + tmtg-cow-transcoder-2 (29) = 101 channels; control = the same channels on cor-1/2
  (2.0.2-pre4): 14 hourly checks, 0 restarts, 0 cores, RSS max +3.4 MB/h (median 0.1), SCTE-35 in = out on every
  single-input channel, large source time jumps handled (TruBLU step backs to −2698 s, Weather_nation +9047 s forward).
  Mosaic lip sync measured on air (RAV mosaic cell): rc5 +3 ms flat; pre4 on cor-2 wanders ±120 ms.
- rc5 gate vs rc4 (kit 5d72d5b, media-v11): 267 runs, 0 regressions, 0 INVALID; smoke 35/1/0 (the one mosaic cross-slot
  blip re-ran 3/3 PASS). Details: `patches/ptv/2.2.0-rc5/README.md`.
- Baselines: `test-results/baselines/2.2.0-rc5/` (same code; no separate 2.2.0 gate).

**Rollback:** 2.2.0-rc5 (same code) or 2.2.0-rc4 (`patches/ptv/2.2.0-rc4`). Production before 2.2.0: glo-1..4
2.0.1-pre1 / 2.0.2-pre4, cor-1/2 2.0.2-pre4 (sets in `patches/v2/`, not published here).

**Support scripts:** run with the transcoder repo's current `ptvencoder.sh` and `sync_check.sh` (`SV_REGULATE`,
T-446 moving-reading rule).
