--------------------------------------------------------------------------------
-- TARGET ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.target ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.target
AS
  SELECT * FROM ObjectTarget;

GRANT SELECT ON api.target TO administrator;

--------------------------------------------------------------------------------
-- api.add_target --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет цель.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pPost - Публикация
 * @param {text} pCode - Код
 * @param {text} pContent - Содержимое
 * @param {text} pData - Данные
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_target (
  pParent       uuid,
  pType         uuid,
  pPost         uuid,
  pCode         text,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateTarget(pParent, coalesce(pType, GetType('post.target')), pPost, pCode, pContent, pData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_target -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет цель.
 * @param {uuid} pId - Идентификатор карты (api.get_target)
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pPost - Публикация
 * @param {text} pCode - Код
 * @param {text} pContent - Содержимое
 * @param {text} pData - Данные
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_target (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pPost         uuid default null,
  pCode         text default null,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  PERFORM c.id FROM db.target c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('цель', 'id', pId);
  END IF;

  PERFORM EditTarget(pId, pParent, pType, pPost, pCode, pContent, pData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_target --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_target (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pPost         uuid default null,
  pCode         text default null,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.target
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_target(pParent, pType, pPost, pCode, pContent, pData, pLabel, pDescription);
  ELSE
    PERFORM api.update_target(pId, pParent, pType, pPost, pCode, pContent, pData, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.target WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_target --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает цель
 * @param {uuid} pId - Идентификатор
 * @return {api.target} - Публикация
 */
CREATE OR REPLACE FUNCTION api.get_target (
  pId		uuid
) RETURNS	api.target
AS $$
  SELECT * FROM api.target WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_target -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список цельов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.target} - Публикацияы
 */
CREATE OR REPLACE FUNCTION api.list_target (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.target
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'target', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
