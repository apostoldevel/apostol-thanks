--------------------------------------------------------------------------------
-- POST ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.post --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.post
AS
  SELECT * FROM ObjectPost;

GRANT SELECT ON api.post TO administrator;

--------------------------------------------------------------------------------
-- api.add_post ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет руководство.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pStructure - Структура
 * @param {uuid} pApprover - Утверждающий
 * @param {uuid} pExecutor - Исполнитель
 * @param {uuid} pObserver - Наблюдатель
 * @param {text} pContent - Содержимое
 * @param {text} pRendered - Обработанные данные
 * @param {text} pData - Данные
 * @param {text} pRaw - Необработанные данные
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {uuid} pPriority - Приоритет
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_post (
  pParent       uuid,
  pType         uuid,
  pStructure    uuid,
  pApprover     uuid default null,
  pExecutor     uuid default null,
  pObserver     uuid default null,
  pContent      text default null,
  pRendered     text default null,
  pData         text default null,
  pRaw      	text default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null,
  pPriority     uuid default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreatePost(pParent, coalesce(pType, GetType('author.post')), pStructure, pApprover, pExecutor, pObserver, pContent, pRendered, pData, pRaw, pCode, pLabel, pDescription, pPriority);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_post -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует руководство.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pStructure - Структура
 * @param {uuid} pApprover - Утверждающий
 * @param {uuid} pExecutor - Исполнитель
 * @param {uuid} pObserver - Наблюдатель
 * @param {text} pContent - Содержимое
 * @param {text} pRendered - Обработанные данные
 * @param {text} pData - Данные
 * @param {text} pRaw - Необработанные данные
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {uuid} pPriority - Приоритет
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_post (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pStructure    uuid default null,
  pApprover     uuid default null,
  pExecutor     uuid default null,
  pObserver     uuid default null,
  pContent      text default null,
  pRendered     text default null,
  pData         text default null,
  pRaw      	text default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null,
  pPriority     uuid default null
) RETURNS       void
AS $$
DECLARE
  uDocument     uuid;
BEGIN
  SELECT c.id INTO uDocument FROM db.post c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('post', 'id', pId);
  END IF;

  PERFORM EditPost(uDocument, pParent, pType, pStructure, pApprover, pExecutor, pObserver, pContent, pRendered, pData, pRaw, pCode, pLabel, pDescription, pPriority);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_post ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_post (
  pId		    uuid,
  pParent	    uuid default null,
  pType         uuid default null,
  pStructure    uuid default null,
  pApprover     uuid default null,
  pExecutor     uuid default null,
  pObserver     uuid default null,
  pContent      text default null,
  pRendered     text default null,
  pData         text default null,
  pRaw      	text default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null,
  pPriority     uuid default null
) RETURNS       SETOF api.post
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_post(pParent, pType, pStructure, pApprover, pExecutor, pObserver, pContent, pRendered, pData, pRaw, pCode, pLabel, pDescription, pPriority);
  ELSE
    PERFORM api.update_post(pId, pParent, pType, pStructure, pApprover, pExecutor, pObserver, pContent, pRendered, pData, pRaw, pCode, pLabel, pDescription, pPriority);
  END IF;

  RETURN QUERY SELECT * FROM api.post WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_post ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает руководство
 * @param {uuid} pId - Идентификатор
 * @return {api.post}
 */
CREATE OR REPLACE FUNCTION api.get_post (
  pId		uuid
) RETURNS	api.post
AS $$
  SELECT * FROM api.post WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_post ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает руководство в виде списка.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.post}
 */
CREATE OR REPLACE FUNCTION api.list_post (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.post
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'post', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.post_content ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.post_content
AS
  SELECT * FROM PostContent;

GRANT SELECT ON api.post_content TO administrator;

--------------------------------------------------------------------------------
-- api.get_post_content --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает содержимое руководства
 * @param {uuid} pId - Идентификатор
 * @return {api.post}
 */
CREATE OR REPLACE FUNCTION api.get_post_content (
  pId		uuid
) RETURNS	api.post_content
AS $$
  SELECT * FROM api.post_content WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_post_content -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает содержимое руководства в виде списка.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.post}
 */
CREATE OR REPLACE FUNCTION api.list_post_content (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.post_content
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'post_content', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
