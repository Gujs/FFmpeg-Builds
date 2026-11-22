# ptvencoder 2.2.3-pre2

**Pre-release (dev) = 2.2.3-pre1 + two mosaic slots never share a regulator port (T-526) + the legend explains a mosaic
slot's sk (T-522).** Source: `adaptive-2.2` @ `70b61bdad6` (tag `ptv-2.2.3-pre2`, Gujs/FFmpeg). Eight patches for FFmpeg
`master`, applied in order; `0002`–`0008` are byte-identical to 2.2.2 / 2.2.3-pre1, `0001` carries the change. `dev` set;
`stable` stays 2.2.2.

**What changes (vs pre1):**
- **T-526 — two mosaic slots' regulators never share a loopback port** (pre-existing since 2.2.0-pre10, every udp input
  regulated by default). Each regulator hands its paced packets to the input through a loopback UDP port it picks as "any
  free port" (bound, read, released; the input binds it a moment later). A mosaic starts all regulators before any input
  binds, and the system handed the port just released for slot 0 to slot 1 too (pre2 gate, mv01-t479: in1 'Address
  already in use' and WAITING the whole run, in0 fed both sources). 1 of 2526 regulated mosaic runs, never in the fleet's
  logs. A regulator now refuses a port another regulator of this process holds. Not covered: another process taking the
  port between the release and the input's bind (T-527: an in-memory hand-off without a port, 2.3).
- **T-522 — closed, not a defect; legend text only.** `inK:sk` is the content the frame sync dropped (or repeated) so far,
  not the slot's delay (a +130 ppm source walks it -0.47 s/h); `[PTV-RES]` occ counts pictures, tgt house ticks.

**Verification:**
- Full gate on pre2 without the T-526 fix (12 lanes, kit 8169d97, media-v47 `8f49889427fe` = v46 + `mv2997ravlong`,
  `tests/results/full-223pre2`): 413 keys; key by key against pre1's gate (411 common): 410 the same verdict, 1 changed =
  `mv01-t479/sync_gap_3` (the T-526 collision); the 2 accepted SCTE-35 KNOWN keys; `mv01-t522` PASS (new).
- The fixed build on every key the fix can reach (12 lanes, kit 333edcb, `tests/results/keys-223pre2fix`): all 51 mosaic
  keys (the only ones with more than one regulator) + `mv01-t526` + `prod-t519/sync_catchup_8` (a kit typo had dropped it
  from the full gate) + smoke = 65 keys, 65 PASS, pinchk 65/65, every udp input its own regulator, no shared port. A
  single input has one regulator and picks as before. New key `mv01-t526` (a test shim makes the system reuse the port):
  2.2.3-pre1 FAIL, pre2 PASS; every mosaic key now FAILs if two regulators report the same port.
- Strict `git apply` of all eight + `make ptvencoder` on upstream master `329157f585` (2026-11-22): `2.2.3-pre2  FFmpeg N-129222-g329157f585`,
  CONFIG_DVB_TELETEXT_ENCODER 1 (binary tests/media/bin/ptv-2.2.3-pre2).

**Rollout:** soak tier (live-transcoder + tmtg-cow-transcoder-1/2), replacing pre1 (or pre7) — the pre1 watch list holds:
the mosaics' `lipsync=` per slot near 0, no audio-PID gap at a slot return, film channels 0 `[PTV-ATRIM]` 17 ms steps after
a hold, no sync-check restart (wire or lipsync; T-525 alert mode). Plus: every mosaic start logs one `[PTV-REG] inK
regulated` per slot with four different ports.
**Rollback:** 2.2.3-pre1, or 2.2.2 (`stable`).
