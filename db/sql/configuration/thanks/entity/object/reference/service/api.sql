--------------------------------------------------------------------------------
-- SERVICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.service -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.service
AS
  SELECT * FROM ObjectService;

GRANT SELECT ON api.service TO administrator;

--------------------------------------------------------------------------------
-- api.add_service -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет услугу.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {text} pType - Код типа
 * @param {text} pCategory - Категория
 * @param {text} pMeasure - Мера
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {integer} pValue - Величина
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_service (
  pParent           uuid,
  pType             text,
  pCategory         text,
  pMeasure          text,
  pCode             text,
  pName             text,
  pValue            integer,
  pDescription	    text DEFAULT null
) RETURNS           uuid
AS $$
BEGIN
  RETURN CreateService(pParent, CodeToType(lower(coalesce(pType, 'debit')), 'service'), CodeToType(lower(coalesce(pCategory, 'service')), 'category'), CodeToType(lower(coalesce(pMeasure, 'time')), 'measure'), pCode, pName, pValue, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_service ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует услугу.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {text} pType - Код типа
 * @param {text} pCategory - Категория
 * @param {text} pMeasure - Мера
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {integer} pValue - Величина
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_service (
  pId               uuid,
  pParent           uuid default null,
  pType             text default null,
  pCategory         text default null,
  pMeasure          text default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription      text default null
) RETURNS           void
AS $$
DECLARE
  uType             uuid;
  nCategory         uuid;
  nMeasure          uuid;
  nService          uuid;
BEGIN
  SELECT t.id INTO nService FROM db.service t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('услуга', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'service');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  IF pCategory IS NOT NULL THEN
    nCategory := CodeToType(lower(pCategory), 'category');
  END IF;

  IF pMeasure IS NOT NULL THEN
    nMeasure := CodeToType(lower(pMeasure), 'measure');
  END IF;

  PERFORM EditService(nService, pParent, uType, nCategory, nMeasure, pCode, pName, pValue, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_service -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_service (
  pId               uuid,
  pParent           uuid default null,
  pType             text default null,
  pCategory         text default null,
  pMeasure          text default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription      text default null
) RETURNS           SETOF api.service
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_service(pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription);
  ELSE
    PERFORM api.update_service(pId, pParent, pType, pCategory, pMeasure, pCode, pName, pValue, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.service WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_service -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает услугу
 * @param {uuid} pId - Идентификатор
 * @return {api.service}
 */
CREATE OR REPLACE FUNCTION api.get_service (
  pId		uuid
) RETURNS	api.service
AS $$
  SELECT * FROM api.service WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_service ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список услуг.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.service}
 */
CREATE OR REPLACE FUNCTION api.list_service (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.service
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'service', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
