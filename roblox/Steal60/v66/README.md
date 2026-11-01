# Steal60 v66 · RU / EN

Последнее обновление: закрыт выход в море у гаражей. Невидимая торцевая стена перенесена внутрь края земли, продлена под воду и соединена с боковыми границами; защитный периметр постоянно загружен. При выходе за край пешеход возвращается на сушу. [Подробности](OCEAN-UPDATE.md).

Предыдущие исправления памяти, ошибок Output и двухвалютного магазина сохранены. [Подробности](UPDATE.md).

**Обновлено по скриншотам и новым замечаниям:** компактные полки, исправленное оформление лидерборда, руководство сверху, подробные дорожные события, машины 25–30 в районах 6+, тихий двигатель и питомцы сзади машины. Добавлены три покупки за монеты и новая кривая мастерства: [что изменено](VISUAL-UPDATE.md), [цены и расчёты](ECONOMY.md).

**Исправление доставки сохранено.** Восстановлен рабочий обработчик Main, ошибочно удалённый вместе с отладочным блоком. Машина теперь запускает выдачу каталога/монет/XP/добычи и продвижение обучения. Скачайте текущий файл, остановите Play и замените старый контейнер установщика; профиль сбрасывать не нужно. [Проверка полной цепочки](RESULTS.md).

Обновлено после [проверки замечаний v64](AUDIT-v64.md). Экономика, немедленное сохранение улучшений, US English, числовые формы и управление геймпадом доработаны; имя установщика и ветка сохранены.

Один двуязычный установщик, восстановленный **из приложенного v65**, без использования недоступной сборки v66. RU/EN переключается внутри игры. Каталог из 150 автомобилей и идентификаторы сохранений сохранены.

**Скачать:** откройте [Steal60_v66.rbxmx](Steal60_v66.rbxmx), затем нажмите **Download raw file** в правом верхнем углу просмотра файла GitHub. Не сохраняйте HTML-страницу GitHub вместо XML.

## Установка в Roblox Studio

1. Сохраните копию своего Place. Остановите Play/Run.
2. Если в Workspace остался контейнер старого установщика Steal60, удалите именно этот контейнер. Одновременно должен запускаться только один установщик. Если в редактируемом Place уже есть `ServerScriptService/Main` от Steal60, временно выключите его (`Disabled = true`): новый установщик заменит и включит свой Main. Не удаляйте пользовательские `ServerStorage/CarModels` и хранилища данных.
3. В Explorer нажмите правой кнопкой на Workspace → **Insert from File…** и выберите скачанный `Steal60_v66.rbxmx` (либо перетащите файл в Studio). Появится `Steal60_v66_RU_EN`.
4. Нажмите Play. В Output должна появиться строка `[Steal60 v66] Установлено…`. В рантайме контейнер распределяет модули по сервисам и удаляет себя; Main запускается последним.
5. После Stop изменения рантайма откатываются Studio. Сохраните/публикуйте Place с контейнером установщика в режиме редактирования: он нужен для установки при следующих запусках. Не импортируйте второй контейнер поверх первого.
6. В игре кнопка RU/EN переключает язык, кнопка с нотой открывает отдельную громкость музыки и выключатель. Полиция использует одну умеренную сирену без дополнительных пугающих звуков; тихий двигатель работает отдельно только за рулём. У двигателя оставлен прежний клип, добавлены подавление металлических щелчков, плавное изменение тона и внутренний участок повтора; реальное звучание требует прослушивания в Studio. Настройки сохраняются вместе с профилем.

После замены установщика опубликуйте Place и проверяйте в **новом сервере**: уже запущенные серверы Roblox продолжают исполнять прежний код.

Для настоящих сохранений в Studio нужны опубликованный Experience и включённый **Enable Studio Access to API Services**. При недоступном DataStore сохраняется поведение v65: временный профиль только в Studio, с соответствующим сообщением в Output; это не проверка сохранения между сеансами.

## Что изменено

