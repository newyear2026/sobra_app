# Play "What's new" — 1.0.19 (build 31)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself, and each entry stays under the
500-character limit. The in-app note (`lib/data/release_notes.dart`) covers
the same ground in two lines.

```
<es-419>
• Nuevo: Mi meta. Pon un monto o pega el enlace de algo que quieras comprar (Amazon, Mercado Libre…) y se llenan la foto y el precio.
• Al cierre de cada ciclo eliges cuánto de lo que te sobró va a tu meta. Inicio te muestra cuánto llevas y cuántos días faltan.
• ¿Ya lo compraste? Regístralo con «Lo compré con mi meta»: tu dinero de hoy y tu presupuesto no cambian.
</es-419>
<en-US>
• New: My goal. Set an amount or paste a link to something you want (Amazon, Mercado Libre…), and the photo and price fill in.
• When a cycle closes, choose how much of what’s left goes to your goal. Home shows how far along you are and how many days are left.
• Bought it? Record it with “Bought with my goal”: today’s money and your budget stay the same.
</en-US>
<pt-BR>
• Novidade: Minha meta. Defina um valor ou cole o link de algo que você quer comprar (Amazon, Mercado Livre…), e a foto e o preço aparecem sozinhos.
• No fechamento de cada ciclo, você escolhe quanto do que sobrou vai para a meta. O Início mostra quanto já juntou e quantos dias faltam.
• Comprou? Registre com “Comprei com a minha meta”: o dinheiro de hoje e o orçamento não mudam.
</pt-BR>
<ko-KR>
• 새 기능 '내 목표'. 금액을 정하거나 사고 싶은 물건 링크(Amazon, Mercado Libre 등)를 붙여넣으면 사진과 가격이 채워져요.
• 주기가 끝나면 남은 돈 중 얼마를 목표에 넣을지 골라요. 홈에서 모은 정도와 남은 날짜를 볼 수 있어요.
• 샀다면 '목표로 샀어요'로 기록하세요. 오늘 남은 돈과 예산은 그대로예요.
</ko-KR>
<ja-JP>
• 新機能「目標」。金額を決めるか、買いたいもののリンク(Amazon、Mercado Libreなど)を貼ると、写真と価格が入ります。
• サイクルの締めに、残ったお金のうち目標に回す額を選べます。ホームで貯まり具合と残り日数が分かります。
• 買ったら「目標のお金で買った」で記録。今日のお金と予算は変わりません。
</ja-JP>
<de-DE>
• Neu: Mein Ziel. Leg einen Betrag fest oder füge den Link zu etwas ein, das du kaufen möchtest (Amazon, Mercado Libre…) – Foto und Preis werden übernommen.
• Zum Zyklusende wählst du, wie viel vom Rest in dein Ziel fließt. Die Startseite zeigt deinen Fortschritt und die verbleibenden Tage.
• Gekauft? Trag es mit „Mit meinem Ziel gekauft“ ein: Dein Geld für heute und dein Budget bleiben gleich.
</de-DE>
<fr-FR>
• Nouveau : Mon objectif. Choisis un montant ou colle le lien de ce que tu veux acheter (Amazon, Mercado Libre…), la photo et le prix se remplissent.
• À la clôture de chaque cycle, tu choisis combien de ce qui reste va à ton objectif. L’accueil montre où tu en es et les jours restants.
• Tu l’as acheté ? Note-le avec « Acheté avec mon objectif » : ton argent du jour et ton budget ne changent pas.
</fr-FR>
```

## What this release contains

User-facing, and in the notes:

- **Mi meta (savings goal).** One active goal, either an amount or a
  product. A product goal reads its photo, name and price from an Amazon
  México, Mercado Libre, Walmart or SHEIN link in an in-app browser. Every
  value can be edited before saving. A target date is optional.
- When a cycle closes with money left, a popup offers to put all or part of
  it toward the goal. The same popup shows the cycle's XP and links to the
  full summary. Older cycles can be added later from Presupuesto → past
  cycles. Income recorded as savings also counts.
- The home card shows progress and a date line:
  - D-n within 31 days of the target date
  - an amount per pay cycle when the date is further away
  - the remaining amount when there is no date
- **Lo compré con mi meta.** Records the purchase as a shopping expense
  outside the budget, the same way fixed payments are. It can re-read
  today's price from the link and is capped at what was saved. The goal
  moves to the history, and what is left can start the next goal.

Shipped too, but not announced:

- A native ad under the last category on Presupuesto. It uses the
  Movimientos ad unit until a `native_budget` unit exists.
- Native ads keep a 3-minute gap per slot (Movimientos, Presupuesto, exit)
  instead of one shared 5-minute gap.
- Link import reads Amazon's mobile title (not its "El resumen del producto"
  heading). It also ignores Mercado Libre's colour-thumbnail prices.
