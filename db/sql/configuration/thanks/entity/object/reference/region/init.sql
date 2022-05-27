--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddRegionEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddRegionEvents (
  pClass        uuid
)
RETURNS         void
AS $$
DECLARE
  r             record;

  uParent       uuid;
  uEvent        uuid;
BEGIN
  uParent := GetEventType('parent');
  uEvent := GetEventType('event');

  FOR r IN SELECT * FROM Action
  LOOP

    IF r.code = 'create' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион создан', 'EventRegionCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион открыт', 'EventRegionOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион изменён', 'EventRegionEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион сохранён', 'EventRegionSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион доступен', 'EventRegionEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион недоступен', 'EventRegionDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион будет удалён', 'EventRegionDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион восстановлен', 'EventRegionRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Регион будет уничтожен', 'EventRegionDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassRegion -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassRegion (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uClass        uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'region', 'Регион', false);

  -- Тип
  PERFORM AddType(uClass, 'country.region', 'Регион страны', 'Регион страны.');

  -- Событие
  PERFORM AddRegionEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityRegion ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityRegion (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  nEntity       uuid;
BEGIN
  -- Сущность
  nEntity := AddEntity('region', 'Регион');

  -- Класс
  PERFORM CreateClassRegion(pParent, nEntity);

  -- API
  PERFORM RegisterRoute('region', AddEndpoint('SELECT * FROM rest.region($1, $2);'));

  RETURN nEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitRegion ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitRegion()
RETURNS         void
AS $$
DECLARE
  uType         uuid;
  uCountry      uuid;
BEGIN
  uType := GetType('country.region');
  SELECT id INTO uCountry FROM db.country WHERE alpha2 = 'RU';

  PERFORM CreateRegion(null, uType, uCountry, '01', 'Республика Адыгея (Адыгея)');
  PERFORM CreateRegion(null, uType, uCountry, '02', 'Республика Башкортостан');
  PERFORM CreateRegion(null, uType, uCountry, '03', 'Республика Бурятия');
  PERFORM CreateRegion(null, uType, uCountry, '04', 'Республика Алтай');
  PERFORM CreateRegion(null, uType, uCountry, '05', 'Республика Дагестан');
  PERFORM CreateRegion(null, uType, uCountry, '06', 'Республика Ингушетия');
  PERFORM CreateRegion(null, uType, uCountry, '07', 'Кабардино-Балкарская Республика');
  PERFORM CreateRegion(null, uType, uCountry, '08', 'Республика Калмыкия');
  PERFORM CreateRegion(null, uType, uCountry, '09', 'Карачаево-Черкесская Республика');
  PERFORM CreateRegion(null, uType, uCountry, '10', 'Республика Карелия');
  PERFORM CreateRegion(null, uType, uCountry, '11', 'Республика Коми');
  PERFORM CreateRegion(null, uType, uCountry, '12', 'Республика Марий Эл');
  PERFORM CreateRegion(null, uType, uCountry, '13', 'Республика Мордовия');
  PERFORM CreateRegion(null, uType, uCountry, '14', 'Республика Саха (Якутия)');
  PERFORM CreateRegion(null, uType, uCountry, '15', 'Республика Северная Осетия - Алания');
  PERFORM CreateRegion(null, uType, uCountry, '16', 'Республика Татарстан (Татарстан)');
  PERFORM CreateRegion(null, uType, uCountry, '17', 'Республика Тыва');
  PERFORM CreateRegion(null, uType, uCountry, '18', 'Удмуртская Республика');
  PERFORM CreateRegion(null, uType, uCountry, '19', 'Республика Хакасия');
  PERFORM CreateRegion(null, uType, uCountry, '20', 'Чеченская Республика');
  PERFORM CreateRegion(null, uType, uCountry, '21', 'Чувашская Республика – Чувашия');
  PERFORM CreateRegion(null, uType, uCountry, '22', 'Алтайский край');
  PERFORM CreateRegion(null, uType, uCountry, '23', 'Краснодарский край');
  PERFORM CreateRegion(null, uType, uCountry, '24', 'Красноярский край');
  PERFORM CreateRegion(null, uType, uCountry, '25', 'Приморский край');
  PERFORM CreateRegion(null, uType, uCountry, '26', 'Ставропольский край');
  PERFORM CreateRegion(null, uType, uCountry, '27', 'Хабаровский край');
  PERFORM CreateRegion(null, uType, uCountry, '28', 'Амурская область');
  PERFORM CreateRegion(null, uType, uCountry, '29', 'Архангельская область');
  PERFORM CreateRegion(null, uType, uCountry, '30', 'Астраханская область');
  PERFORM CreateRegion(null, uType, uCountry, '31', 'Белгородская область');
  PERFORM CreateRegion(null, uType, uCountry, '32', 'Брянская область');
  PERFORM CreateRegion(null, uType, uCountry, '33', 'Владимирская область');
  PERFORM CreateRegion(null, uType, uCountry, '34', 'Волгоградская область');
  PERFORM CreateRegion(null, uType, uCountry, '35', 'Вологодская область');
  PERFORM CreateRegion(null, uType, uCountry, '36', 'Воронежская область');
  PERFORM CreateRegion(null, uType, uCountry, '37', 'Ивановская область');
  PERFORM CreateRegion(null, uType, uCountry, '38', 'Иркутская область');
  PERFORM CreateRegion(null, uType, uCountry, '39', 'Калининградская область');
  PERFORM CreateRegion(null, uType, uCountry, '40', 'Калужская область');
  PERFORM CreateRegion(null, uType, uCountry, '41', 'Камчатская область');
  PERFORM CreateRegion(null, uType, uCountry, '42', 'Кемеровская область');
  PERFORM CreateRegion(null, uType, uCountry, '43', 'Кировская область');
  PERFORM CreateRegion(null, uType, uCountry, '44', 'Костромская область');
  PERFORM CreateRegion(null, uType, uCountry, '45', 'Курганская область');
  PERFORM CreateRegion(null, uType, uCountry, '46', 'Курская область');
  PERFORM CreateRegion(null, uType, uCountry, '47', 'Ленинградская область');
  PERFORM CreateRegion(null, uType, uCountry, '48', 'Липецкая область');
  PERFORM CreateRegion(null, uType, uCountry, '49', 'Магаданская область');
  PERFORM CreateRegion(null, uType, uCountry, '50', 'Московская область');
  PERFORM CreateRegion(null, uType, uCountry, '51', 'Мурманская область');
  PERFORM CreateRegion(null, uType, uCountry, '52', 'Нижегородская область');
  PERFORM CreateRegion(null, uType, uCountry, '53', 'Новгородская область');
  PERFORM CreateRegion(null, uType, uCountry, '54', 'Новосибирская область');
  PERFORM CreateRegion(null, uType, uCountry, '55', 'Омская область');
  PERFORM CreateRegion(null, uType, uCountry, '56', 'Оренбургская область');
  PERFORM CreateRegion(null, uType, uCountry, '57', 'Орловская область');
  PERFORM CreateRegion(null, uType, uCountry, '58', 'Пензенская область');
  PERFORM CreateRegion(null, uType, uCountry, '59', 'Пермская область ');
  PERFORM CreateRegion(null, uType, uCountry, '60', 'Псковская область');
  PERFORM CreateRegion(null, uType, uCountry, '61', 'Ростовская область');
  PERFORM CreateRegion(null, uType, uCountry, '62', 'Рязанская область');
  PERFORM CreateRegion(null, uType, uCountry, '63', 'Самарская область');
  PERFORM CreateRegion(null, uType, uCountry, '64', 'Саратовская область');
  PERFORM CreateRegion(null, uType, uCountry, '65', 'Сахалинская область');
  PERFORM CreateRegion(null, uType, uCountry, '66', 'Свердловская область');
  PERFORM CreateRegion(null, uType, uCountry, '67', 'Смоленская область');
  PERFORM CreateRegion(null, uType, uCountry, '68', 'Тамбовская область');
  PERFORM CreateRegion(null, uType, uCountry, '69', 'Тверская область');
  PERFORM CreateRegion(null, uType, uCountry, '70', 'Томская область');
  PERFORM CreateRegion(null, uType, uCountry, '71', 'Тульская область');
  PERFORM CreateRegion(null, uType, uCountry, '72', 'Тюменская область');
  PERFORM CreateRegion(null, uType, uCountry, '73', 'Ульяновская область');
  PERFORM CreateRegion(null, uType, uCountry, '74', 'Челябинская область');
  PERFORM CreateRegion(null, uType, uCountry, '75', 'Читинская область');
  PERFORM CreateRegion(null, uType, uCountry, '76', 'Ярославская область');
  PERFORM CreateRegion(null, uType, uCountry, '77', 'Г. Москва');
  PERFORM CreateRegion(null, uType, uCountry, '78', 'Г. Санкт-Петербург');
  PERFORM CreateRegion(null, uType, uCountry, '79', 'Еврейская автономная область');
  PERFORM CreateRegion(null, uType, uCountry, '80', 'Агинский Бурятский автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '81', 'Коми-Пермяцкий автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '82', 'Корякский автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '83', 'Ненецкий автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '84', 'Таймырский (Долгано-Ненецкий) автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '85', 'Усть-Ордынский Бурятский автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '86', 'Ханты-Мансийский автономный округ - Югра');
  PERFORM CreateRegion(null, uType, uCountry, '87', 'Чукотский автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '88', 'Эвенкийский автономный округ');
  PERFORM CreateRegion(null, uType, uCountry, '89', 'Ямало-Ненецкий автономный округ');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