- Исходный текст отделён от последнего отображённого перевода; собственные отложенные сигналы не перезаписывают источник. Отслеживаются весь PlayerGui, подсказки и подгруженные вывески. Добавлен перевод составных строк эффектов.
- Подсказки пешего/автомобильного управления находятся над MENU и видны только в обучении или справочнике. Справочник оставляет место нижней полосе; кнопка руководства находится справа сверху над RU/EN и музыкой.
- Улучшения показывают текущий и следующий суммарный эффект и фактический доход кассы в час, рассчитанный серверной формулой. `botSpeed` сохранён как ключ покупки: прежние ветки дают +3% или +4% к базовой выплате за доставку, каждую можно оплатить любой валютой. `secondBot` даёт +15% к базе для rare/epic/legendary, включая старое право владения. Возврат машины, помощник и уведомления сохранены; скорость возврата фиксирована на базовых 42 с ограничением максимальной скорости.
- Сервер проверяет пересечение переднего бампера с конусом 30 раз/с; конус сразу смещается вперёд/в сторону и получает серверную скорость. Это не клиентский запрос награды/столкновения.
- На полках убраны большие физические плашки: фон измеряется по тексту, шрифт фиксирован, доход/детали идут отдельными строками. Компактные Billboard-карточки видны до 28 studs; клиент исключает их экранные пересечения.
- Громкость и выключение музыки сохраняются отдельно. Наземные питомцы опираются на заднюю площадку/грузовую платформу за головой водителя, летающие парят над крышей. Учтены геометрия поверхности и тюнинг; локальные опорные координаты кэшируются.
- Обновлены пропорции кабин, крыши и стёкла. Каталог и средства просмотра тюнинга сохранены.
- Различаются силуэты магазинов/домов и дворы пяти тем: промдвор, городской двор с качелями, огород с сараем, бассейн с перголой, курортное кафе. Крупные постройки и дворы занимают отдельные участки; при построении проверяется отсутствие пересечений их участков.
- Полицейский пост использует подробный кузов из конструктора каталога и одетого полицейского с жезлом. Ремонт использует подробный экскаватор-погрузчик, рабочего с лопатой, ограждения и вскрытый асфальт. NPC смотрят на своего игрока; события появляются через 3 с и чередуются. Свободная полоса и серверная проверка объезда сохранены.
- Конечные стены/ограничения пяти районов убраны. После 5 идут 6, 7 и далее со стабильным случайным выбором одной из пяти тем. Загрузчик держит соседние районы игроков, удалённые выгружает через прежнюю задержку 8 секунд. Защита от телепортации и проверка навыка сохранены.
- В общих парковках районов 6+ семь обычных машин класса super требуют 25–30, независимо от навыка посетителя; места №1/7 гарантируют 25/30. Место №8 — сложная машина `max(31, навык+1)`, с учётом игроков рядом и персональным повышением при взаимодействии. Низкий навык не обходит исходную проверку; полицейский возврат сохранён.
- Крупное золотое «В разработке» / «In development» появляется в центре на 1,5 секунды при въезде в 6+ и далее каждые 10 секунд. Переход 6→7 не сбрасывает интервал. При активном модальном окне/взломе показ откладывается; управление надпись не перехватывает.
- `HarDvRaiN` получает однократный сброс прогресса **только в Studio** с новым флагом `studioFreshStartV66`. Очищаются монеты/касса, покупки, улучшения, коллекции, косметика, питомцы, полки и обучение. Алмазы, взлом/опыт, журнал платежей и настройки остаются. Код старого тестового подарка алмазов удалён. Live-хранилище остаётся `Steal60_PlayerData_v1`, Studio-хранилище — прежнее `Steal60_PlayerData_Studio_v62`.

- Лидерборд перенесён перед колоннами, получил отступы и отдельные колонки имени/суммы. Имена игроков не переводятся. Добавлены рабочий за 4 млн, простой цвет за 750 тыс. и аура за 1,5 млн монет; лицензия питомца — 5 млн, мастерство растёт по квадратичной кривой. [Подробные цены](ECONOMY.md).

