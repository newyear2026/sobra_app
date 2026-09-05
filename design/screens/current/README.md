# Capturas del build actual

Pantallas reales del app, no mockups: salen de `flutter build web` corrido sobre
la rama de trabajo y fotografiado en Chromium a 390x844 px con densidad 3x
(iPhone 14, locale `es-MX`).

| Archivo | Pantalla |
| --- | --- |
| `00-overview.png` | Hoja de contacto con las ocho pantallas |
| `01-onboarding.png` | Onboarding, instalacion limpia |
| `02-home.png` | Inicio |
| `03-movimientos.png` | Movimientos |
| `04-registrar.png` | Registrar |
| `05-presupuesto.png` | Presupuesto |
| `06-ajustes.png` | Ajustes |
| `07-conteo-efectivo.png` | Conteo de efectivo, con un faltante capturado |
| `08-niveles-xp.png` | Historial de XP |

Todas menos el onboarding usan un estado sembrado en `localStorage`
(`flutter.sobra_state_v2`): quincena del 1 al 15 de septiembre de 2026,
presupuesto de $6,000 MXN, diez gastos, dos ingresos y cinco eventos de XP.
Es solo data de demo para que las pantallas no salgan vacias.
