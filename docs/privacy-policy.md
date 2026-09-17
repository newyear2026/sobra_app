# Sobrita 개인정보처리방침 / Aviso de Privacidad / Privacy Policy

> **출시 전 필수:** 아래 세 값을 실제 정보로 교체한 뒤 공개하세요.
> 회사가 없다면 `{{LEGAL_NAME}}`에는 개인 개발자의 법적 성명을 씁니다.
> `{{POSTAL_ADDRESS}}`에는 회사 주소가 아니라도 실제로 통지를 받을 수 있는 주소를 씁니다.
> 자택 공개가 부담되면 우편 수령이 가능한 가상 오피스·공유 오피스 등의 주소를 정식으로 확보한 뒤 사용하세요.
> 이메일만 적거나 실제 관계없는 주소를 쓰는 것은 권장하지 않습니다.
>
> - `{{LEGAL_NAME}}`: 회사명 또는 개인 개발자의 법적 성명
> - `{{POSTAL_ADDRESS}}`: 법적 통지를 받을 수 있는 실제 주소
> - `{{PRIVACY_EMAIL}}`: 개인정보 문의를 받을 이메일
>
> 기준 문서: 이 Markdown 파일이 정책 원본입니다. `privacy-policy.html`은 스토어에 제출할 공개 웹페이지입니다.

- 시행일 / Fecha de entrada en vigor / Effective date: 2026-09-15
- 최종 업데이트 / Última actualización / Last updated: 2026-09-15
- 앱 / Aplicación / App: **Sobrita** (`com.sobra.app.sobra_app`)

---

## 한국어

### 1. 적용 범위 및 개인정보처리자

이 개인정보처리방침은 **Sobrita** 모바일 애플리케이션(이하 “앱”)에 적용됩니다.

- 개인정보처리자: `{{LEGAL_NAME}}`
- 주소: `{{POSTAL_ADDRESS}}`
- 개인정보 문의: `{{PRIVACY_EMAIL}}`

Sobrita는 별도의 회원가입 없이 기기에서 사용할 수 있는 가계부 앱입니다. 핵심 가계부 데이터는 개발자가 운영하는 서버로 전송되지 않습니다. 다만 운영체제 백업, 앱 마켓 결제 및 광고 기능을 사용할 때는 아래에 설명한 제3자가 정보를 처리할 수 있습니다.

### 2. 앱이 처리하는 정보

#### 사용자가 입력하는 가계부 정보

사용자가 예산, 수입·지출 금액, 날짜, 카테고리, 메모, 현금 계산 결과, 통화·언어·화면 설정, 미션·XP 및 컬렉션 진행도를 입력하거나 생성할 수 있습니다. 이 정보는 앱의 로컬 저장공간에 저장되며 개발자의 서버로 자동 전송되지 않습니다.

#### 영수증 사진

사용자가 선택한 경우에만 카메라 또는 사진 보관함에서 영수증 이미지를 가져옵니다. 이미지는 크기를 줄여 앱 전용 로컬 저장공간에 보관하며 개발자에게 전송하지 않습니다. 거래에서 영수증을 제거하면 해당 파일을 삭제하고, 앱이 참조하지 않는 영수증 파일도 정리합니다.

앱의 JSON 백업에는 영수증 이미지가 포함되지 않습니다. Android 클라우드 백업에서도 영수증 이미지는 제외되지만, 기기 간 직접 전송에는 포함될 수 있습니다.

#### 로컬 알림과 위젯

사용자가 빠른 입력 알림을 켜면 Android 알림 권한과 부팅 완료 신호를 사용하여 기기에서 지속 알림을 복원할 수 있습니다. 홈 화면 위젯과 알림에는 앱에 저장된 일부 요약 정보가 표시될 수 있습니다. 원격 푸시 알림 서버는 사용하지 않습니다.

#### 사용자가 내보내는 백업

사용자가 설정에서 백업을 실행하면 가계부 데이터가 JSON 텍스트로 기기의 클립보드에 복사됩니다. 이후 어디에 붙여넣거나 공유할지는 사용자가 결정합니다. 클립보드에 복사된 데이터는 운영체제 또는 사용자가 선택한 다른 앱의 처리 대상이 될 수 있습니다.

#### 운영체제 백업

