--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.transaction -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.transaction
AS
  SELECT * FROM ObjectTransaction;

GRANT SELECT ON api.transaction TO administrator;

--------------------------------------------------------------------------------
-- api.add_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет транзакцию.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {text} pType - Код типа
 * @param {uuid} pClient - Клиент
 * @param {uuid} pService - Услуга
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pPrice - Цена
 * @param {numeric} pVolume - Объём
 * @param {numeric} pAmount - Сумма
 * @param {text} pLabel - Тема
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_transaction (
  pParent       uuid,
  pType         text,
  pClient       uuid,
  pService      uuid,
  pInvoice      uuid,
  pPrice		numeric,
  pVolume       numeric,
  pAmount       numeric,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateTransaction(pParent, CodeToType(lower(coalesce(pType, 'expense.transaction')), 'transaction'), pClient, pService, pInvoice, pPrice, pVolume, pAmount, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_transaction ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует транзакцию.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {text} pType - Код типа
 * @param {uuid} pClient - Клиент
 * @param {uuid} pService - Услуга
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pPrice - Цена
 * @param {numeric} pVolume - Объём
 * @param {numeric} pAmount - Сумма
 * @param {text} pLabel - Тема
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_transaction (
  pId           uuid,
  pParent       uuid default null,
  pType         text default null,
  pClient       uuid default null,
  pService      uuid default null,
  pInvoice      uuid default null,
  pPrice		numeric default null,
  pVolume       numeric default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uType         uuid;
  nTransaction  uuid;
BEGIN
  SELECT c.id INTO nTransaction FROM db.transaction c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('транзакцию', 'id', pId);
  END IF;

  IF pType IS NOT NULL THEN
    uType := CodeToType(lower(pType), 'transaction');
  ELSE
    SELECT o.type INTO uType FROM db.object o WHERE o.id = pId;
  END IF;

  PERFORM EditTransaction(nTransaction, pParent, uType, pClient, pService, pInvoice, pPrice, pVolume, pAmount, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_transaction (
  pId			uuid,
  pParent		uuid default null,
  pType			text default null,
  pClient       uuid default null,
  pService      uuid default null,
  pInvoice      uuid default null,
  pPrice		numeric default null,
  pVolume       numeric default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS		SETOF api.transaction
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_transaction(pParent, pType, pClient, pService, pInvoice, pPrice, pVolume, pAmount, pLabel, pDescription);
  ELSE
    PERFORM api.update_transaction(pId, pParent, pType, pClient, pService, pInvoice, pPrice, pVolume, pAmount, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.transaction WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_transaction ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает транзакцию
 * @param {uuid} pId - Идентификатор
 * @return {api.transaction}
 */
CREATE OR REPLACE FUNCTION api.get_transaction (
  pId		uuid
) RETURNS	api.transaction
AS $$
  SELECT * FROM api.transaction WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_transaction --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список транзакциюов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.transaction}
 */
CREATE OR REPLACE FUNCTION api.list_transaction (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.transaction
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'transaction', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_wait_transaction -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.update_wait_transaction (
  pId		uuid
) RETURNS	boolean
AS $$
BEGIN
  IF GetObjectStateCode(pId) = 'finishing' THEN
    RETURN UpdateWaitTransaction(pId);
  END IF;

  PERFORM SetErrorMessage('Статус соединителя должен быть: Finishing.');

  RETURN false;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_transaction -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.current_transaction (
  pClient		uuid,
  pConnector	uuid
) RETURNS		jsonb
AS $$
DECLARE
  r				record;
  e				record;
  d				record;
  tx            record;
  rv            record;
  cr            record;
  lr            record;

  uState		uuid;

  reservationId integer;

  vLabel		text;

  connector		jsonb;
  transaction   jsonb;
  reservation   jsonb;
  limited       jsonb;
  transactions	jsonb;
BEGIN
  uState := GetObjectState(pConnector);
  vLabel := GetObjectLabel(pConnector);

  SELECT id, code, label INTO e FROM State WHERE id = uState;
  SELECT *, vLabel AS label INTO d FROM kernel.Connector WHERE id = pConnector;

  FOR cr IN
    SELECT c.id
      FROM db.card c INNER JOIN db.object o ON c.document = o.id
                     INNER JOIN db.type   t ON o.type = t.id AND t.code = 'rfid.card'
     WHERE c.client = pClient
  LOOP
	SELECT * INTO tx
	  FROM db.charge_point_transaction
	 WHERE card = cr.id
	   AND chargepoint = d.chargepoint
	   AND connectorid = d.connectorid
	   AND datestart <= Now()
	   AND datestop > Now();

	IF FOUND THEN
	  transaction := row_to_json(tx)::jsonb;
	END IF;

	SELECT max(id) INTO reservationId
	  FROM db.charge_point_reservation
	 WHERE card = cr.id
	   AND chargepoint = d.chargepoint
	   AND connectorid = d.connectorid
	   AND datestart <= Now()
	   AND datestop + interval '15 min' > Now();

	IF FOUND THEN
	  SELECT * INTO rv FROM db.charge_point_reservation WHERE id = reservationId;
      IF FOUND THEN
	    reservation := row_to_json(rv)::jsonb;
	  END IF;
	END IF;

	SELECT * INTO lr
	  FROM db.charge_point_limit
	 WHERE card = cr.id
	   AND chargePoint = d.chargepoint
	   AND connectorId = d.connectorid
	   AND validFromDate <= Now()
	   AND validToDate > Now();

	IF FOUND THEN
	  limited := row_to_json(lr)::jsonb;
	END IF;
  END LOOP;

  connector := row_to_json(d)::jsonb || jsonb_build_object('state', row_to_json(e));

  FOR r IN
	SELECT o.parent, Sum(amount) AS total
	  FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = pConnector AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
	 WHERE t.client = pClient
	   AND t.invoice IS NULL
     GROUP BY o.parent
  LOOP
    transactions := jsonb_build_array();

	FOR e IN
	  SELECT t.id, t.service, t.price, t.volume, t.amount
		FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = r.parent AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
	   WHERE t.client = pClient
		 AND t.invoice IS NULL
	LOOP
      SELECT * INTO d FROM Service WHERE id = e.service;
      transactions := transactions || jsonb_build_object('id', e.id, 'service', row_to_json(d), 'price', e.price, 'volume', e.volume, 'amount', e.amount);
	END LOOP;

    RETURN jsonb_build_object('client', pClient, 'total', r.total, 'transactionId', transaction->'id', 'transaction', transaction, 'reservationId', reservation->'id', 'reservation', reservation, 'limited', limited, 'connector', connector, 'transactions', transactions);
  END LOOP;

  RETURN jsonb_build_object('client', pClient, 'total', 0, 'transactionId', transaction->'id', 'transaction', transaction, 'reservationId', reservation->'id', 'reservation', reservation, 'limited', limited, 'connector', connector, 'transactions', transactions);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
