--------------------------------------------------------------------------------
-- CreateInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт счёт на оплату
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
 * @param {uuid} pClient - Клиент
 * @param {numeric} pAmount - Сумма
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid} - Id
 */
CREATE OR REPLACE FUNCTION CreateInvoice (
  pParent	    uuid,
  pType		    uuid,
  pClient       uuid,
  pAmount       numeric,
  pCode		    text default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    uuid
AS $$
DECLARE
  uId		    uuid;
  nInvoice	    uuid;
  uDocument	    uuid;

  uClass	    uuid;
  uMethod	    uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'invoice' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.invoice WHERE code = pCode;

  IF found THEN
    PERFORM InvoiceCodeExists(pCode);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.invoice (id, document, code, client, amount)
  VALUES (uDocument, uDocument, pCode, pClient, pAmount)
  RETURNING id INTO nInvoice;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(nInvoice, uMethod);

  RETURN nInvoice;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditInvoice -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует параметры счёта на оплату (но не сам счёт).
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
 * @param {uuid} pClient - Клиент
 * @param {numeric} pAmount - Сумма
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditInvoice (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pClient       uuid default null,
  pAmount       numeric default null,
  pCode		    text default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    void
AS $$
DECLARE
  uId		    uuid;
  uClass	    uuid;
  uMethod	    uuid;

  -- current
  cCode		    text;
BEGIN
  SELECT id, code INTO uId, cCode FROM db.invoice WHERE id = pId;

  IF not found THEN
    PERFORM ObjectNotFound('счёт', 'id', pId);
  END IF;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    SELECT id INTO uId FROM db.invoice WHERE code = pCode;
    IF found THEN
      PERFORM InvoiceCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.invoice
     SET client = coalesce(pClient, client),
         amount = coalesce(pAmount, amount),
         code = pCode
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoice ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetInvoice (
  pCode		text
) RETURNS	uuid
AS $$
DECLARE
  uId		uuid;
BEGIN
  SELECT id INTO uId FROM db.invoice WHERE code = pCode;
  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoiceCode --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetInvoiceCode (
  pInvoice	uuid
) RETURNS	text
AS $$
DECLARE
  vCode		text;
BEGIN
  SELECT code INTO vCode FROM db.invoice WHERE id = pInvoice;
  RETURN vCode;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetInvoiceAmount ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetInvoiceAmount (
  pInvoice	uuid
) RETURNS	uuid
AS $$
DECLARE
  nAmount	numeric;
BEGIN
  SELECT amount INTO nAmount FROM db.invoice WHERE id = pInvoice;
  RETURN nAmount;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- BuildInvoice ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создает счёт.
 * @param {uuid} pConnector - Идентификатор соединителя зарядной станции
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION BuildInvoice (
  pConnector	uuid
) RETURNS 	    uuid
AS $$
DECLARE
  r				record;
  x				record;
  e				record;
  a				record;

  nInvoice		uuid;

  transactions	json[];
  cars			json[];
BEGIN
  SELECT cp.id, c.id AS connector, cp.identity, c.connectorid INTO e
    FROM db.connector c INNER JOIN db.charge_point cp ON cp.id = c.chargepoint
   WHERE c.id = pConnector;

  FOR r IN
    SELECT t.client, Sum(t.amount) AS amount
      FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = pConnector
                            INNER JOIN db.state  s ON s.id = o.state AND s.code = 'disabled'
     WHERE t.invoice IS NULL
     GROUP BY t.client
    HAVING Sum(t.amount) > 1
  LOOP
	nInvoice := CreateInvoice(pConnector, GetType('payment.invoice'), r.client, r.amount);

	FOR x IN
	  SELECT t.*, ot.label
	    FROM Transaction t INNER JOIN db.object       o ON o.id = t.document AND o.parent = pConnector
                           INNER JOIN db.state        s ON s.id = o.state AND s.code = 'disabled'
	                        LEFT JOIN db.object_text ot ON ot.object = o.id AND ot.locale = current_locale()
	   WHERE t.client = r.client
		 AND t.invoice IS NULL
	LOOP
	  UPDATE db.transaction SET invoice = nInvoice WHERE id = x.id;
	  transactions := array_append(transactions, row_to_json(x));
	END LOOP;

	FOR a IN SELECT * FROM Car WHERE client = r.client
	LOOP
	  cars := array_append(cars, row_to_json(a));
	END LOOP;

    PERFORM SetObjectDataJSON(nInvoice, 'charge_point', row_to_json(e));
    PERFORM SetObjectDataJSON(nInvoice, 'transactions', array_to_json(transactions));
    PERFORM SetObjectDataJSON(nInvoice, 'cars', array_to_json(cars));

    PERFORM SendPush(pConnector, 'Счёт на оплату', format('Сформирован счёт на сумму %s рублей.', r.amount), GetClientUserId(r.client));
  END LOOP;

  RETURN nInvoice;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateCloudPaymentContent ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateCloudPaymentContent (
  pInvoice      uuid
) RETURNS       jsonb
AS $$
DECLARE
  r				record;

  uUserId		uuid;
  uClient		uuid;
  uServices		uuid[];

  inn			text;
  ts			text;

  receipt		jsonb;
  items			jsonb;

  nAmount		numeric;

  vEmail		text;
  vPhone		text;

  bVerPhone		bool;
  bVerEmail		bool;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.invoice WHERE id = pInvoice;

  uUserId := GetClientUserId(uClient);

  SELECT email, phone, email_verified, phone_verified INTO vEmail, vPhone, bVerEmail, bVerPhone
	FROM db.user u INNER JOIN db.profile p ON u.id = p.userid
   WHERE id = uUserId;

  uServices := ARRAY[GetService('suspended.service'), GetService('waiting.service')];

  inn := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'Inn', uUserId);
  ts := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Service\CloudPayments', 'TaxationSystem', uUserId);

  items := jsonb_build_array();

  FOR r IN
	SELECT t.volume, t.amount, t.price, e.measurename, ot.label
	  FROM Transaction t INNER JOIN db.object       o ON o.id = t.document
						 INNER JOIN db.state        s ON s.id = o.state AND s.code = 'disabled'
						 INNER JOIN Service         e ON e.id = t.service
						  LEFT JOIN db.object_text ot ON ot.object = o.id AND ot.locale = current_locale()
	 WHERE t.invoice = pInvoice
	   AND t.service NOT IN (SELECT unnest(uServices))
       AND t.amount > 0
  LOOP
    r.volume := trunc(r.amount / r.price, 2);
	items := items || jsonb_build_object('label', r.label, 'price', r.price, 'quantity', r.volume, 'amount', r.amount, 'vat', 20, 'method', 4, 'object', 4, 'measurementUnit', r.measurename);
  END LOOP;

  FOR r IN
	SELECT Sum(t.volume) AS volume, Sum(t.amount) AS amount, trunc(Avg(t.price), 2) AS price, e.measurename, 'Ожидание' AS label
	  FROM Transaction t INNER JOIN db.object       o ON o.id = t.document
						 INNER JOIN db.state        s ON s.id = o.state AND s.code = 'disabled'
						 INNER JOIN Service         e ON e.id = t.service
						  LEFT JOIN db.object_text ot ON ot.object = o.id AND ot.locale = current_locale()
	 WHERE t.invoice = pInvoice
	   AND t.service IN (SELECT unnest(uServices))
       AND t.amount > 0
     GROUP BY e.measurename
  LOOP
    r.volume := trunc(r.amount / r.price, 2);
	items := items || jsonb_build_object('label', r.label, 'price', r.price, 'quantity', r.volume, 'amount', r.amount, 'vat', 20, 'method', 4, 'object', 4, 'measurementUnit', r.measurename);
  END LOOP;

  receipt := jsonb_build_object('Items', items, 'TaxationSystem', ts, 'Amounts', jsonb_build_object('electronic', nAmount));
  receipt := receipt || jsonb_build_object('email', vEmail);

  IF bVerPhone THEN
    receipt := receipt || jsonb_build_object('phone', vPhone);
  END IF;

  RETURN jsonb_build_object('Inn', inn, 'InvoiceId', pInvoice, 'Type', 'Income', 'CustomerReceipt', receipt);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SendCloudPayment ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SendCloudPayment (
  pInvoice      uuid
) RETURNS       uuid
AS $$
DECLARE
  profile		text;
  address		text;
  subject		text;

  content		jsonb;

  vMessage      text;
  vContext      text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  profile := 'cloudpayments';
  address := '/kkt/receipt';
  subject := 'receipt';
  content := CreateCloudPaymentContent(pInvoice);

  RETURN SendMessage(pInvoice, GetAgent('cloudkassir.agent'), profile, address, subject, content::text);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SendCloudPaymentTest --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SendCloudPaymentTest (
  pInvoice      uuid
) RETURNS       uuid
AS $$
DECLARE
  profile		text;
  address		text;
  subject		text;

  vMessage      text;
  vContext      text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  profile := 'cloudpayments';
  address := 'test';
  subject := 'test';

  RETURN SendMessage(pInvoice, GetAgent('cloudkassir.agent'), profile, address, subject, null);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
