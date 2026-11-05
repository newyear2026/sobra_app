# Play 스토어 등록정보 — 독일어, de-DE

> **한 번에 한 로케일.** Play Console에 붙여넣을 때는 이 파일 하나만 열어 두고
> **de-DE** 로케일만 처리해요. 다른 언어 파일을 같이 열어 두면 섞여 들어가요.
> 아래 코드 블록은 입력란 하나에 하나씩 대응해요. 블록 안 내용만 복사하고,
> 괄호 안 글자 수는 붙여넣지 않아요.


독일은 「Haushaltsbuch」가 카테고리 대표어예요. 영어 `budget app`을 직역한
`Budget-App`으로는 잘 안 걸려요. 독일어는 단어가 길어서 30자 제한을 넘기기 쉬우니
이름은 짧게 가고 키워드는 간단한 설명으로 밀었어요. 앱 안 독일어 문구(`app_de.arb`)와
같은 말을 써요: Budget, Ausgabe, Einnahme, Fixkosten, Beleg, Kassensturz, du-Form.

---

## 앱 이름 (최대 30자)

추천:

```
Sobrita: Haushaltsbuch
```

(22/30자)


키워드를 하나 더 넣은 버전(30자 한계까지):

```
Sobrita Haushaltsbuch Budget
```

(28/30자)


---

## 간단한 설명 (최대 80자)

추천:

```
Sieh, wie viel du heute ausgeben kannst. Ausgaben und Budget mit Katze Michi.
```

(77/80자)


카테고리어를 앞세운 버전:

```
Haushaltsbuch mit Katze: Ausgaben, Einnahmen und Fixkosten ganz ohne Druck.
```

(75/80자)


---

## 자세한 설명 (최대 4,000자)

```
Sobrita ist ein Haushaltsbuch für den Alltag. Die App zeigt dir, wie viel Geld du heute ausgeben kannst, und sammelt Ausgaben, Einnahmen und Fixkosten an einem Ort.

Keine Bankverbindung, kein Konto: Du trägst es ein, und Michi, eine kleine Katze, rechnet neben dir mit.

Das kannst du mit Sobrita machen:

• Ein Budget aufsetzen, das zu deinem Geldeingang passt: monatlich, zweimal im Monat, alle 14 Tage, wöchentlich oder ohne festes Datum.
• Sehen, wie viel dir heute bleibt und wie viel im Zyklus übrig ist.
• Ausgaben und Einnahmen mit Datum, Kategorie, Notiz und Zahlungsart eintragen.
• Das Foto vom Beleg direkt an die Ausgabe hängen.
• Fixkosten wie Miete, Handy und Strom getrennt vom Tagesbetrag führen, mit Erinnerung vor dem Fälligkeitstag.
• Mit dem Kassensturz dein Bargeld zählen und eine Differenz klären, ohne sie doppelt zu buchen.
• Pro Kategorie ein Limit setzen und früh sehen, wie der Zyklus ausgeht.
• Verlauf, vergangene Zyklen und deinen Tagesdurchschnitt nachlesen.
• Widget und Schnelleingabe nutzen und in Sekunden etwas eintragen.
• Die Tagesmissionen schaffen, XP sammeln und aufsteigen.
• Begleiter, Kostüme und Möbel sammeln und dein Zuhause einrichten.

Kategorien, die von Anfang an bereitstehen: Essen, Transport, Einkäufe, Zuhause, Rechnungen, Gesundheit, Bildung, Freizeit, Haustiere und Sonstiges.

Deine Einträge und Belegfotos bleiben auf diesem Gerät. Für die Hauptfunktionen von Sobrita brauchst du kein Konto.

Sobrita verbindet sich nicht mit Banken, bewegt kein Geld und bietet weder Kredite noch Finanzberatung an.

Die App enthält Werbung und bietet optionale Käufe.
```

(1614/4000자)


---

## 키워드를 이렇게 고른 이유

- **`Haushaltsbuch`** — 독일 Play에서 이 카테고리를 찾는 대표어예요. 독일 비교 기사들도
  "스토어에 `Haushaltsbuch`를 치면 된다"고 그대로 안내해요. 이름에 넣었어요.
- **`Ausgaben`** — `Haushaltsbuch` 다음으로 많이 치는 말. 이름에는 자리가 없어서
  간단한 설명 앞쪽과 자세한 설명 첫 문장에 넣었어요.
- **`Budget`** — 독일 사용자도 쓰지만 영어 차용어라 단독 검색은 적어요. 보조로만 써요.
- **`Finanzen` / `Geld verwalten`** 는 일부러 피했어요. 은행 연동·투자 앱이 차지한 말이라
  "계좌 연결 안 되네"라는 리뷰를 부르기 쉬워요.
- **`Fixkosten`, `Beleg`, `Kassensturz`** 는 앱 안에서 쓰는 말 그대로예요.
  `Kassensturz`는 검색량이 작지만 경쟁이 거의 없어서 긴 꼬리로 값이 있어요.
- 30자 제한 때문에 `Sobrita: Haushaltsbuch & Budget`(31자)은 못 써요. 대안 이름은
  구두점을 빼서 `Budget`까지 밀어 넣은 28자 버전이에요.

---

## 스크린샷과 그래픽 이미지

- **처음에는 비워 둬도 돼요.** 비우면 기본 언어 이미지가 보여요. 문안만 먼저 올려도 색인은 돼요.
- 지금 스크린샷의 큰 제목은 스페인어예요. 여유가 생기면 `design/store/build_screenshots.py`에
  이 로케일 문구를 추가하고, 앱 언어를 바꿔 화면을 다시 찍어요(`capture.py`).
- 그래픽 이미지(1024×500)는 글자가 없는 버전이라 그대로 써도 돼요.
