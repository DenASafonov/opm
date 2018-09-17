///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ОписаниеКоманды(Знач КомандаПриложения) Экспорт
		
	КомандаПриложения.Опция("n app-name", "", "Имя генерируемого исполняемого файла");

	КомандаПриложения.Аргумент("PATH", "", "Имя скрипта в текущем каталоге или полный путь скрипта");
	КомандаПриложения.Аргумент("DIR", ТекущийКаталог(), "Каталог, в котором будет создан скрипт запуска")
					.Обязательный(Ложь);

КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Процедура ВыполнитьКоманду(Знач КомандаПриложения) Экспорт

	ИмяФайлаЗапуска = КомандаПриложения.ЗначениеОпции("name");
	ИмяСкрипта = КомандаПриложения.ЗначениеАргумента("PATH");
	Каталог = КомандаПриложения.ЗначениеАргумента("DIR");

  	СоздатьСкриптЗапуска(ИмяСкрипта, Каталог, ИмяФайлаЗапуска);

КонецПроцедуры

Процедура СоздатьСкриптЗапуска(Знач ИмяСкрипта, Знач Каталог, Знач ИмяФайлаЗапуска) Экспорт
	
	Если ПустаяСтрока(ИмяСкрипта) Тогда
		ВызватьИсключение "Не указано имя файла скрипта";
	КонецЕсли;
	
	ФайлСкрипта = Новый Файл(ИмяСкрипта);
	ПолноеИмяСкрипта = ФайлСкрипта.ПолноеИмя;
	Если Не ФайлСкрипта.Существует() Тогда
		ФайлСкрипта = Новый Файл(ИмяСкрипта + ".os");
		Если Не ФайлСкрипта.Существует() Тогда
			ВызватьИсключение "Файл скрипта """ + ПолноеИмяСкрипта + """ не найден";
		Иначе
			ПолноеИмяСкрипта = ФайлСкрипта.ПолноеИмя;
		КонецЕсли;
	КонецЕсли;
	
	Если Не ФайлСкрипта.ЭтоФайл() Тогда
		ВызватьИсключение "Указанный скрипт """ + ПолноеИмяСкрипта + """ не является файлом";
	КонецЕсли;
	
	ФайлКаталога = Новый Файл(Каталог);
	Каталог = ФайлКаталога.ПолноеИмя;
	Если ФайлКаталога.Существует() Тогда
		Если ФайлКаталога.ЭтоФайл() Тогда
			ВызватьИсключение "Указанный каталог """ + Каталог + """ является файлом";
		КонецЕсли;
	Иначе
		СоздатьКаталог(Каталог);
		Если Не ФайлКаталога.Существует() Тогда
			ВызватьИсключение "Не удалось создать каталог """ + Каталог + """";
		КонецЕсли;
	КонецЕсли;
	
	ИмяСкриптаЗапуска = ?(ИмяФайлаЗапуска = Неопределено, ФайлСкрипта.ИмяБезРасширения, ИмяФайлаЗапуска);
	Установщик = Новый УстановкаПакета;
	Установщик.СоздатьСкриптЗапуска(ИмяСкриптаЗапуска, ПолноеИмяСкрипта, Каталог);
	
КонецПроцедуры

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(НРег(СистемнаяИнформация.ВерсияОС), "windows") > 0;