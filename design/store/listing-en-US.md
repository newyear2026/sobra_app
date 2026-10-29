# Play 스토어 등록정보 — 영어(미국), en-US

> **한 번에 한 로케일.** Play Console에 붙여넣을 때는 이 파일 하나만 열어 두고
> **en-US** 로케일만 처리해요. 다른 언어 파일을 같이 열어 두면 섞여 들어가요.
> 아래 코드 블록은 입력란 하나에 하나씩 대응해요. 블록 안 내용만 복사하고,
> 괄호 안 글자 수는 붙여넣지 않아요.


영어는 Play에서 문안을 채우지 않은 모든 나라의 기본 노출 언어가 되기 쉬우므로
(기본 언어 fallback) 가장 먼저 채워요. 앱 안 영어 문구(`app_en.arb`)와 같은 말을 써요:
Budget, Expense, Income, Fixed expenses, Cash count, Receipt, Cycle.

---

## 앱 이름 (최대 30자)

추천:

```
Sobrita: Daily Budget Tracker
```

(29/30자)


브랜드/캐릭터를 앞세운 버전:

```
Sobrita - Spending with Michi
```

(29/30자)


---

## 간단한 설명 (최대 80자)

추천:

```
See what you can spend today. Track your expenses and budget with Michi.
```

(72/80자)


키워드를 더 넣은 버전:

```
Daily budget, expenses, income and bills — with a little cat doing the math.
```

(76/80자)


---

## 자세한 설명 (최대 4,000자)

```
Sobrita is a daily budget app and expense tracker. It shows how much money you can spend today, and keeps your expenses, income and bills in one place.

No bank login and no account: you write it down, and Michi, a little cat, does the math beside you.

What you can do with Sobrita:

• Build a budget around the way you actually get paid: monthly, twice a month, every two weeks, weekly, or with no fixed date.
• See what you have left to spend today, and what is left in the cycle.
• Record expenses and income with date, category, note and payment method.
• Attach a photo of the receipt to an expense.
• Keep fixed expenses — rent, phone, electricity — apart from your daily amount, and get a reminder before each one is due.
• Count your cash and sort out any difference without recording it twice.
• Set a limit per category and see where the cycle is heading before it closes.
• Look back at recent activity, past cycles and your daily average.
• Add the home screen widget and quick entry to log something in seconds.
• Finish the daily missions, earn XP and level up.
• Collect companions, outfits and furniture, and decorate your room.

Categories you can use from the start: Food, Transport, Shopping, Home, Bills, Health, Education, Fun, Pets and Other.

Your records and receipt photos stay on your device. You don't need an account to use the main features of Sobrita.

Sobrita does not connect to banks, does not move money, and does not offer loans or financial advice.

The app contains ads and offers optional purchases.
```

(1538/4000자)


---

## 키워드를 이렇게 고른 이유

- **`budget` / `expense tracker` / `spending`** — 미국 Play 검색에서 이 카테고리를 찾는 가장 큰 말이에요.
  앱 이름에 `Daily Budget Tracker`로 `budget`과 `tracker`를 둘 다 넣었어요.
- **`daily`** — 이 앱의 차별점이 "오늘 얼마 쓸 수 있는지"라서, 경쟁이 심한 `budget` 단독 대신
  `daily budget`이라는 덜 붐비는 조합을 노려요. 간단한 설명 첫 문장도 같은 말로 시작해요.
- **`money manager`, `finance`** 는 일부러 안 썼어요. 은행 연동 앱들이 차지한 말이라
  이 앱으로 들어온 사람이 기대와 다르다고 느끼기 쉬워요.
- 자세한 설명 첫 문장(약 150자)에 `daily budget app`, `expense tracker`, `spend today`를
  모두 넣었어요. Play는 앞부분에 더 무게를 둬요.

---

## 스크린샷과 그래픽 이미지

- **처음에는 비워 둬도 돼요.** 비우면 기본 언어 이미지가 보여요. 문안만 먼저 올려도 색인은 돼요.
- 지금 스크린샷의 큰 제목은 스페인어예요. 여유가 생기면 `design/store/build_screenshots.py`에
  이 로케일 문구를 추가하고, 앱 언어를 바꿔 화면을 다시 찍어요(`capture.py`).
- 그래픽 이미지(1024×500)는 글자가 없는 버전이라 그대로 써도 돼요.
