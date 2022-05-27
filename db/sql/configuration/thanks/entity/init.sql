--------------------------------------------------------------------------------
-- InitConfigurationEntity -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationEntity()
RETURNS         void
AS $$
DECLARE
  uDocument     uuid;
  uReference    uuid;
BEGIN
  -- Документ

  uDocument := GetClass('document');

    -- Лицевой счёт

    PERFORM CreateEntityAccount(uDocument);

    -- Карта

    PERFORM CreateEntityCard(uDocument);

    -- Клиент

    PERFORM CreateEntityClient(uDocument);

    -- Договор

    PERFORM CreateEntityContract(uDocument);

    -- Устройство

    PERFORM CreateEntityDevice(uDocument);

    -- Счёт

    PERFORM CreateEntityInvoice(uDocument);

    -- Ордер

    PERFORM CreateEntityOrder(uDocument);

    -- Публикация

    PERFORM CreateEntityPost(uDocument);

    -- Цель

    PERFORM CreateEntityTarget(uDocument);

    -- Транзакция

    PERFORM CreateEntityTransaction(uDocument);

  -- Справочник

  uReference := GetClass('reference');

    -- Календарь

    PERFORM CreateEntityCalendar(uReference);

    -- Категория

    PERFORM CreateEntityCategory(uReference);

    -- Страна

    PERFORM CreateEntityCountry(uReference);

    -- Валюта

    PERFORM CreateEntityCurrency(uReference);

    -- Мера

    PERFORM CreateEntityMeasure(uReference);

    -- Модель

    PERFORM CreateEntityModel(uReference);

    -- Свойство

    PERFORM CreateEntityProperty(uReference);

    -- Регион

    PERFORM CreateEntityRegion(uReference);

    -- Услуга

    PERFORM CreateEntityService(uReference);

    -- Тариф

    PERFORM CreateEntityTariff(uReference);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
