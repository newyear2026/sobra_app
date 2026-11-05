# Play 스토어 등록정보 — 프랑스어, fr-FR

> **한 번에 한 로케일.** Play Console에 붙여넣을 때는 이 파일 하나만 열어 두고
> **fr-FR** 로케일만 처리해요. 다른 언어 파일을 같이 열어 두면 섞여 들어가요.
> 아래 코드 블록은 입력란 하나에 하나씩 대응해요. 블록 안 내용만 복사하고,
> 괄호 안 글자 수는 붙여넣지 않아요.


프랑스는 `budget`과 `dépenses`가 둘 다 쓰여요. 프랑스 소비자 매체들도 스토어에서
`budget`, `suivi dépenses`, `gérer son budget`으로 찾으라고 안내해요. 앱 안 프랑스어
문구(`app_fr.arb`)와 같은 말을 써요: Budget, Dépense, Rentrée, Dépenses fixes, Ticket,
Comptage du liquide, tu-Form.

---

## 앱 이름 (최대 30자)

추천:

```
Sobrita : budget et dépenses
```

(28/30자)


`suivi des dépenses`를 앞세운 버전:

```
Sobrita - Suivi des dépenses
```

(28/30자)


---

## 간단한 설명 (최대 80자)

추천:

```
Vois combien tu peux dépenser aujourd’hui. Budget et dépenses avec Michi.
```

(73/80자)


동사형 검색어에 맞춘 버전:

```
Gère ton budget et suis tes dépenses au jour le jour, avec un petit chat.
```

(73/80자)


---

## 자세한 설명 (최대 4,000자)

```
Sobrita est une application de budget et de suivi des dépenses. Elle te dit combien tu peux dépenser aujourd’hui et réunit tes dépenses, tes rentrées et tes dépenses fixes.

Pas de connexion bancaire, pas de compte : tu notes, et Michi, un petit chat, fait les calculs à côté de toi.

Avec Sobrita, tu peux :

• Construire un budget qui suit la façon dont tu es payé : mensuel, deux fois par mois, tous les 14 jours, hebdomadaire ou sans date fixe.
• Voir ce qu’il te reste pour aujourd’hui et ce qu’il reste sur le cycle.
• Noter dépenses et rentrées avec date, catégorie, note et moyen de paiement.
• Attacher la photo du ticket à une dépense.
• Garder les dépenses fixes — loyer, téléphone, électricité — à part de ton montant du jour, avec un rappel avant l’échéance.
• Compter ton liquide et régler un écart sans le noter deux fois.
• Fixer une limite par catégorie et voir tôt comment le cycle va finir.
• Revoir ton activité, les cycles passés et ta moyenne par jour.
• Utiliser le widget et la saisie rapide pour noter en quelques secondes.
• Terminer les missions du jour, gagner de l’XP et monter de niveau.
• Collectionner des compagnons, des tenues et des meubles, et décorer ta maison.

Catégories disponibles dès le départ : Nourriture, Transport, Achats, Maison, Factures, Santé, Éducation, Loisirs, Animaux et Autre.

Tes enregistrements et les photos de tickets restent sur cet appareil. Tu n’as pas besoin de compte pour utiliser les fonctions principales de Sobrita.

Sobrita ne se connecte pas aux banques, ne déplace pas d’argent et ne propose ni prêt ni conseil financier.

L’application contient des publicités et propose des achats facultatifs.
```

(1668/4000자)


---

## 키워드를 이렇게 고른 이유

- **`budget`** — 프랑스에서 이 카테고리의 1순위 검색어. 이름에 넣었어요.
- **`dépenses` / `suivi des dépenses`** — 2순위이자 의도가 더 분명한 말이에요.
  이름 추천안은 `budget et dépenses`로 둘을 같이 잡고, 대안안은 `suivi des dépenses` 완전형을 써요.
- **`gérer son budget`** — 동사형으로 치는 사람이 많아서 대안 간단한 설명에 `Gère ton budget`으로 넣었어요.
- **`économiser` / `épargne`** 는 뺐어요. 저축·투자 앱을 찾는 의도라 이 앱과 안 맞아요.
- **`compte`** 도 피했어요. 프랑스에서 `compte`는 은행 계좌를 뜻해서 "계좌 연동 되는 줄 알았다"는
  오해를 부르기 쉬워요. 앱은 은행에 연결하지 않아요.
- **`dépenses fixes`, `ticket`, `liquide`** 는 앱 안에서 쓰는 말 그대로예요.
- 프랑스어 타이포그래피: 콜론 앞 공백(`Sobrita : budget`)과 아포스트로피 `’`를 앱 안 문구와 맞췄어요.

---

## 스크린샷과 그래픽 이미지

- **처음에는 비워 둬도 돼요.** 비우면 기본 언어 이미지가 보여요. 문안만 먼저 올려도 색인은 돼요.
- 지금 스크린샷의 큰 제목은 스페인어예요. 여유가 생기면 `design/store/build_screenshots.py`에
  이 로케일 문구를 추가하고, 앱 언어를 바꿔 화면을 다시 찍어요(`capture.py`).
- 그래픽 이미지(1024×500)는 글자가 없는 버전이라 그대로 써도 돼요.
