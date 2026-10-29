# Play "What's new" — 1.0.17 (build 28)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself; each entry stays under its 500-character
limit. The in-app note (`lib/data/release_notes.dart`) says the same three
things.

```
<es-419>
• Ahora puedes eliminar un gasto desde la pantalla donde lo editas.
• Puedes cambiar la fecha de un gasto o un ingreso, y ahora los ingresos también se editan.
• Inicio te dice cuánto te sobrará al cierre del ciclo si sigues a este ritmo.
</es-419>
<en-US>
• You can now delete an expense from the screen where you edit it.
• You can change the date of an expense or an income, and incomes can now be edited too.
• Home shows how much you’ll have left when the cycle closes at your current pace.
</en-US>
<pt-BR>
• Agora dá para apagar um gasto na mesma tela em que você o edita.
• Dá para mudar a data de um gasto ou de uma entrada, e agora as entradas também podem ser editadas.
• O Início mostra quanto vai sobrar no fechamento do ciclo nesse ritmo.
</pt-BR>
<ko-KR>
• 지출을 수정하는 화면에서도 바로 삭제할 수 있어요.
• 지출과 수입의 날짜를 바꿀 수 있고, 이제 수입도 수정할 수 있어요.
• 홈에서 지금 속도라면 주기 마감 때 얼마가 남을지 바로 보여요.
</ko-KR>
<ja-JP>
• 支出の編集画面からも、そのまま削除できるようになりました。
• 支出と収入の日付を変えられるようになり、収入も編集できるようになりました。
• ホームで、今のペースなら周期の締めにいくら残るかがすぐ分かります。
</ja-JP>
<de-DE>
• Du kannst eine Ausgabe jetzt direkt beim Bearbeiten löschen.
• Du kannst das Datum einer Ausgabe oder Einnahme ändern, und Einnahmen lassen sich jetzt auch bearbeiten.
• Die Startseite zeigt, wie viel dir in diesem Tempo zum Zyklusende bleibt.
</de-DE>
<fr-FR>
• Tu peux maintenant supprimer une dépense depuis son écran de modification.
• Tu peux changer la date d’une dépense ou d’une rentrée, et les rentrées se modifient aussi maintenant.
• L’accueil montre ce qu’il te restera à la clôture du cycle à ce rythme.
</fr-FR>
```

## What this release contains

User-facing, and in the notes:

- Tapping an expense in Movimientos opens its edit sheet, which now has an
  **Eliminar** button under **Guardar cambios**. It deletes through the same
  path as the row's ⋮ menu, with the same undo. Prompted by a Play review
  (pt, 10/28) that read the ⋮-only delete as a bug.
- An expense made by a cash count shows why it cannot be deleted in that
  spot, instead of a button that is silently missing.
- The expense sheet has a date row, the register screen's, with its range.
  A fixed-expense payment moves the day it was paid ("Día en que lo
  pagaste") and keeps the installment it settles, which is a separate
  field. Only a cash count's date stays locked, like its amount.
- Incomes open an edit sheet from their row and their ⋮ menu: amount, kind,
  this cycle or savings, cash or account, note, date, and delete. A new date
  or a switch to savings moves the money with it. Cash-count incomes still
  have no editor.
- Inicio shows the budget tab's projection under today's figure ("A este
  ritmo, al cierre del …"), and the tap opens Presupuesto. On the budget tab
  that card moved up under the ring, says the daily average it rests on,
  and lists income put into savings this cycle and what closed cycles left,
  overruns netted. Both from a Play review (es, 10/29) that asked for
  editable dates and savings estimates.

Shipped too, but not announced:

- The projection is rounded to whole units, like the daily average.
- Edit sheets stop under the status bar and scroll when they run tall.
- A moved date keeps the entry's time of day, so moving it away and back
  lands where it started. A time still to come today is pulled back to now.
- The delete notice replaces whatever snack bar is up, so its undo no longer
  waits unseen behind the XP notice from the expense just recorded.

The 1.0.16 costume gift keeps its daily card through 11/3 on this version:
that card follows the note that brought the gift, not the running version.
