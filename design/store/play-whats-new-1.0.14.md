# Play "What's new" — 1.0.14 (build 24)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself; each entry stays under its 500-character
limit. The in-app notes (`lib/data/release_notes.dart`) say the same two
things.

```
<es-419>
• Al terminar la bienvenida, tu primer gasto se anota en dos pasos, y ese día ya cuenta para que llegue tu otro compañero.
• Una cuenta nueva empieza en la moneda de tu país.
</es-419>
<en-US>
• Right after the welcome, your first expense takes two steps, and that day already counts towards bringing your other companion over.
• A new ledger starts in your country's currency.
</en-US>
<pt-BR>
• Logo depois das boas-vindas, seu primeiro gasto leva dois passos, e esse dia já conta para trazer seu outro companheiro.
• Uma conta nova começa na moeda do seu país.
</pt-BR>
<ko-KR>
• 환영 화면이 끝나면 첫 지출을 두 단계로 기록해요. 그날부터 다른 친구를 데려오는 기록일로 쳐요.
• 새로 시작하면 내 나라 통화로 시작해요.
</ko-KR>
<ja-JP>
• ようこそ画面のあと、はじめての支出を2ステップで記録できます。その日から、もう一匹の仲間を迎える記録日に数えます。
• 新しく始めると、お住まいの国の通貨で始まります。
</ja-JP>
<de-DE>
• Direkt nach der Begrüßung trägst du deine erste Ausgabe in zwei Schritten ein, und dieser Tag zählt schon, um deinen zweiten Begleiter zu holen.
• Ein neues Haushaltsbuch startet in der Währung deines Landes.
</de-DE>
<fr-FR>
• Juste après l’accueil, votre première dépense se note en deux étapes, et ce jour compte déjà pour faire venir votre autre compagnon.
• Un nouveau carnet démarre dans la monnaie de votre pays.
</fr-FR>
```

## What this release contains

User-facing, and in the notes:

- The guided first expense after onboarding (`35d5306`), with Inicio's
  card for whoever answers "Aún no he gastado".
- New installs start in the phone country's currency (`a173240`).

Shipped too, but not announced because nobody sees them as a change:

- Play's rating sheet asked once, the day after the first record (`42dd01c`).
- Collection visits and their way in reported to Analytics (`287c3da`).
- Installs from Meta ads reported through Meta App Events (`f80c022`).
- A `first_expense` Analytics event with `origin` (`onboarding`,
  `homeCard`) and `result` (`saved`, `skipped`, `snoozed`).
