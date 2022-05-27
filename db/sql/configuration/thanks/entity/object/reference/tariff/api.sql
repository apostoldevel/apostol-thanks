--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.tariff ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.tariff
AS
  SELECT * FROM ObjectTariff;

GRANT SELECT ON api.tariff TO administrator;

--------------------------------------------------------------------------------
-- api.add_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет тариф.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {uuid} pService - Услуга
 * @param {numeric} pPrice - Цена
 * @param {numeric} pCommission - Комиссия
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_tariff (
  pParent           uuid,
  pType             uuid,
  pCode             text,
  pName             text,
  pService          uuid,
  pPrice            numeric,
  pCommission       numeric default null,
  pDescription	    text default null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateTariff(pParent, coalesce(pType, GetType('service.tariff')), pCode, pName, pService, pPrice, pCommission, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_tariff -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует тариф.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {uuid} pService - Услуга
 * @param {numeric} pPrice - Цена
 * @param {numeric} pCommission - Комиссия
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_tariff (
  pId		        uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCode             text default null,
  pName             text default null,
  pService          uuid default null,
  pPrice            numeric default null,
  pCommission       numeric default null,
  pDescription	    text default null
) RETURNS           void
AS $$
DECLARE
  nTariff           uuid;
BEGIN
  SELECT t.id INTO nTariff FROM db.tariff t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('тариф', 'id', pId);
  END IF;

  PERFORM EditTariff(nTariff, pParent, pType, pCode, pName, pService, pPrice, pCommission, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_tariff (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCode             text default null,
  pName             text default null,
  pService          uuid default null,
  pPrice            numeric default null,
  pCommission       numeric default null,
  pDescription	    text default null
) RETURNS           SETOF api.tariff
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_tariff(pParent, pType, pCode, pName, pService, pPrice, pCommission, pDescription);
  ELSE
    PERFORM api.update_tariff(pId, pParent, pType, pCode, pName, pService, pPrice, pCommission, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.tariff WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_tariff --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тариф
 * @param {uuid} pId - Идентификатор
 * @return {api.tariff}
 */
CREATE OR REPLACE FUNCTION api.get_tariff (
  pId		uuid
) RETURNS	api.tariff
AS $$
  SELECT * FROM api.tariff WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_tariff -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список тарифов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.tariff}
 */
CREATE OR REPLACE FUNCTION api.list_tariff (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.tariff
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'tariff', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
