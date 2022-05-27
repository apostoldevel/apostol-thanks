--------------------------------------------------------------------------------
-- CreateTransaction -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт транзакцию
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
 * @param {uuid} pClient - Клиент
 * @param {uuid} pService - Услуга
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pPrice - Цена
 * @param {numeric} pVolume - Объём
 * @param {numeric} pAmount - Сумма
 * @param {text} pLabel - Тема
 * @param {text} pDescription - Описание
 * @return {uuid} - Id
 */
CREATE OR REPLACE FUNCTION CreateTransaction (
  pParent	    uuid,
  pType		    uuid,
  pClient       uuid,
  pService      uuid,
  pInvoice      uuid,
  pPrice		numeric,
  pVolume       numeric,
  pAmount       numeric,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    uuid
AS $$
DECLARE
  uId		    uuid;
  uDocument	    uuid;
  nTransaction  uuid;

  uClass	    uuid;
  uMethod	    uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'transaction' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('клиент', 'id', pClient);
  END IF;

  SELECT id INTO uId FROM db.service WHERE id = pService;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('услуга', 'id', pService);
  END IF;

  IF pInvoice IS NOT NULL THEN
    SELECT id INTO uId FROM db.invoice WHERE id = pInvoice;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('счёт', 'id', pInvoice);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.transaction (id, document, client, service, invoice, price, volume, amount)
  VALUES (uDocument, uDocument, pClient, pService, pInvoice, pPrice, pVolume, pAmount)
  RETURNING id INTO nTransaction;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(nTransaction, uMethod);

  RETURN nTransaction;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTransaction -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует транзакцию.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
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
CREATE OR REPLACE FUNCTION EditTransaction (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pClient       uuid default null,
  pService      uuid default null,
  pInvoice      uuid default null,
  pPrice		numeric default null,
  pVolume       numeric default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    void
AS $$
DECLARE
  uId		    uuid;
  uClass	    uuid;
  uMethod	    uuid;
BEGIN
  SELECT id INTO uId FROM db.transaction WHERE id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('транзакция', 'id', pId);
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.transaction
     SET client = coalesce(pClient, client),
         service = coalesce(pService, service),
         invoice = CheckNull(coalesce(pInvoice, invoice, null_uuid())),
         price = coalesce(pPrice, price),
         volume = coalesce(pVolume, volume),
         amount = coalesce(pAmount, amount)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransaction --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTransaction (
  pParent		uuid,
  pClient       uuid,
  pService      uuid,
  pState		uuid
) RETURNS 	    uuid
AS $$
  SELECT t.id
	FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = pParent AND o.state = pState
   WHERE client = pClient
	 AND service = pService
	 AND invoice IS NULL;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransactionSum -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTransactionSum (
  pParent		uuid,
  pClient       uuid,
  pService      uuid,
  pState		uuid
) RETURNS 	    numeric
AS $$
  SELECT Sum(amount)
	FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = pParent AND o.state = pState
   WHERE client = pClient
	 AND service = pService
	 AND invoice IS NULL;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTransactionVolume --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTransactionVolume (
  pParent		uuid,
  pClient       uuid,
  pService      uuid,
  pState		uuid
) RETURNS 	    numeric
AS $$
  SELECT Sum(volume)
	FROM db.transaction t INNER JOIN db.object o ON t.document = o.id AND o.parent = pParent AND o.state = pState
   WHERE client = pClient
	 AND service = pService
	 AND invoice IS NULL;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
