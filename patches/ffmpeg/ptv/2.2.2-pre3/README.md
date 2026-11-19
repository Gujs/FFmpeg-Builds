# ptvencoder 2.2.2-pre3

**Pre-release (dev) = 2.2.2-pre2 + the sound follows the shown picture inside the frame (T-499, T-497 M1).**
Source: `adaptive-2.2` @ `f413fd8cc2` (tag `ptv-2.2.2-pre3`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in order;
`0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1 / pre2, `0001` carries the change. `dev` set; `stable` stays 2.2.1.

**What changes (vs pre2):** pictures are placed on the house frame grid (round to the nearest tick), the sound at its exact
source time — so the on-air A/V offset was the rounding residue (up to ±half a frame) and it moved silently whenever the
source's video timestamps stepped by a fraction of a frame or walked. Sandbox 2.2.1: Biohackingville +18.6 ms after a
splice's +118.67 ms video label step (it never came back); PATRIOT-LVTV_Portugal's video labels walk ~−12 ppm, sweeping the
offset across ±20 ms with a wrap at 25 fps. Now the audio follows the picture's snap: an audio-only placement term (house_skew
untouched) tracks the residue measured on 0.5 s windows, slewed at 2 ms/s (4 ms/s beyond 20 ms or near the ±half-frame seam,
where the target falls linearly to 0 so a wrap never jumps a frame); not followed when the phase is not coherent for 5 s or
it slips faster than the slew can follow. Review fixes (independent agent, approve with changes): the slip is measured on
the short arc through the seam, the slip limit is derived from the slew, no snap on a pause (only on a real restart), the
sync check flags unclean beyond 3 ms from the target, r is taken on content_index's own tick branch.
`PTV_NO_VPHASE=1` reverts. Stats `vph=`, events `[PTV-VPHASE]`. Also contains pre1 (T-498: one emit decision for the
whole ABR ladder) and pre2 (T-501: no output PTS hole at a small source timing gap).

**Verification:**
- Full gate on 12 lanes (kit `ebac025`, media-v42 `2c9553d36bf6` = v40 + the T-499 media, `tests/results/full-222pre3`,
  binary = this source on upstream 01ca75d350): **390 keys, 388 PASS**; the 2 FAILs are the accepted SCTE-35 KNOWN keys
  (`rich25b/sync_flapping`, `rich2997long-settle/sync_burst_once_6`). No unexplained FAIL. Baseline
  `tests/results/baselines/2.2.2-pre3/2c9553d36bf6/gate` (first v42 baseline — not comparable key by key with pre2's v40).
- New keys `prod-t499/{bio_control, bio_vstep-14, bio_vstep+18, bio_walk500, bio_splice}` (m1key.sh: lip sync of the
  lowest rung vs the source by content, production 6-rung ladder): 2.2.2-pre2 control PASS, steps / walk / splice FAIL;
  pre3 all PASS (steps and splice within ±12 ms, walk 83 % of windows within ±8 ms, none beyond T/2).
- `prod-t498/rung_starve` judge replaced (kit `ebac025`, per-frame identity at equal PTS): the earlier correlation judge
  gave false one-tick FAILs on low-motion content; 2.2.2 0 off-tick frames, 2.2.1 still FAILs.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `1328c5613e` (2026-11-19):
  `2.2.2-pre3  FFmpeg N-129133-g1328c5613e`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.2-pre3).

**Known, not in this pre / before the final 2.2.2:** T-499 release keys from the review (netting, 2:1 and 25→29.97, 25 fps
walks at 150 / 400 ppm judged on the peak, record-door hand-over, bias hook, AAC PTS spacing flatness), a listening test
of the 0.2–0.4 % slew, a real LVTV seam crossing on the soak; T-502 / T-503 / T-505 (intermittents), T-504.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre2. Watch: `[PTV-VPHASE]` events and `vph=`
in the stats (LVTV_Portugal: vph follows the walk, no audible pitch change), SYNCCHK clean, [PTV-RUNG] WARNINGs (none).
**Rollback:** 2.2.2-pre2, or 2.2.1 (`stable`).
