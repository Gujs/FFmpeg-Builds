# ptvencoder 2.2.2-pre2

**Pre-release (dev) = 2.2.2-pre1 + no output video PTS hole at a small source timing gap (T-501, GOALS #1 / #6).**
Source: `adaptive-2.2` @ `70fc7c5b5c` (tag `ptv-2.2.2-pre2`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order;
`0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1, `0001` carries the change. `dev` set; `stable` stays 2.2.1.

**What changes (vs pre1):** a forward step in the source's video timestamps under 200 ms in front of a clean frame left a
hole in the output video PTS (the output skipped 1-3 ticks): sandbox 2.2.1 PATRIOT-LVTV_Portugal 8 one-tick + 1 two-tick
holes in 2 min (its video label walk crossing the rounding line), Biohackingville a 3-tick hole at a splice's +118.67 ms
label step. Now such a gap is filled with whole-picture repeats up to the frame's slot (residence: house_skew and the audio
do not move) when this rung's queue dropped nothing since the previous pop — the gap is the source's timing; a gap our own
queue made (drop-oldest, a backlog — T-084) or one of 200 ms or more keeps the leap. Review fixes (independent agent): the
drop-oldest is counted before it takes effect; on a 2:1 source the surplus picture shown while the next one is parked is
residence too; these repeats count as pd= and get their own PTV_DIAG line (not the [PTV-VFILL] "lost/corrupt" warning).
`PTV_NO_VGAP_SRC=1` reverts. Also contains pre1 (T-498: one emit decision for the whole ABR ladder).

**Verification:**
- Full gate on 12 lanes (kit `78958c9`, media-v40 `a844ad0b3d0e` = v39 + the T-501 media, `tests/results/full-222pre2cand`,
  binary = this source on upstream 4da74f9513): **385 keys, 380 PASS**; the 2 accepted SCTE-35 KNOWN keys;
  `blip1000/sync_blip_20` (T-502, intermittent, released 2.2.1 too); `std-cin/loss_100` (**T-505**: a rare intermittent,
  2 of 59 runs over 2.2.1 / pre1 / pre2 / pre2 with T-501 off / pre2 without the counter reorder — one failure WITH T-501
  switched off, so not the gap fill; the failing runs drop a larger audio overlap at the graph door under 10 % loss,
  2290 vs 499 ms; `tests/results/rerun-cinloss*`). Against the pre1 gate key by key: the only other change is
  `vt-nowall/sync_vnull_20` FAIL -> PASS (T-503 intermittent).
- New keys `prod-t501/vstep20_awe` (cap-awe +20 ms video label step at 120 s) and `prod-t501/splice_bio` (the real
  Biohackingville splice capture): 2.2.2-pre1 FAIL (6006 at 119 s / 12000 at 159 s, all 6 rungs), pre2 PASS.
- Replays (production graph): injected step and real splice holes gone; clean lip sync -1 ms flat (= pre1); rungs PASS under
  starvations; LVTV and 59.94 -> 29.97 replays identical to pre1 (no regression).
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `01ca75d350` (2026-11-19):
  `2.2.2-pre2  FFmpeg N-129129-g01ca75d350`, CONFIG_DVB_TELETEXT_ENCODER 1, series check OK (binary tests/media/bin/ptv-2.2.2-pre2).

**Known, not in this pre:** T-499 (the sound follows the picture's sub-frame snap), T-502 / T-503 / T-505 (intermittents),
T-504 (the film / slow-arm pop path can still leave a hole).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre1. Watch: [PTV-RUNG] WARNINGs (none),
output video PTS continuity. **Rollback:** 2.2.2-pre1, or 2.2.1 (`stable`).
