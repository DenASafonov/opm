#Использовать asserts
#Использовать logos
#Использовать gitrunner

Перем ДопустимыеИменаКаналов;
Перем Лог;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ОписаниеКоманды(Знач КомандаПриложения) Экспорт
	
	КомандаПриложения.Опция("token", "", "Токен авторизации на GitHub.com
								|                        - Токен авторизации создается на странице https://github.com/settings/tokens
								|                        - Токен используется только для проверки авторизации на GitHub.com и прав на репозиторий, 
								|                        выдача дополнительных разрешений в ""scopes"" НЕ требуется.")
								.ВОкружении("GITHUB_OAUTH_TOKEN");
	;
	КомандаПриложения.Опция("f file", "", "Маска или имя файла пакета.");
	КомандаПриложения.Опция("c channel", "auto", "Канал публикации.")
							.ТПеречисление()
							.Перечисление("auto", "auto", "Автоматическое определение канала.
							|     В случае отправки из ветки master гит-репозитория данный параметр можно опустить - будет использоваться канал ""stable"".
							|     В любых других случаях его заполнение обязательно.")
							.Перечисление("stable", "stable", "Канал содержащий стабильные версии пакетов")
							.Перечисление("dev", "dev" , "Канал содержащий разработческие версии пакетов")
							.ВОкружении("OPM_HUB_CHANNEL");

	КомандаПриложения.Аргумент("FILE", "", "Маска или имя файла пакета.")
							.Обязательный(Ложь);

	// КомандаПриложения.Спек = "(-a | --all | -l | --local | -d | --dest )";

КонецПроцедуры

Процедура ВыполнитьКоманду(Знач КомандаПриложения) Экспорт
	

	ТокенАвторизации = КомандаПриложения.ЗначениеОпции("token");
	МаскаФайлаПакетаСтарая = КомандаПриложения.ЗначениеОпции("file");
	ИмяКаналаПубликации = КомандаПриложения.ЗначениеОпции("channel");

	МаскаФайлаПакета = КомандаПриложения.ЗначениеАргумента("FILE");

	Если Не ПустаяСтрока(МаскаФайлаПакетаСтарая) Тогда
		ЛОг.Предупреждение("Использование опции <--file> устарело в следующих версиях будет удалена. Используйте аргумент <FILE>");
		МаскаФайлаПакета = МаскаФайлаПакетаСтарая;
	КонецЕсли;

	Ожидаем.Что(МаскаФайлаПакета, СтрШаблон("Не заполнено значение обязательного параметра %1", МаскаФайлаПакета)).Заполнено();

	ФайлПакета = ПолучитьФайлПакета(МаскаФайлаПакета);

	Канал = ПолучитьИмяКаналаПубликации(ИмяКаналаПубликации);
	
	ОтправитьПакетВХаб(ТокенАвторизации, ФайлПакета, Канал);
	
КонецПроцедуры

Функция ПолучитьИмяКаналаПубликации(Знач ИмяКаналаПубликации)
	
	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьРабочийКаталог(ТекущийКаталог());
	
	КаналПубликации = СокрЛП(ИмяКаналаПубликации);
	
	Если КаналПубликации = "auto" Тогда
		
		Если НЕ ГитРепозиторий.ЭтоРепозиторий() Тогда
			ВызватьИсключение "Не заполнено значение обязательного параметра --channel";
		КонецЕсли;
		
		ИмяВетки = ГитРепозиторий.ПолучитьТекущуюВетку();
		Если ИмяВетки <> "master" Тогда
			ВызватьИсключение "Не заполнено значение обязательного параметра --channel";
		КонецЕсли;

		Возврат ДопустимыеИменаКаналов.Стабильный;

	Иначе

		Если ЭтоДопустимыйКаналПубликации(КаналПубликации) Тогда
			Возврат КаналПубликации;
		Иначе
			ТекстСообщения = "Указано недопустимое имя канала. Допустимые имена:" + Символы.ПС;
			Для Каждого КлючИЗначение Из ДопустимыеИменаКаналов Цикл
				ТекстСообщения = ТекстСообщения + КлючИЗначение.Значение + Символы.ПС;
			КонецЦикла;
			
			ВызватьИсключение ТекстСообщения;
		КонецЕсли;

	КонецЕсли;

КонецФункции

Функция ЭтоДопустимыйКаналПубликации(КаналПубликации)
	Результат = Ложь;
	Для Каждого КлючИЗначение Из ДопустимыеИменаКаналов Цикл
		Если КлючИЗначение.Значение = КаналПубликации Тогда
			Результат = Истина;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Результат;
КонецФункции

Функция ПолучитьФайлПакета(МаскаФайлаПакета)
	
	НайденныеФайлы = НайтиФайлы(ТекущийКаталог(), МаскаФайлаПакета);
	
	Если НайденныеФайлы.Количество() = 0 Тогда
		ВызватьИсключение "По переданной маске файла пакета не найдено файлов";
	КонецЕсли;
	Если НайденныеФайлы.Количество() > 1 Тогда
		ВызватьИсключение "По переданной маске файла пакета найдено больше одного файла";
	КонецЕсли;
	
	Возврат НайденныеФайлы[0];
	
КонецФункции

Процедура ОтправитьПакетВХаб(Знач ТокенАвторизации, Знач ФайлПакета, Знач Канал)
	
	ДвоичныеДанныеФайла = Новый ДвоичныеДанные(ФайлПакета.ПолноеИмя);
	ДвоичныеДанныеФайлаВBase64 = Base64Строка(ДвоичныеДанныеФайла);
	
	Сервер = КонстантыOpm.СерверУдаленногоХранилища;
	Ресурс = КонстантыOpm.РесурсПубликацииПакетов;
	
	Заголовки = Новый Соответствие();
	Заголовки.Вставить("OAUTH-TOKEN", ТокенАвторизации);
	Заголовки.Вставить("FILE-NAME", ФайлПакета.Имя);
	Заголовки.Вставить("CHANNEL", Канал);
	
	Соединение = Новый HTTPСоединение(Сервер);
	Запрос = Новый HTTPЗапрос(Ресурс, Заголовки);
	Запрос.УстановитьТелоИзДвоичныхДанных(ДвоичныеДанныеФайла);
	
	Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	ТелоОтвета = Ответ.ПолучитьТелоКакСтроку();
	
	Если Ответ.КодСостояния <> 200 Тогда
		ВызватьИсключение ТелоОтвета;
	КонецЕсли;
	
	Лог.Информация(ТелоОтвета);
	
КонецПроцедуры

Лог = Логирование.ПолучитьЛог("oscript.app.opm");

ДопустимыеИменаКаналов = Новый Структура;
ДопустимыеИменаКаналов.Вставить("Стабильный", "stable");
ДопустимыеИменаКаналов.Вставить("Разработческий", "dev");
