# ptvencoder 2.2.4-pre2

**Pre-release (dev) = 2.2.4-pre1 + the sound that comes back inside a video-only outage continues (T-535).**
Source: `adaptive-2.2` @ `fbee5a823b` (tag `ptv-2.2.4-pre2`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.3 / 2.2.4-pre1; `0001` carries the change. This sets `dev`; `stable` stays
2.2.3.

**What changes (vs pre1):**
- **T-535: an audio gap inside a video-only outage no longer silences the rest of the outage.**
  - Before: in a video-only outage (T-529), an audio gap of 3 s or more started the track's silence fill. Every real frame
    after the gap was then dropped as a "fragment of the hold" (T-083) until the picture returned. A 40 s video-only hole
    with a 5 s audio gap at 45 s was silent for 18 s after the sound was back.
  - Now, while the outage is video-only (the clock's T-076 rule) and the real frames have arrived steadily for 1 s, the
    fill ends as at a hold's end and the frames continue through the record door.
  - They are placed with the house_skew of the hold's start. The master grows house_skew while the sound is missing
    (+4.2 s in this case); with the grown value the returning sound landed ahead of the fill and 5 s of the hole were lost
    again (measured A/B).
  - A sporadic fragment of a whole-source outage is no 1 s run and is still dropped, as before.
  - Log: `[PTV-SRC] aN(inM) the sound is back in a video-only hold — the fill ends after X s, real frames continue
    (house_skew +N ms kept from the hold's start)`.
- No other change.

**Verification:**
- **New keys** `rich2997b-t535 / rich25b-t535 sync_vnull_40` (kit `c6b8e4d`, media-v51 `177ebc9ef5f8`).
  - Setup: the 40 s video-only hole (video PID nulled 30–70 s) with the audio PID also nulled 45–50 s. Every 1 s window
    of the hole outside the audio gap (±1 s) must carry TONE; lip sync after the return as for every sync_ key.
  - FAIL on 2.2.4-pre1 (both: 18 of 38 s silent, `tests/results/keys-t535-224pre1`).
  - PASS here (both; 39/39 TONE, lip sync after the return +0.6 ms).
- **Full gate** of this binary (12 lanes, kit c6b8e4d, media-v48 `b1a91b69a32a`, `tests/results/full-224pre2`),
  compared key by key against the T-529 gate (`full-t529c`, same media):
  - 429 keys, 0 regressions; log checker (pinchk) 407/407 PASS.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys (same cue numbers as before).
  - The 6 keys whose media is only in v49–v51 ran on media-v51 (below).
  - Baseline `tests/results/baselines/2.2.4-pre2/b1a91b69a32a/gate`.
- **Upstream build:** strict `git apply` of all eight patches + `make ptvencoder` on upstream master `35ef294f5d`
  gives `2.2.4-pre2  FFmpeg N-129306-g35ef294f5d` (binary tests/media/bin/ptv-2.2.4-pre2; the gate ran on this binary).
- **Smoke** on media-v51 (`tests/results/keys-v51-224pre2`): **8/8 PASS** — `rich2997b-t535` / `rich25b-t535`,
  `vt-t533` move (worst −13 ms) / back (worst −3 ms), `mv-t532 tbstep`, `vt-t530real clean`, `mv01 sync_clean`,
  `rich2997long-t471s sync_clean`. Baseline `baselines/2.2.4-pre2/177ebc9ef5f8/smoke`.

**Known, open:** T-536 (mechanism found: a drifting mosaic slot's one/two-frame lag steps; small transient while the
sound follows), T-504 (keys built on media-v52, not yet run).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2). The pre1 watch list still holds. Also: a source whose
picture stops while its sound keeps coming, with a gap in the sound too — the sound returns on air ~1 s after it is back,
`the sound is back in a video-only hold` in the log, in sync when the picture returns.

**Rollback:** 2.2.4-pre1, or 2.2.3 (`stable`).