기기의 백업 기능이 켜져 있으면 앱 설정과 가계부 기록이 Google 또는 Apple과 같은 운영체제 백업 제공자에게 백업되거나 새 기기로 전송될 수 있습니다. 이러한 처리는 사용자의 기기·계정 설정과 해당 제공자의 정책을 따릅니다. Android 클라우드 백업은 영수증 사진을 제외합니다.

### 3. 광고와 Google AdMob

Android 버전은 사용자가 선택하여 보는 보상형 광고와 거래 내역의 네이티브 광고를 제공하기 위해 Google Mobile Ads SDK(AdMob) 및 Google User Messaging Platform(UMP)을 사용합니다.

Google의 안내에 따르면 Mobile Ads SDK는 다음 정보를 자동으로 수집하거나 Google과 공유할 수 있습니다.

- IP 주소(일반적인 위치를 추정하는 데 사용될 수 있음)
- 앱 실행, 탭, 광고 노출·조회와 같은 앱 또는 광고 상호작용
- 비정상 종료 로그, 실행 시간, 배터리 사용량과 같은 진단 정보
- Android 광고 ID, 앱 세트 ID 등 기기 또는 계정 식별자

Google은 이 정보를 광고 제공·측정·개인화(허용된 경우), 분석, 사기 방지와 보안 목적으로 처리할 수 있습니다. 광고 SDK의 네트워크 전송에는 TLS가 사용됩니다. 앱에 입력한 거래 금액, 예산, 메모 및 영수증 사진을 개발자가 AdMob에 광고 타기팅 정보로 제공하지 않습니다.

관련 지역에서는 UMP를 통해 필요한 동의를 요청합니다. 동의가 필요한 경우 사용자는 앱 설정의 **개인정보 선택**에서 결정을 다시 확인하거나 변경할 수 있습니다. 광고 개인화 가능 여부와 실제 표시되는 광고는 사용자의 선택, 지역, 기기 설정 및 Google 정책에 따라 달라질 수 있습니다.

