--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.order -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.order
AS
  SELECT * FROM ObjectOrder;

GRANT SELECT ON api.order TO administrator;

--------------------------------------------------------------------------------
-- api.add_order ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет ордер.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {text} pType - Tип
 * @param {text} pCode - Код
 * @param {uuid} pClient - Клиент
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pAmount - Сумма
 * @param {uuid} pOrderId - Номер заказа
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_order (
  pParent       uuid,
  pType         text,
  pCode         text,
  pClient       uuid,
  pInvoice      uuid,
  pAmount       numeric,
  pOrderId      uuid default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateOrder(pParent, CodeToType(lower(coalesce(pType, 'reserve')), 'order'), pCode, pClient, pInvoice, pAmount, pOrderId, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_order ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует ордер.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
 * @param {text} pCode - Код
 * @param {uuid} pClient - Клиент
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pAmount - Сумма
 * @param {uuid} pOrderId - Номер заказа
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_order (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    text default null,
  pCode		    text default null,
  pClient       uuid default null,
  pInvoice      uuid default null,
  pAmount       numeric default null,
  pOrderId      uuid default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uType         uuid;
  nOrder        uuid;
BEGIN
  pId := coalesce(NULLIF(pId, 0), GetOrder(pCode));

  SELECT c.id INTO nOrder FROM db.order c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('заказ', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'order');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditOrder(nOrder, pParent, uType,pCode, pClient, pInvoice, pAmount, pOrderId, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_order ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_order (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    text default null,
  pCode		    text default null,
  pClient       uuid default null,
  pInvoice      uuid default null,
  pAmount       numeric default null,
  pOrderId      uuid default null,
  pDescription	text default null
) RETURNS       SETOF api.order
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_order(pParent, pType, pCode, pClient, pInvoice, pAmount, pOrderId, pDescription);
  ELSE
    PERFORM api.update_order(pId, pParent, pType, pCode, pClient, pInvoice, pAmount, pOrderId, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.order WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает ордер
 * @param {uuid} pId - Идентификатор
 * @return {api.order} - Ордер
 */
CREATE OR REPLACE FUNCTION api.get_order (
  pId		uuid
) RETURNS	api.order
AS $$
  SELECT * FROM api.order WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_order --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список ордеров.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.order} - Ордера
 */
CREATE OR REPLACE FUNCTION api.list_order (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.order
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'order', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

