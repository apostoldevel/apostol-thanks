--------------------------------------------------------------------------------
-- CreateOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт счёт на оплату
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип: Type.Id
 * @param {text} pCode - Код
 * @param {uuid} pClient - Клиент
 * @param {uuid} pInvoice - Счёт
 * @param {numeric} pAmount - Сумма
 * @param {uuid} pOrderId - Номер заказа
 * @param {text} pDescription - Описание
 * @return {uuid} - Id
 */
CREATE OR REPLACE FUNCTION CreateOrder (
  pParent	    uuid,
  pType		    uuid,
  pCode		    text,
  pClient       uuid,
  pInvoice      uuid,
  pAmount	    numeric,
  pOrderId      uuid default null,
  pDescription	text default null
) RETURNS 	    uuid
AS $$
DECLARE
  uId		    uuid;
  nOrder	    uuid;
  uDocument	    uuid;

  uClass	    uuid;
  uMethod	    uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'order' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.order WHERE code = pCode;

  IF found THEN
    PERFORM OrderCodeExists(pCode);
  END IF;

  SELECT id INTO uId FROM db.client WHERE id = pClient;

  IF not found THEN
    PERFORM ObjectNotFound('клиент', 'id', pClient);
  END IF;

  IF GetTypeCode(pType) = 'payment.order' THEN
    SELECT id INTO uId FROM db.invoice WHERE id = pInvoice;
    IF not found THEN
      PERFORM ObjectNotFound('счёт', 'id', pInvoice);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pCode, pDescription);

  INSERT INTO db.order (id, document, code, client, invoice, amount, orderId)
  VALUES (uDocument, uDocument, pCode, pClient, pInvoice, pAmount, pOrderId)
  RETURNING id INTO nOrder;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(nOrder, uMethod);

  RETURN nOrder;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditOrder -------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует параметры счёта на оплату (но не сам счёт).
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
CREATE OR REPLACE FUNCTION EditOrder (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pCode		    text default null,
  pClient       uuid default null,
  pInvoice      uuid default null,
  pAmount	    numeric default null,
  pOrderId      uuid default null,
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
  SELECT code INTO cCode FROM db.order WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  SELECT id INTO uId FROM db.client WHERE id = pClient;

  IF not found THEN
    PERFORM ObjectNotFound('клиент', 'id', pClient);
  END IF;

  IF pCode <> cCode THEN
    SELECT id INTO uId FROM db.order WHERE code = pCode;
    IF found THEN
      PERFORM OrderCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pCode, pDescription);

  UPDATE db.order
     SET code = coalesce(pCode, code),
         client = coalesce(pClient, client),
         invoice = coalesce(pInvoice, invoice),
         amount = coalesce(pAmount, amount),
         orderId = coalesce(pOrderId, orderId)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrder --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrder (
  pCode		text
) RETURNS	uuid
AS $$
DECLARE
  uId		uuid;
BEGIN
  SELECT id INTO uId FROM db.order WHERE code = pCode;
  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderAmount --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrderAmount (
  pOrder	uuid
) RETURNS	uuid
AS $$
DECLARE
  nAmount	numeric;
BEGIN
  SELECT amount INTO nAmount FROM db.order WHERE id = pOrder;
  RETURN nAmount;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
