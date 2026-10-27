# Play "What's new" — 1.0.16 (build 27)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself; each entry stays under its 500-character
limit. The in-app notes (`lib/data/release_notes.dart`) say the same two
things.

```
<es-419>
• Llegaron 12 disfraces de temporada para tus amigos. Son gratis hasta el 3 de noviembre.
• Una vez recibidos, son tuyos para siempre.
</es-419>
<en-US>
• 12 seasonal outfits arrived for your friends. They're free until November 3.
• Once received, they are yours to keep.
</en-US>
<pt-BR>
• Chegaram 12 fantasias da temporada para seus amigos. São grátis até 3 de novembro.
• Depois de receber, são seus para sempre.
</pt-BR>
<ko-KR>
• 친구들을 위한 시즌 코스튬 12종이 도착했어요. 11월 3일까지 무료로 받을 수 있어요.
• 한 번 받으면 이벤트가 끝나도 영구 소장해요.
</ko-KR>
<ja-JP>
• 仲間たちの季節の衣装が12着届きました。11月3日まで無料で受け取れます。
• 受け取った衣装はずっと使えます。
</ja-JP>
<de-DE>
• 12 saisonale Kostüme sind für deine Freunde da. Bis zum 3. November kostenlos.
• Einmal erhalten, gehören sie dir dauerhaft.
</de-DE>
<fr-FR>
• 12 tenues de saison sont arrivées pour tes amis. Elles sont gratuites jusqu'au 3 novembre.
• Une fois reçues, ces tenues sont à toi pour toujours.
</fr-FR>
```

## What this release contains

User-facing, and in the notes:

- The autumn 2026 costume gift: 12 costumes, one per companion, claimable
  free from 10/23 through 11/3 (device local date) and kept forever.
- The "Novedades" card for 1.0.16 shows three of the costumes and, while
  the gift is unclaimed, its main button is **Ver regalo**, which opens the
  gift sheet. Once claimed or expired it falls back to **Ver todo**.
- While the gift is unclaimed, that card comes back on the first launch of
  each day through 11/3, new installs included (after onboarding's own
  notices). Ticking **No volver a mostrar** before closing it stops it for
  the rest of the campaign; the banners, the note's button and the last-day
  reminder stay.

Shipped too, but not announced:

- A last-day notification on 11/3 at 10:00 for anyone who has not claimed.
  Its own Android channel ("Regalos y novedades"), so turning it off never
  touches fixed-expense reminders. It does not ask for notification
  permission; phones that never granted it skip it. Claiming cancels the
  alarm and clears the notification if it is already showing.
