# Play "What's new" — 1.0.17 (build 28)

Paste the block below into Play Console → Release → Release notes. Play
reads the language tags itself; each entry stays under its 500-character
limit. The in-app note (`lib/data/release_notes.dart`) says the same thing.

```
<es-419>
• Ahora puedes eliminar un gasto desde la pantalla donde lo editas.
</es-419>
<en-US>
• You can now delete an expense from the screen where you edit it.
</en-US>
<pt-BR>
• Agora dá para apagar um gasto na mesma tela em que você o edita.
</pt-BR>
<ko-KR>
• 지출을 수정하는 화면에서도 바로 삭제할 수 있어요.
</ko-KR>
<ja-JP>
• 支出の編集画面からも、そのまま削除できるようになりました。
</ja-JP>
<de-DE>
• Du kannst eine Ausgabe jetzt direkt beim Bearbeiten löschen.
</de-DE>
<fr-FR>
• Tu peux maintenant supprimer une dépense depuis son écran de modification.
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

Shipped too, but not announced:

- The delete notice replaces whatever snack bar is up, so its undo no longer
  waits unseen behind the XP notice from the expense just recorded.

The 1.0.16 costume gift keeps its daily card through 11/3 on this version:
that card follows the note that brought the gift, not the running version.
