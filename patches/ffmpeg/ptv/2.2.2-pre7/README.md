# ptvencoder 2.2.2-pre7

**Pre-release (dev) = 2.2.2-pre6 + a delay kept after a stall no longer breaks film cadence or walks the sound (T-516).**
Source: `adaptive-2.2` @ `e65b37c043` (tag `ptv-2.2.2-pre7`, Gujs/FFmpeg). Eight patches for FFmpeg `master`, applied in
order; `0002`–`0008` are byte-identical to 2.2.1 / 2.2.2-pre1..pre6, `0001` carries the change. `dev` set; `stable` stays 2.2.1.

**What changes (vs pre6):**
- **T-516 — film (real 3:2 cadence) while the output keeps a delay after a stall.** Two defects on top of each other:
  1. *pre-existing (2.2.1 too):* with house_skew > 0 the cadence due test (`nc <= last_vpts + 1`) was always true, so film
     pictures went out one per tick until the queue ran empty and the buffer level then see-sawed one frame at every film
     pair — the sound was cut and padded 33 ms each time (AWE_Plus 1056 ATRIM cuts, PATRIOT-OAN 3654 on 2026-11-20/21).
     Residence is now judged where the pictures are on air (`nc + vg_lag`).
  2. *from T-499 (pre3+):* the backward half of each see-saw sat on the P/2 line of the "opposite picture slip" test and
     was netted, the forward half never was — the sound walked 33 ms later per film pair (OAN_Plus +4.6 s and a sync-check
     PIN restart, cow-1 2026-11-20 19:30 CST). A house_skew step is now netted only while a picture phase is followed
     (coherent, ±1 tick), and the sound's door takes back at most one slip (beyond that the sound takes the step).
- Trigger in the field: the 2026-11-20 whole-box stalls (OOMs caused by an agent's runaway read-only scan, not by the
  encoder), which left 10–21 s banks to drain on film content.

**Verification:**
- New key `prod-t516/tele_stall` (cap-bioclean through a 3:2 telecine, media-v46 `base.tele32.ts`, encoder SIGSTOPped
  20 s while the source keeps sending): pre6 worst A/V +5.1 s / 540 sound cuts, 2.2.1 682 cuts, pre7 16 ms / 0 cuts
  (8 runs). pre6, pre2 and 2.2.1 FAIL, pre7 PASS.
- Full gate on 12 lanes (kit `dee59fc`, media-v46 `5a093dfbd154` = v45 + `base.tele32.ts`, binary = this source on the
  ptv-v2-2.2 tree `0617744864`, `tests/results/full-222pre7cand`): **401 keys, 399 PASS**; the 2 FAILs are the accepted
  SCTE-35 KNOWN lead-outage keys (same as pre6). Against the pre6 baseline (v46 = v45 + one addition): 0 regressions
  (`mv01-t397/sync_clean`, INVALID "lane busy" on pre6, PASS). pinchk 401/401.
  Baseline `tests/results/baselines/2.2.2-pre7/5a093dfbd154/gate`.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `b54992769c` (2026-11-21): `2.2.2-pre7  FFmpeg N-129180-gb54992769c`,
  CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.2-pre7); smoke std/clean, blip1000, prod-t516/tele_stall
  PASS (tele_stall: sensor worst +16 ms, 0 sound steps); baseline `tests/results/baselines/2.2.2-pre7/5a093dfbd154/smoke`.

**Known, not in this pre:** T-517 (pre-existing, every build incl. 2.2.1): film through a source pause (hold + rejoin)
gives 17 ms sound step-backs ~6 per second; pre7 halves the rate vs pre6, lip sync stays within 16 ms -> 2.2.3.
T-511, T-513..T-515 -> 2.3.

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre6. Watch: OAN_Plus / AWE_Plus /
PATRIOT-OAN `[PTV-ATRIM]` 33 ms cut rate and lip sync after any bank; no sync-check restart (wire or PIN); WildTV as pre6.
**Rollback:** 2.2.2-pre6, or 2.2.1 (`stable`).
