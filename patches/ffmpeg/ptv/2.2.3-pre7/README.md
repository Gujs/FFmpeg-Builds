# ptvencoder 2.2.3-pre7

**Pre-release (dev) = 2.2.3-pre6 + a video that moves to a new PID keeps the program's timeline (T-533).**
Source: `adaptive-2.2` @ `fab1f5fd15` (tag `ptv-2.2.3-pre7`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order. `0002`–`0008` are byte-identical to 2.2.2 / 2.2.3-pre1..pre6; `0001` carries the change. This sets `dev`; `stable`
stays 2.2.2.

**What changes (vs pre6):**
- **T-533: a moved video continues the bound stream's timeline, and a move back is taken over too.**
  - Seen on cow-1 Western_Bound_Int, 2026-11-23 09:31 CST (Amagi SSAI break edges via our ingest). The cor-1 control on
    2.2.2 was the same, and worse there.
  - The source stepped its program clock back 120.1 s, then 5 s later moved video 0x100 -> 0x1e1 and audio 0x101 -> 0x1ec,
    with the labels going on.
  - The audio take-over kept its stream's state (incl. the program offset of the step). The video take-over started the new
    stream from a fresh state, without that offset. Picture and sound ended up 120 s apart: ~30 s of silence, then the sound
    placed +100..+119 s, and sync_check restarted the channel. Present in every 2.2.x.
  - Now the moved video carries over the old stream's offset, wrap and wall references, the edit ledger the sync check reads,
    and its timeline path. A label difference at the move is an ordinary timeline event.
  - A video moving BACK to a PID it left (the break ends on the old PIDs) is now taken over the same way. Before, it was
    dropped and the picture stayed dark until the 30 s LOST reopen.
  - Log: `[PTV-SRC] input ...: video moved to pid 0x1e1 (pid 0x100 silent N s) — taken over in-process` (now also for a
    move back).
- No other change.

**Verification:**
- **New keys** `vt-t533 move` / `vt-t533 back` (kit `2230d28`, media-v50 `60d5496d714f`).
  - Setup: production single input (VideoToolbox), the cap-wbint capture (Western Bound Int, 1080p30 AAC + ID3, replayed on
    its recorded arrival times). The break edge is rebuilt from the production log: a −120.1 s program step at content 70 s,
    video + audio moved to new PIDs at 75 s; `back` moves back to the old PIDs at 95 s.
  - Judged by lip sync against the unmoved source, by content (6 s windows every 3 s). Every reliable window outside the edit
    zones must be within ±25 ms, with at least 3 after the last edit.
  - FAIL on 2.2.3-pre6 (content live share 0.73 / 0.69, no reliable window after the move).
  - PASS on pre7 (worst −13 ms / −3 ms).
- **Full gate** of the candidate (12 lanes, kit 2230d28, media-v48, `tests/results/full-t533a`), compared key by key against
  pre6's gate (`full-t532b`, same media):
  - 427 keys, 0 regressions.
  - The only FAILs are the 2 accepted SCTE-35 KNOWN lead-outage keys.
  - The four keys whose media is only in v49/v50 were run on media-v50 (`keys-v50-t533a`): vt-t533 move/back, mv-t532,
    vt-t530real — all PASS.
- **Upstream build:** strict `git apply` of all eight patches + `make ptvencoder` on upstream master `6e839cf771`
  (2026-11-24) gives `2.2.3-pre7  FFmpeg N-129278-g6e839cf771`, with CONFIG_DVB_TELETEXT_ENCODER 1 (binary
  tests/media/bin/ptv-2.2.3-pre7).
- **Smoke** on that binary (`tests/results/smoke-223pre7`, media-v50): 17/17 PASS: `vt-t533` move (28 reliable windows, worst −13 ms) and back (26, worst −3 ms), pre6's smoke (`mv-t532` tbstep, `vt-t530real` clean, prod-mv / mv01 sync_clean, mv25-t514 sync_clean, mv02-t520 sync_catchup_8, vt-t534 / std-t534 loss_100, vt-tbseed loopcap_3, vt-tbsplice loopcap_40, vt-t530 / std-t530 sync_halfwrap, vt-nowall / rich2997b sync_vnull_20, rich2997long-t471s sync_clean). Baseline `baselines/2.2.3-pre7/60d5496d714f/smoke`.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre6. The pre6 watch list still holds. Also:
- On cow-1 Western_Bound_Int, at the next Amagi break with PID moves: `video moved to pid ... taken over in-process` with
  the sound staying with the picture — no ~30 s silence, no sync_check restart, no LOST reopen when the video moves back.
- Every other channel should look the same as on pre6.

**Rollback:** 2.2.3-pre6 (or 2.2.2, `stable`).
