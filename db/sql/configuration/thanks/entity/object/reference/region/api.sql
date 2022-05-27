--------------------------------------------------------------------------------
-- REGION ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.region ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.region
AS
  SELECT * FROM ObjectRegion;

GRANT SELECT ON api.region TO administrator;

--------------------------------------------------------------------------------
-- api.add_region --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет регион.
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {text} pType - Код или идентификатор типа
 * @param {uuid} pCategory - Страна
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_region (
  pParent       uuid,
  pType         text,
  pCategory		uuid,
  pCode         text,
  pName         text,
  pDescription	text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateRegion(pParent, CodeToType(coalesce(pType, 'country'), 'region'), pCategory, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_region -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует регион.
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {text} pType - Код или идентификатор типа
 * @param {uuid} pCategory - Страна
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_region (
  pId		    uuid,
  pParent       uuid default null,
  pType         text default null,
  pCategory		uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uType         uuid;
  uRegion        uuid;
BEGIN
  SELECT t.id INTO uRegion FROM db.region t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('регион', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'region');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditRegion(uRegion, pParent, uType, pCategory, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_region --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_region (
  pId           uuid,
  pParent       uuid default null,
  pType         text default null,
  pCategory		uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription	text default null
) RETURNS       SETOF api.region
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_region(pParent, pType, pCategory, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_region(pId, pParent, pType, pCategory, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.region WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_region --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает регион
 * @param {uuid} pId - Идентификатор
 * @return {api.region}
 */
CREATE OR REPLACE FUNCTION api.get_region (
  pId		uuid
) RETURNS	api.region
AS $$
  SELECT * FROM api.region WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_region -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список регионов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.region}
 */
CREATE OR REPLACE FUNCTION api.list_region (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.region
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'region', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
