# ptvencoder 2.2.1-rc1

**Release candidate for 2.2.1 = 2.2.0 + T-461.** Source: `adaptive-2.2` @ `8598caf617` (tag `ptv-2.2.1-rc1`, Gujs/FFmpeg).
Eight patches for FFmpeg `master`, applied in order; `0002`–`0008` are byte-identical to 2.2.0, `0001` adds the T-461 change
to `fftools/ptvencoder_clock.c` (+ version and changelog). `dev` set; `stable` stays 2.2.0.

**What changes (T-461) — only channels whose source runs faster than the output (`-r max:30` on 59.94 / 50, SV_FPS=max:30):**
- The frame-queue cushion is counted in content, not pictures. 2.2.0 counted the two source pictures of each output tick as
  two ticks: the servo held half the designed cushion (cow-1 on 2026-11-12, and locally: 0.52 s instead of 1 s), the start-up
  prime stopped at 0.5 s, and `wucr_buf=` showed twice the real ms.
- Cushion targets of such a channel are capped at 3/4 of the frame queue (120 pictures = 2.0 s at 59.94 → 29.97). Counted in
  ticks, the 4 s raised tier (grown on cow by Daystar_esp and PATRIOT-Family_Entertainment after two starvations) asked 238
  pictures of a 160-picture queue: continuous drop-oldest (local, 5 min: 1202 pictures).
- Channels at their source rate (every channel without `-r` / SV_FPS, and every mosaic) behave exactly as 2.2.0.

**Verification:**
- Local A/B, Daystar_esp capture (720p59.94) over UDP, `-r max:30`, 10 min: content queued 2.2.0 0.52 s (min 0.23) →
  rc1 1.02 s (min 0.78); 59.94 output unchanged (1.00 s both); 0 dup / 0 drop. Deep target (4 s tier) 5 min: 2.2.0 98–135
  pictures 0 drops, rc1 without the cap 1202 drops, rc1 111–132 pictures 0 drops.
- New kit keys (kit 9c31c46, media-v14): `rich5994b-r30`, `rich50b-r30` (clean, gap_20, kill_return_20, loss_100, stop_20,
  bursty_6) + `day-r30` (Daystar capture), cushion check `T056_CUSHION_MIN=0.8` = queued pictures ÷ source rate on the steady
  scenarios: **rc1 13/13 PASS** (cushion 0.92–1.80 s); 2.2.0 (rc5 binary) 5 FAIL (0.48–0.58 s). The outage scenarios carry no
  cushion bar: a 20 s outage empties the queue by design (native 29.97 control = rc1 at 2:1).
- Regression gate vs 2.2.0-rc5 (= 2.2.0 code; kit 5d72d5b, media-v11, binary = the `ptv-v2-2.2` build): 267 runs, 235 PASS,
  **0 regressions, 0 INVALID**; the FAIL set is rc5's (rich*ru teletext timing without the T-319 default on this kit, the
  owner-accepted SCTE-35 lead-outage keys), counts ±1.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `21ae927dc6` (2026-11-12): `2.2.1-rc1  FFmpeg N-128867-g21ae927dc6`.
- Baselines: `test-results/baselines/2.2.1-rc1/`.

**Not in this change:** a start-up backlog longer than the 160-picture queue (2.67 s of any 59.94 source, with or without
`-r`) still sheds on non-master rungs (cow-1 restart of 2026-11-12 09:01, set-up 3.3 s with seven channels restarting).

**Rollout:** soak on the soak tier first (cow-1/2 carry the SV_FPS=max:30 channels). **Rollback:** 2.2.0 (`patches/ptv/2.2.0`).
