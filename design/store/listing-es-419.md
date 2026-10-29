# Play 스토어 등록정보 — 스페인어(라틴아메리카), es-419

> **한 번에 한 로케일.** Play Console에 붙여넣을 때는 이 파일 하나만 열어 두고
> **es-419** 로케일만 처리해요. 다른 언어 파일을 같이 열어 두면 섞여 들어가요.
> 아래 코드 블록은 입력란 하나에 하나씩 대응해요. 블록 안 내용만 복사하고,
> 괄호 안 글자 수는 붙여넣지 않아요.


⚠️ **이 로케일은 이미 라이브일 가능성이 높아요.** 기존 `listing-pt-BR.md`가
"현재 스페인어(es-419) 등록정보를 바탕으로" 썼다고 적혀 있어요. 즉 이 파일은 *추가*가 아니라
*교체* 후보예요. Play Console에서 현재 들어가 있는 문안을 먼저 복사해 두고 비교한 뒤 바꿔요.

es-ES가 아니라 es-419인 이유: 앱 안 스페인어 문구(`app_es.arb`)가 라틴아메리카 말이에요
(`Renta`, `celular`, `luz`, `Taquería El Faro`). es-ES로 올리면 말이 안 맞아요.

---

## 앱 이름 (최대 30자)

추천:

```
Sobrita: Control de Gastos
```

(26/30자)


현재 쓰고 있을 것으로 보이는 버전(브랜드 중심):

```
Sobrita - Gastos y amiguitos
```

(28/30자)


---

## 간단한 설명 (최대 80자)

추천:

```
Controla tus gastos y mira cuánto puedes gastar hoy, con el gatito Michi.
```

(73/80자)


키워드를 더 넣은 버전:

```
Tu presupuesto diario, gastos, ingresos y pagos fijos, con la compañía de Michi.
```

(80/80자)


---

## 자세한 설명 (최대 4,000자)

```
Sobrita es una app de control de gastos y presupuesto personal. Te dice cuánto puedes gastar hoy y guarda tus gastos, ingresos y pagos fijos en un solo lugar.

Sin cuenta y sin conectar el banco: tú lo anotas y Michi, un gatito, hace las cuentas a tu lado.

Con Sobrita puedes:

• Armar un presupuesto según cómo te pagan: mensual, dos veces al mes, cada 14 días, semanal o sin fecha fija.
• Ver cuánto te queda para hoy y cuánto te queda en el ciclo.
• Anotar gastos e ingresos con fecha, categoría, nota y forma de pago.
• Guardar la foto del ticket junto al gasto.
• Separar los gastos fijos —renta, celular, luz— de tu gasto diario, con un recordatorio antes de cada pago.
• Contar tu efectivo y aclarar cualquier diferencia sin anotarla dos veces.
• Poner un límite por categoría y ver cómo va a terminar el ciclo antes de que cierre.
• Revisar tus movimientos, los ciclos pasados y tu promedio diario.
• Usar el widget y el registro rápido para anotar en segundos.
• Completar las misiones del día, ganar experiencia y subir de nivel.
• Reunir personajes, ropita y muebles para decorar tu casa.

Categorías listas desde el principio: Comida, Transporte, Compras, Hogar, Servicios, Salud, Educación, Diversión, Mascotas y Otros.

Tus registros y las fotos de tickets se guardan en tu dispositivo. No necesitas una cuenta para usar las funciones principales de Sobrita.

Sobrita no se conecta a bancos, no mueve dinero y no ofrece préstamos ni asesoría financiera.

La app contiene anuncios y ofrece compras opcionales.
```

(1523/4000자)


---

## 키워드를 이렇게 고른 이유

- **`control de gastos`** — 라틴아메리카에서 이 카테고리를 찾을 때 가장 많이 치는 말이에요.
  `presupuesto`보다 생활 밀착형이고, `finanzas personales`보다 덜 붐벼요. 앱 이름에 넣었어요.
- **`presupuesto` / `gastar hoy`** — 간단한 설명과 자세한 설명 첫 문장에 넣어 보조 키워드로 써요.
- **`ahorrar`** 는 일부러 뒤로 뺐어요. 저축 앱을 찾는 사람이 들어오면 기대와 달라요.
- **`gastos fijos`, `ticket`, `efectivo`** 는 앱 안에서 실제로 쓰는 말이라(`app_es.arb`)
  설명과 화면이 어긋나지 않아요. 긴 꼬리 검색어로도 걸려요.

---

## 스크린샷과 그래픽 이미지

- **처음에는 비워 둬도 돼요.** 비우면 기본 언어 이미지가 보여요. 문안만 먼저 올려도 색인은 돼요.
- 지금 스크린샷의 큰 제목은 스페인어예요. 여유가 생기면 `design/store/build_screenshots.py`에
  이 로케일 문구를 추가하고, 앱 언어를 바꿔 화면을 다시 찍어요(`capture.py`).
- 그래픽 이미지(1024×500)는 글자가 없는 버전이라 그대로 써도 돼요.
