--------------------------------------------------------------------------------
-- CONTRACT --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.contract ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.contract
AS
  SELECT * FROM ObjectContract;

GRANT SELECT ON api.contract TO administrator;

--------------------------------------------------------------------------------
-- api.add_contract ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет договор.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип карты
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pContent - Содержимое
 * @param {text} pData - Данные
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_contract (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateContract(pParent, coalesce(pType, GetType('offer.contract')), pClient, pCode, pContent, pData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_contract ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет договор.
 * @param {uuid} pId - Идентификатор карты (api.get_contract)
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип карты
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pContent - Содержимое
 * @param {text} pData - Данные
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_contract (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCode         text default null,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uContract     uuid;
BEGIN
  SELECT c.id INTO uContract FROM db.contract c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('договор', 'id', pId);
  END IF;

  PERFORM EditContract(uContract, pParent, pType, pClient, pCode, pContent, pData, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_contract ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_contract (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCode         text default null,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.contract
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_contract(pParent, pType, pClient, pCode, pContent, pData, pLabel, pDescription);
  ELSE
    PERFORM api.update_contract(pId, pParent, pType, pClient, pCode, pContent, pData, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.contract WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_contract ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает договор
 * @param {uuid} pId - Идентификатор
 * @return {api.contract} - Клиент
 */
CREATE OR REPLACE FUNCTION api.get_contract (
  pId		uuid
) RETURNS	api.contract
AS $$
  SELECT * FROM api.contract WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_contract -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список договоров.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.contract} - Клиенты
 */
CREATE OR REPLACE FUNCTION api.list_contract (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.contract
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'contract', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
