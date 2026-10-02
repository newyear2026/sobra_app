# Sobrita promotional video — Spanish, version 1

- 20 seconds, 1080 × 1920, 30 fps, H.264 MP4 with AAC stereo audio.
- Actual Flutter widgets and current app sprites, rendered deterministically with an isolated mock preferences store. No personal finances or live purchases are used.
- Promotional headings are burned in. No voice-over. The soft mallet music is newly synthesized by `build_audio.py`, without third-party recordings or samples.
- Paid characters are identified with “Algunos personajes son de pago.”
- No “download now” message: the app is currently in closed testing. The file has not been uploaded or published.

## Sequence

| Time | Scene | Spanish heading |
| --- | --- | --- |
| 0–3.5 s | Animated Michi in a furnished room | Una compañía para tu quincena. |
| 3.5–8.5 s | Enter MX$85 for Café y pan; save; see updated daily amount | Registra tus gastos. |
| 8.5–13 s | Place furniture and select Casa jardín | Hazlo tuyo. |
| 13–17 s | Switch between Miru, Tranqui, and Lana in the decorator | Elige a tu compañero. |
| 17–20 s | Furnished room, animated Michi, app name | Sobrita — Tu dinero, con un poco de ternura. |

The opening and closing room shots use the production room widget enlarged for the video. The closing arrangement is a separate furnished example. Other scenes operate real app controls. The character inventory is seeded to represent a user who has already acquired the shown characters.

## Rebuild from the repository root

```sh
flutter test --no-pub tool/render_promo_video_test.dart --reporter expanded
python3 design/marketing/video-v1/build_audio.py
python3 design/marketing/video-v1/encode_video.py
```

Audio generation needs NumPy; encoding needs FFmpeg. The capture harness loads the system Arial and Arial Rounded fonts on macOS for video headings; the app uses its bundled Pixelify font. Add `--dart-define=PROMO_PREVIEW=true` to the Flutter command for sparse proof frames instead of all 600 final frames.

For a Google Play store preview, upload the MP4 to YouTube as public or unlisted, then enter the YouTube URL in Play Console. Publication is a separate step.