자세한 내용은 [Google 개인정보처리방침](https://policies.google.com/privacy), [Google 파트너 사이트 또는 앱의 정보 사용 방식](https://policies.google.com/technologies/partner-sites), [Google Mobile Ads SDK 데이터 공개 안내](https://developers.google.com/admob/android/privacy/play-data-disclosure)를 확인하세요.

### 4. 앱 내 구매

유료 아이템을 구매하거나 복원할 때 결제는 Google Play 또는 Apple App Store가 처리합니다. Sobrita는 카드번호나 은행계좌 정보를 직접 수집하지 않습니다. 앱은 상품 제공과 복원을 위해 상품 ID, 구매 상태, 구매 식별자 또는 검증 정보와 같은 결제 결과를 앱 마켓에서 받을 수 있습니다. 앱 마켓의 정보 처리는 각 제공자의 개인정보처리방침을 따릅니다.

### 5. 권한

- **카메라 및 사진:** 사용자가 영수증 사진을 직접 촬영하거나 선택할 때만 사용합니다.
- **알림:** 사용자가 빠른 지출 입력 알림을 켰을 때 사용합니다. 기기 설정에서 언제든 끌 수 있습니다.
- **부팅 완료:** 사용자가 켜 둔 빠른 입력 알림을 재부팅 후 복원하는 데 사용합니다.
- **인터넷:** 광고·동의 메시지 및 앱 마켓 구매 기능에 사용합니다.

### 6. 제3자 제공, 판매 및 국외 처리

개발자는 사용자의 가계부 원문이나 영수증 사진을 판매하지 않습니다. 기능 제공에 필요한 범위에서 다음 제3자가 정보를 처리할 수 있습니다.

- Google: AdMob 광고, UMP 동의 관리, Google Play 결제 및 Android 백업
- Apple: App Store 결제 및 기기 백업(해당 플랫폼에서 사용하는 경우)

Google과 Apple은 사용자의 거주 국가 밖에서 정보를 처리할 수 있습니다. 구체적인 처리 장소와 보호조치는 각 회사의 정책을 따릅니다. 법률상 의무, 법적 절차, 권리·안전 보호를 위해 필요한 경우에도 법이 허용하는 범위에서 정보를 공개할 수 있습니다.

### 7. 보관 및 삭제

로컬 가계부 데이터는 사용자가 앱 안에서 삭제하거나 앱 데이터 삭제 또는 앱 제거를 실행할 때까지 기기에 남습니다. 운영체제 백업에 저장된 사본은 사용자의 백업 설정과 백업 제공자의 보관 정책에 따라 더 오래 남거나 재설치 시 복원될 수 있습니다.

개발자는 핵심 가계부 정보를 서버에 보관하지 않으므로 사용자의 기기 안에 있는 기록을 원격으로 열람하거나 삭제할 수 없습니다. 기기 데이터는 앱에서 개별 기록을 삭제하거나, 운영체제 설정에서 앱 데이터를 삭제하거나, 앱을 제거하여 삭제할 수 있습니다. 운영체제 백업 사본은 Google 또는 Apple 계정의 백업 설정에서 관리해야 합니다.

광고 및 결제와 관련해 Google 또는 Apple이 처리하는 정보의 보관·삭제는 각 제공자의 정책과 사용자의 계정 설정을 따릅니다.

### 8. 보안

가계부 데이터와 영수증 사진은 운영체제가 보호하는 앱 전용 저장공간에 보관합니다. 제3자 서비스와의 통신에는 해당 서비스가 제공하는 전송 보안이 적용됩니다. 합리적인 보호조치를 사용하지만 어떠한 저장 또는 전송 방식도 절대적인 안전을 보장할 수는 없습니다.

### 9. 이용자의 권리

적용되는 법률에 따라 이용자는 개인정보에 대한 접근, 정정, 삭제·취소, 처리 반대 또는 동의 철회를 요청할 수 있습니다. 멕시코 이용자는 ARCO 권리(접근, 정정, 취소, 반대)를 행사할 수 있습니다.

요청 시 `{{PRIVACY_EMAIL}}`로 다음 내용을 보내 주세요.

- 요청자의 이름과 회신 가능한 연락처
- 원하는 조치와 관련 정보에 대한 설명
- 본인 확인에 합리적으로 필요한 정보

개발자가 보유하지 않는 기기 내 데이터는 위 7절의 방법으로 직접 관리해야 합니다. Google 또는 Apple이 독립적으로 처리하는 정보에 관한 요청은 해당 제공자에게 제출해야 합니다.

### 10. 아동의 개인정보

Sobrita는 아동을 대상으로 설계된 서비스가 아닙니다. 법정대리인이 아동의 정보가 앱 외부에서 개발자에게 전달되었다고 판단하는 경우 `{{PRIVACY_EMAIL}}`로 연락해 주세요. 확인 후 관련 법률에 따라 조치합니다.

### 11. 방침 변경 및 문의

기능, 제3자 서비스 또는 법적 요구사항이 변경되면 이 방침을 수정할 수 있습니다. 중요한 변경은 앱, 스토어 설명 또는 이 페이지를 통해 알리고 상단의 최종 업데이트 날짜를 변경합니다.

이 방침에 관한 문의: `{{PRIVACY_EMAIL}}`

---

## Español

### 1. Alcance y responsable

Este Aviso de Privacidad se aplica a la aplicación móvil **Sobrita** (la “Aplicación”).

- Responsable: `{{LEGAL_NAME}}`
- Domicilio: `{{POSTAL_ADDRESS}}`
- Contacto de privacidad: `{{PRIVACY_EMAIL}}`

Sobrita es una aplicación de presupuesto que puede utilizarse sin crear una cuenta. Los datos principales de presupuesto se guardan en el dispositivo y no se envían automáticamente a un servidor operado por el responsable. Sin embargo, el proveedor de respaldo del sistema operativo, la tienda de aplicaciones y los servicios publicitarios pueden tratar datos según se describe a continuación.

### 2. Información tratada por la Aplicación

#### Información presupuestaria introducida por la persona usuaria

La persona usuaria puede introducir o generar presupuestos, ingresos y gastos, importes, fechas, categorías, notas, conteos de efectivo, moneda e idioma, preferencias, misiones, XP y progreso de colección. Esta información se guarda en el almacenamiento local de la Aplicación y no se transmite automáticamente al servidor del responsable.

#### Fotografías de recibos

Solo cuando la persona usuaria lo decide, la Aplicación permite tomar o elegir una fotografía de un recibo. La imagen se reduce y se guarda en el espacio privado de la Aplicación; no se envía al responsable. Al quitar un recibo de un movimiento se elimina su archivo, y la Aplicación también limpia fotografías que ya no estén asociadas a un movimiento.

Las fotografías no forman parte de la copia de seguridad JSON. También se excluyen del respaldo en la nube de Android, aunque podrían incluirse en una transferencia directa entre dispositivos.

#### Notificaciones locales y widgets

Si la persona usuaria habilita el acceso rápido, la Aplicación usa el permiso de notificaciones de Android y la señal de reinicio para restaurar una notificación persistente en el dispositivo. Los widgets y la notificación pueden mostrar resúmenes de datos guardados en la Aplicación. No se utiliza un servidor de notificaciones push remotas.

#### Copia de seguridad exportada por la persona usuaria

Cuando la persona usuaria crea una copia de seguridad desde Ajustes, los datos se copian como texto JSON al portapapeles del dispositivo. La persona usuaria decide dónde pegarlos o compartirlos. Una vez en el portapapeles, el sistema operativo u otras aplicaciones elegidas por la persona usuaria pueden tratar esos datos.

#### Respaldo del sistema operativo

Si el respaldo del dispositivo está habilitado, los registros y preferencias de la Aplicación pueden respaldarse con el proveedor del sistema operativo, como Google o Apple, o transferirse a un dispositivo nuevo. Este tratamiento depende de la configuración de la cuenta y del dispositivo y de las políticas del proveedor. El respaldo en la nube de Android excluye las fotografías de recibos.

### 3. Publicidad y Google AdMob

La versión para Android utiliza Google Mobile Ads SDK (AdMob) y Google User Messaging Platform (UMP) para mostrar anuncios recompensados elegidos por la persona usuaria y anuncios nativos en el historial de movimientos.

De acuerdo con la documentación de Google, Mobile Ads SDK puede recopilar automáticamente o compartir con Google:

- dirección IP, que puede utilizarse para estimar una ubicación general;
- interacciones con la Aplicación o los anuncios, como aperturas, toques, impresiones y visualizaciones de video;
- información de diagnóstico, como registros de fallos, tiempo de inicio y uso de batería; e
- identificadores de dispositivo o cuenta, como el ID de publicidad de Android y el ID del conjunto de aplicaciones.

Google puede tratar esta información para ofrecer, medir y —cuando esté permitido— personalizar publicidad, realizar análisis, prevenir fraude y mantener la seguridad. Google indica que los datos del SDK se cifran en tránsito mediante TLS. El responsable no proporciona a AdMob importes de movimientos, presupuestos, notas ni fotografías de recibos como datos para segmentar publicidad.

Cuando sea aplicable, UMP solicita las decisiones de consentimiento necesarias. Si la normativa requiere ofrecerlas, la persona usuaria puede revisar o cambiar sus decisiones desde **Opciones de privacidad** en Ajustes. La personalización y los anuncios mostrados dependen de la elección de la persona usuaria, su región, la configuración del dispositivo y las políticas de Google.

Para más información, consulta la [Política de Privacidad de Google](https://policies.google.com/privacy), [cómo usa Google la información de sitios o aplicaciones que utilizan sus servicios](https://policies.google.com/technologies/partner-sites) y la [divulgación de datos de Google Mobile Ads SDK](https://developers.google.com/admob/android/privacy/play-data-disclosure).

### 4. Compras dentro de la Aplicación

Google Play o Apple App Store procesan el pago y la restauración de artículos de pago. Sobrita no recibe directamente números de tarjeta ni datos bancarios. Para entregar y restaurar una compra, la Aplicación puede recibir de la tienda el ID del producto, el estado de compra, un identificador de compra o información de verificación. El tratamiento de la tienda se rige por la política de privacidad de su proveedor.

### 5. Permisos

- **Cámara y fotos:** se utilizan únicamente cuando la persona usuaria toma o selecciona una foto de un recibo.
- **Notificaciones:** se utilizan si la persona usuaria habilita la notificación de acceso rápido. Pueden deshabilitarse en los ajustes del dispositivo.
- **Inicio del dispositivo:** permite restaurar la notificación de acceso rápido que la persona usuaria dejó habilitada.
- **Internet:** se utiliza para publicidad, mensajes de consentimiento y compras de la tienda.

### 6. Terceros, venta y transferencias internacionales

El responsable no vende el contenido de los registros financieros ni las fotografías de recibos. Para prestar las funciones descritas, los siguientes terceros pueden tratar información:

- Google: AdMob, UMP, compras de Google Play y respaldo de Android.
- Apple: compras de App Store y respaldo del dispositivo, cuando corresponda.

Google y Apple pueden tratar información fuera del país de residencia de la persona usuaria. Las ubicaciones y salvaguardas concretas se rigen por sus respectivas políticas. También podrán comunicarse datos cuando sea necesario para cumplir una obligación legal, un proceso jurídico o proteger derechos y seguridad, dentro de lo permitido por la ley.

### 7. Conservación y eliminación

Los datos locales permanecen en el dispositivo hasta que la persona usuaria borra los registros dentro de la Aplicación, elimina los datos de la Aplicación o la desinstala. Las copias del sistema operativo pueden conservarse por más tiempo o restaurarse después, de acuerdo con la configuración y política del proveedor del respaldo.

Como el responsable no conserva los registros principales en un servidor, no puede acceder ni borrarlos de forma remota. La persona usuaria puede borrar movimientos dentro de la Aplicación, borrar los datos desde el sistema operativo o desinstalarla. Los respaldos deben administrarse en la cuenta de Google o Apple correspondiente.

La conservación y eliminación de datos publicitarios o de compras tratados por Google o Apple se rigen por las políticas y controles de cuenta de cada proveedor.

### 8. Seguridad

Los registros y fotografías se guardan en el espacio privado que el sistema operativo asigna a la Aplicación. Las comunicaciones con terceros utilizan las medidas de transporte ofrecidas por esos servicios. Aplicamos medidas razonables, pero ningún método de almacenamiento o transmisión puede garantizar seguridad absoluta.

### 9. Derechos ARCO y otros derechos

Según la ley aplicable, la persona titular puede solicitar acceso, rectificación, cancelación o eliminación, oposición al tratamiento o revocación del consentimiento. En México, estos derechos se conocen como derechos ARCO.

Para ejercerlos, envía a `{{PRIVACY_EMAIL}}`:

- nombre y medio para recibir una respuesta;
- descripción clara del derecho que deseas ejercer y de la información relacionada; y
- información razonablemente necesaria para verificar la identidad.

Los datos que solo existen en el dispositivo deben gestionarse mediante los controles indicados en la sección 7. Para datos tratados de manera independiente por Google o Apple, la solicitud debe dirigirse al proveedor correspondiente.

### 10. Privacidad de menores

Sobrita no está diseñada para menores. Si una madre, padre o tutor considera que información de un menor fue enviada al responsable fuera de la Aplicación, puede escribir a `{{PRIVACY_EMAIL}}`. Tras verificarlo, se actuará conforme a la ley aplicable.

### 11. Cambios y contacto

Este Aviso puede actualizarse cuando cambien las funciones, los terceros utilizados o las obligaciones legales. Los cambios importantes se comunicarán en la Aplicación, en la ficha de la tienda o en esta página y se modificará la fecha de actualización.

Contacto: `{{PRIVACY_EMAIL}}`

---

## English

### 1. Scope and data controller

This Privacy Policy applies to the **Sobrita** mobile application (the “App”).

- Data controller: `{{LEGAL_NAME}}`
- Address: `{{POSTAL_ADDRESS}}`
- Privacy contact: `{{PRIVACY_EMAIL}}`

Sobrita is an on-device budget app that can be used without creating an account. Core budget records are not automatically sent to a server operated by the controller. The operating-system backup provider, app store, and advertising services may nevertheless process data as explained below.

### 2. Information handled by the App

#### Budget information entered by the user

Users may enter or generate budgets, income and expenses, amounts, dates, categories, notes, cash-count results, currency and language preferences, settings, missions, XP, and collection progress. This information is stored in the App's local storage and is not automatically transmitted to the controller's server.

#### Receipt photos

Only when the user chooses to do so, the App can take or select a receipt photo. The image is resized and stored in the App's private local storage and is not sent to the controller. Removing a receipt from a transaction deletes its file, and the App also cleans up receipt files that are no longer referenced.

Receipt images are not included in the App's JSON backup. They are also excluded from Android cloud backup, although they may be included in a direct device-to-device transfer.

#### Local notifications and widgets

If the user enables quick entry, the App uses Android notification permission and the boot-completed signal to restore an ongoing notification on the device. Widgets and the notification may display summaries of information stored in the App. The App does not use a remote push-notification server.

#### Backup exported by the user

When the user creates a backup in Settings, the budget data is copied as JSON text to the device clipboard. The user decides where to paste or share it. Once copied, the operating system or another app selected by the user may process that clipboard content.

#### Operating-system backup

If device backup is enabled, App records and preferences may be backed up with an operating-system provider such as Google or Apple or transferred to a new device. This processing depends on the user's device and account settings and the provider's policy. Android cloud backup excludes receipt photos.

### 3. Advertising and Google AdMob

The Android version uses the Google Mobile Ads SDK (AdMob) and Google User Messaging Platform (UMP) to provide user-initiated rewarded ads and native ads in transaction history.

According to Google's documentation, the Mobile Ads SDK may automatically collect or share with Google:

- IP address, which may be used to estimate general location;
- App or advertising interactions such as app launches, taps, impressions, and video views;
- diagnostic information such as crash logs, launch time, and battery usage; and
- device or account identifiers such as the Android advertising ID and app set ID.

Google may process this information to provide, measure, and—where permitted—personalize advertising, perform analytics, prevent fraud, and maintain security. Google states that SDK data is encrypted in transit using TLS. The controller does not provide AdMob with transaction amounts, budgets, notes, or receipt photos as advertising-targeting data.

Where applicable, UMP requests the necessary consent choices. When required, users can review or change those choices through **Privacy choices** in the App's Settings. Ad personalization and the ads shown depend on the user's choice, region, device settings, and Google's policies.

For more information, see the [Google Privacy Policy](https://policies.google.com/privacy), [how Google uses information from sites or apps that use its services](https://policies.google.com/technologies/partner-sites), and the [Google Mobile Ads SDK data-disclosure guidance](https://developers.google.com/admob/android/privacy/play-data-disclosure).

### 4. In-app purchases

Google Play or the Apple App Store processes payments and purchase restoration. Sobrita does not directly receive card numbers or bank account details. To deliver or restore an item, the App may receive a product ID, purchase status, purchase identifier, or verification information from the store. The store's processing is governed by its provider's privacy policy.

### 5. Permissions

- **Camera and photos:** used only when the user takes or selects a receipt photo.
- **Notifications:** used if the user enables the quick-entry notification; it can be disabled in device settings.
- **Boot completed:** used to restore the quick-entry notification the user left enabled.
- **Internet:** used for ads, consent messages, and app-store purchases.

### 6. Third parties, sale, and international processing

The controller does not sell the contents of users' financial records or receipt photos. To provide the described features, the following third parties may process information:

- Google: AdMob advertising, UMP consent management, Google Play purchases, and Android backup.
- Apple: App Store purchases and device backup, where applicable.

Google and Apple may process information outside the user's country of residence. The specific locations and safeguards are governed by their respective policies. Information may also be disclosed where required to comply with law or legal process or to protect rights and safety, as permitted by law.

### 7. Retention and deletion

Local data remains on the device until the user deletes records in the App, clears the App's data, or uninstalls it. Operating-system backups may remain longer or be restored after reinstallation according to the user's backup settings and the provider's retention policy.

Because the controller does not store the core budget records on a server, it cannot remotely access or delete records held on the user's device. Users can delete individual records in the App, clear App data in operating-system settings, or uninstall the App. Backup copies must be managed through the relevant Google or Apple account.

Retention and deletion of advertising or purchase data processed by Google or Apple are governed by each provider's policies and account controls.

### 8. Security

Budget records and receipt photos are kept in the App-private storage protected by the operating system. Communications with third-party services use the transport protections offered by those services. Reasonable safeguards are used, but no storage or transmission method can guarantee absolute security.

### 9. User rights

Depending on applicable law, users may request access, correction, cancellation or deletion, object to processing, or withdraw consent. Users in Mexico may exercise the rights known as ARCO: access, rectification, cancellation, and opposition.

To submit a request, email `{{PRIVACY_EMAIL}}` with:

- your name and a way to receive a response;
- a clear description of the requested action and related information; and
- information reasonably needed to verify your identity.

Data that exists only on the device must be managed using the controls described in section 7. Requests concerning information independently processed by Google or Apple should be submitted to the relevant provider.

### 10. Children's privacy

Sobrita is not designed for children. If a parent or guardian believes a child's information has been sent to the controller outside the App, they may contact `{{PRIVACY_EMAIL}}`. After verification, the controller will act as required by applicable law.

### 11. Changes and contact

This Policy may be updated when features, third-party services, or legal requirements change. Material changes will be communicated through the App, the store listing, or this page, and the last-updated date will be revised.

Contact: `{{PRIVACY_EMAIL}}`
