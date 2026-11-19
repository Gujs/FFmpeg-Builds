# ptvencoder 2.2.2-pre4

**Pre-release (dev) = 2.2.2-pre3 + a gap-fill repeat never moves the sound (T-507) + a lost picture after a hold is a
repeat (T-508).** Source: `adaptive-2.2` @ `9dba80fa29` (tag `ptv-2.2.2-pre4`, Gujs/FFmpeg). Eight patches for FFmpeg
`master`, applied in order; `0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1..pre3, `0001` carries the change. `dev`
set; `stable` stays 2.2.1.

**What changes (vs pre3):**
- **T-507 — a residence tick does not move house_skew.** Since pre2 the T-501 gap fill occasionally made the sound step
  back one frame and forward again ~2-3 s later (`[PTV-ATRIM] input stepped back 40 ms` + `[PTV-ACOMP] ... click risk`;
  sandbox PATRIOT-LVTV_Portugal 16 times in pre2's log, twice at a live seam crossing in pre3; pre3 soak: ~125 one-frame
  step-backs on cow-1, WildTV / LawCrime / Curiosity). Measured cause: house_skew was derived again on every tick, also on
  a residence tick; when the learned source period (T-413) crosses the tick length (LVTV 1080p25: 39.5 <-> 40.0 ms)
  content_index()'s decision line moves 0.24 ms and that one fill tick published -1 tick. A residence tick now keeps the
  value of the tick that showed the picture.
- **T-508 — a small picture gap is filled at the pictures' place on air, also while the output keeps a delay.** After a
  BURST hold the output keeps the bank (house_skew +4.4 s); a corrupt picture ~28 s later left a one-picture gap the fill
  never saw (content index against the output cursor) — the picture was leapt, house_skew -33 ms and the sound cut 33 ms
  (pre2 and pre3). The fill now measures a small gap (< 200 ms, no queue drop) against where the pictures are on air, so the
  lost picture is a repeat at any kept delay. Larger damage-era gaps keep the content-index rule.

**Verification:**
- Full gate on 12 lanes (kit `25ed794`, media-v44 `70e3521b7ad1` = v42 + the T-499 release-key media, binary = this source
  on the ptv-v2-2.2 tree, upstream 01ca75d350; `tests/results/full-222pre4cand`): **397 keys, 392 PASS**. FAILs: the 2
  accepted SCTE-35 KNOWN keys; T-502 `blip1000/sync_blip_20` and T-505 `std-cin/loss_100` (old intermittents, 2.2.1 fails
  them too; pre4 2 of 6 runs each, all under extra load, pre3 1 of 4 / 0 of 4 — a loaded A/B follows); `day_2to1` (the
  Daystar content judge reads -70..+62 ms on pre2/pre3/pre4 alike) re-made a stability key (kit `0003cc7`): PASS.
  Baseline `tests/results/baselines/2.2.2-pre4/70e3521b7ad1/gate` (first v44 baseline).
- New keys (the T-499 v3 review's release list), all PASS: `prod-t499/bio_bias20` (PTV_TEST_VPH_BIAS end to end: +20.0 ms,
  pre2 0), `bio_walkneg500` (92 %, pre2 42 %), `bio_hold` (a followed phase through a 6 s hold — T-508; pre3 FAILed 5 of
  6), `lv_walk150` / `lv_walk400` (real LVTV 1080p25 + 150 / 400 ppm walks, peak-judged; T-507: 400 ppm sound steps
  pre3 1 -> 0), `cin_2997` (25 -> 29.97), `day_2to1` (59.94 -> 29.97 with a +6 ms step: followed once, vph 0 -> -6.0).
  Every m1key run now also requires flat audio PTS and no sound step (ATRIM step-back / ACOMP) in the source span.
- Live (pre3, sandbox LVTV_Portugal 2026-11-19 15:22-15:28 CET): a real seam crossing recorded and judged against the
  source (`tests/media/captures/t499-lvtv-seam-20261119`): the seam band behaved as designed (error ~P/2 for ~3 min around
  the crossing at that slow walk); the two T-507 steps are what pre4 removes.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `22cbbe3daa` (2026-11-19):
  `2.2.2-pre4  FFmpeg N-129142-g22cbbe3daa`, CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.2-pre4).

**Known, not in this pre:** T-502 / T-503 / T-505 (intermittents), T-504, T-509 (a PTS hole seen only under CPU overload),
T-510 (the T-413 period learner's flip still makes one harmless extra repeat, video only), the listening test of the T-499
slew (clips sent to the owner).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre3. Watch: `[PTV-ATRIM] ... stepped back`
of 33-45 ms on WildTV / LawCrime / Curiosity_* / LVTV (should drop to the source's own events), `[PTV-VPHASE]`, SYNCCHK
clean, [PTV-RUNG] none. **Rollback:** 2.2.2-pre3, or 2.2.1 (`stable`).
