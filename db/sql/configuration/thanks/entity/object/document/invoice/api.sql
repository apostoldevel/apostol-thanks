--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.invoice -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.invoice
AS
  SELECT o.*, p.data::json AS charge_point, t.data::json AS transactions, c.data::json AS cars, k.data AS kkt
    FROM ObjectInvoice o LEFT JOIN db.object_data p ON p.object = o.object AND p.type = 'json' AND p.code = 'charge_point'
                         LEFT JOIN db.object_data t ON t.object = o.object AND t.type = 'json' AND t.code = 'transactions'
                         LEFT JOIN db.object_data c ON c.object = o.object AND c.type = 'json' AND c.code = 'cars'
                         LEFT JOIN db.object_data k ON k.object = o.object AND k.type = 'text' AND k.code = 'kkt';

GRANT SELECT ON api.invoice TO administrator;

--------------------------------------------------------------------------------
-- api.add_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет счёт на оплату.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {text} pType - Tип
 * @param {uuid} pClient - Клиент
 * @param {numeric} pAmount - Сумма
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_invoice (
  pParent       uuid,
  pType         text,
  pClient       uuid,
  pAmount       numeric,
  pCode		    text default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateInvoice(pParent, CodeToType(lower(coalesce(pType, 'meter')), 'invoice'), pClient, pAmount, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_invoice ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует параметры счёта на оплату (но не сам счёт).
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {text} pType - Тип
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_invoice (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    text default null,
  pClient       uuid default null,
  pAmount       numeric default null,
  pCode		    text default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uType         uuid;
  nInvoice      uuid;
BEGIN
  SELECT c.id INTO nInvoice FROM db.invoice c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('заказ', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'invoice');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditInvoice(nInvoice, pParent, uType, pClient, pAmount, pCode, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_invoice (
  pId		    uuid,
  pParent	    uuid default null,
  pType         text default null,
  pClient       uuid default null,
  pAmount       numeric default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.invoice
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_invoice(pParent, pType, pClient, pAmount, pCode, pLabel, pDescription);
  ELSE
    PERFORM api.update_invoice(pId, pParent, pType, pClient, pAmount, pCode, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.invoice WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_invoice -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает счёт
 * @param {uuid} pId - Идентификатор
 * @return {api.invoice} - Счёт
 */
CREATE OR REPLACE FUNCTION api.get_invoice (
  pId		uuid
) RETURNS	api.invoice
AS $$
  SELECT * FROM api.invoice WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_invoice ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список счетов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.invoice} - Счета
 */
CREATE OR REPLACE FUNCTION api.list_invoice (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.invoice
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'invoice', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.check_invoice -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Проверяет счета.
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.check_invoice()
RETURNS	void
AS $$
DECLARE
  r			record;
  e			record;
  i			record;

  uArea     uuid;

  dtDate    timestamptz;

  vCode     text;

  params	jsonb;
BEGIN
  uArea := GetSessionArea();

  FOR r IN
	SELECT t.id, d.area
	  FROM db.invoice t INNER JOIN db.object   o ON o.id = t.document
	                    INNER JOIN db.document d ON d.id = t.document
                        INNER JOIN db.state    s ON o.state = s.id AND s.code IN ('created', 'failed')
  LOOP
    PERFORM SetSessionArea(r.area);

    params := GetObjectDataJSON(r.id, 'params')::jsonb;

    FOR e IN SELECT * FROM jsonb_to_record(params) AS x(auto_payment boolean)
    LOOP
      SELECT statecode INTO vCode FROM Object WHERE id = r.id;
	  IF coalesce(e.auto_payment, true) THEN
		IF vCode = 'failed' THEN
		  PERFORM ExecuteObjectAction(r.id, GetAction('cancel'));
		END IF;
	    PERFORM ExecuteObjectAction(r.id, GetAction('enable'), jsonb_build_object('clear_hash', false));
	  ELSE
	    SELECT ldate INTO dtDate FROM db.object WHERE id = r.id;
	    IF Now() - dtDate >= interval '1 day' THEN
          IF vCode = 'failed' THEN
            PERFORM ExecuteObjectAction(r.id, GetAction('cancel'));
          END IF;
          PERFORM ExecuteObjectAction(r.id, GetAction('enable'), jsonb_build_object('clear_hash', true));
		END IF;
	  END IF;
	END LOOP;
  END LOOP;

  FOR i IN
	SELECT o.parent as connector, d.area
	  FROM db.transaction t INNER JOIN db.object   o ON o.id = t.document
	                        INNER JOIN db.document d ON d.id = t.document
                            INNER JOIN db.state    s ON o.state = s.id AND s.code = 'disabled'
       AND t.invoice IS NULL
     GROUP BY connector, area
  LOOP
    PERFORM SetSessionArea(i.area);
	PERFORM BuildInvoice(i.connector);
  END LOOP;

  PERFORM SetSessionArea(uArea);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