## Проверки и границы результата

См. [сверку замечаний и новые цены](AUDIT-v64.md), [RESULTS.md](RESULTS.md) и [исходный журнал](tests/validation-output.txt). Компилировались **все 124 скрипта из конечного XML**, а сценарии выполнялись заново для этой сборки.

**Roblox Engine/Studio в облачной среде отсутствует.** Автоматические сценарии используют Luau и явно обозначенные тестовые двойники Roblox API. Они не подтверждают качество изображения, живую физику/репликацию, доступность аудио и внешних NPC-ассетов, настоящий DataStore или Marketplace. Перед публикацией игры выполните Studio-проверки из RESULTS.md. Ветка GitHub публикует установщик, но не публикует Roblox Experience.

## English

Latest update: native left-thumbstick touch driving, verified first seating, firmer heading/shorter coast, wheel-based showroom placement, replay-safe hack resync and complete R15 portrait heads. [Details](MOBILE-FIX.md). Selection windows fill almost the entire usable canvas; the atelier uses a responsive one-to-four-column grid with a mastery shortcut. Wind has a broad half-transparent shoulder wake and more visible curls. [Details](LARGE-MENU.md). Empty Upgrade/Shop tabs and scaled modal positioning remain fixed. Wind now uses translucent ribbon wakes and rising shoulder swirls. [Evidence](MENU-FIX.md). Memory-puzzle deadlocks, cancellation, NPC cleanup errors and three invalid music IDs remain fixed. Each ordinary upgrade benefit now has coin and diamond buttons on one card. Speed adds +1 for a fixed 20 diamonds per level; Auto Collect costs 300 diamonds. Unlocked hero mastery also works with the player’s own avatar. The basic aura uses translucent wind ribbons and curls, and district junctions have themed corner plazas. See [UPDATE.md](UPDATE.md).

Delivery hotfix: the Main delivery-reward callback was accidentally removed during debug cleanup and has now been restored. Replace the old installer while Studio is stopped; do not reset your profile. A new integration test runs actual Main startup and the delivery/reward/tutorial chain.

This is one bilingual installer rebuilt from the attached v65. Open [Steal60_v66.rbxmx](Steal60_v66.rbxmx) on GitHub and click **Download raw file**. Stop Studio, keep only one Steal60 installer container in Workspace, disable an already-installed old `ServerScriptService/Main`, and insert the downloaded file into Workspace using **Insert from File…**. Play to install; the new Main is enabled last. Keep the installer in the edit-time Place when saving/publishing because Play-time changes are reverted by Studio.

RU/EN is an in-game toggle. The music-note button opens separately saved music volume/mute controls. Existing vehicle IDs, save-store names, purchased levels and v65 payment/recovery mechanisms are retained. Approved economic adjustments are listed in [AUDIT-v64.md](AUDIT-v64.md). Helper speed purchase keys become additive delivery payout bonuses (+3% or +4% of base, either currency per benefit; secondBot +15% of base for rare+). Districts continue beyond five with streamed cleanup, seven ordinary level-25–30 cars and one intentionally harder police-trigger target. See the Russian change list above for all twelve requested changes.

The latest screenshot update and coin progression prices are described in [VISUAL-UPDATE.md](VISUAL-UPDATE.md) and [ECONOMY.md](ECONOMY.md). A worker outfit costs 4M coins, plain paint 750K, a modest aura 1.5M and the pet license 5M. Walking pets sit at the rear of the car, behind the driver.

The updated build adds immediate upgrade saves, separate currency cooldowns, a soft cap on base income before bonuses, lower ladder costs, American English, number inflection, adaptive modal scaling and native gamepad input. All 124 final XML scripts compile; current-run Luau tests cover the new logic with explicit Roblox API test doubles. **No actual Roblox Engine was available.** Studio visuals, physics, live DataStore and Marketplace integration remain unverified. [RESULTS.md](RESULTS.md) provides the evidence and Studio acceptance checklist.
