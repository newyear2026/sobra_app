# Play "What's new" — 1.0.15 (build 25)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself; each entry stays under its 500-character
limit. The in-app notes (`lib/data/release_notes.dart`) say the same two
things.

```
<es-419>
• Penguin ya está en la colección. Una compra única y se queda contigo.
• Mejoramos la carga y la estabilidad de los anuncios con recompensa.
</es-419>
<en-US>
• Penguin is in the collection. One purchase, and they stay.
• Improved rewarded-ad loading and reliability.
</en-US>
<pt-BR>
• O Penguin chegou à coleção. Uma compra única e ele fica com você.
• Melhoramos o carregamento e a estabilidade dos anúncios com recompensa.
</pt-BR>
<ko-KR>
• Penguin이 컬렉션에 들어왔어요. 한 번 구매하면 함께 지내요.
• 보상형 광고를 더 안정적으로 불러오도록 개선했어요.
</ko-KR>
<ja-JP>
• Penguinがコレクションに登場。一度の購入で仲間になります。
• リワード広告の読み込みと安定性を改善しました。
</ja-JP>
<de-DE>
• Penguin ist in der Sammlung. Einmal kaufen, und er bleibt.
• Das Laden von Werbung für Belohnungen ist jetzt zuverlässiger.
</de-DE>
<fr-FR>
• Penguin arrive dans la collection. Un seul achat, et il reste.
• Le chargement des publicités avec récompense est plus fiable.
</fr-FR>
```

## What this release contains

User-facing, and in the notes:

- Penguin, a paid character sold alone as `sobra.character.penguin`
  (MX$39, not in Los amigos de Michi).
- Rewarded ads: a load that timed out can no longer replace a retry's ad,
  and showing has its own timeout.

Shipped too, but not announced because nobody sees them as a change:

- `rewarded_ad_lifecycle` Analytics event with a fixed failure category.

Everything in 1.0.14+24 (the guided first expense) is included; this
build was cut after merging `feat/first-expense-flow`.
