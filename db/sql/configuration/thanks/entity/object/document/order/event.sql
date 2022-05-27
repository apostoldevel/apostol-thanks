--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventOrderCreate ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Ордер создан.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderOpen --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Ордер открыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEdit --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderEdit (
  pObject	uuid default context_object(),
  pParams	jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Ордер изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderSave --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Ордер сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEnable ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uUserId		uuid;
  uClient		uuid;
  uMessage      uuid;

  nAmount       numeric;

  vTypeCode		text;
  subject		text;

  orderNumber	text;
  description	text;

  host			text;
  profile		text;
  address		text;
  content		text;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Ордер отправлен.', pObject);

  SELECT code, client, amount INTO orderNumber, uClient, nAmount FROM db.order WHERE id = pObject;
  SELECT userid INTO uUserId FROM db.client WHERE id = uClient;

  host := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', uUserId);
  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile', uUserId);

  profile := coalesce(profile, 'main');

  vTypeCode := GetObjectTypeCode(pObject);

  IF vTypeCode = 'payment.order' THEN
    address := '/payment/rest/register.do';
	subject := 'register.do';
  ELSE
    address := '/payment/rest/registerPreAuth.do';
	subject := 'registerPreAuth.do';
  END IF;

  description := GetDocumentDescription(pObject);

  content := format('clientId=%s', uClient);
  content := content || format('&amount=%s', IntToStr(nAmount * 100));
  content := content || '&features=AUTO_PAYMENT';
  content := content || format('&orderNumber=%s', orderNumber);
  content := content || format('&returnUrl=%s', format('%s/payment/callback/register.do?orderNumber=%s', host, orderNumber));

  --uMessage := SendMessage(pObject, GetAgent('sba.agent'), profile, address, subject, content, description);

  PERFORM AddMethodStack(jsonb_build_object('profile', profile, 'address', address, 'content', content, 'message', uMessage, 'order', pObject));
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderCancel ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderCancel (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uClient       uuid;
  uMessage      uuid;
  uOrderId      uuid;

  profile		text;
  subject		text;
  address		text;
  content		text;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Ордер отменён.', pObject);

  SELECT orderid, client INTO uOrderId, uClient FROM db.order WHERE id = pObject;

  IF uOrderId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'deleted', 'Order Id cannot be empty.', pObject);
	RETURN;
  END IF;

  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile');
  profile := coalesce(profile, 'main');

  address := '/payment/rest/reverse.do';
  subject := 'reverse.do';

  content := format('orderId=%s', uOrderId::text);

  --uMessage := SendMessage(pObject, GetAgent('sba.agent'), profile, address, subject, content);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderReturn ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderReturn (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uClient       uuid;
  uMessage      uuid;
  uOrderId      uuid;

  nAmount       numeric;

  profile		text;
  subject		text;
  address		text;
  content		text;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'return', 'Ордер возвращён.', pObject);

  SELECT orderid, client, amount INTO uOrderId, uClient, nAmount FROM db.order WHERE id = pObject;

  IF uOrderId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'deleted', 'Order Id cannot be empty.', pObject);
	RETURN;
  END IF;

  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile');
  profile := coalesce(profile, 'main');

  address := '/payment/rest/refund.do';
  subject := 'refund.do';

  content := format('orderId=%s', uOrderId::text);
  content := content || format('&amount=%s', IntToStr(nAmount * 100));

  --uMessage := SendMessage(pObject, GetAgent('sba.agent'), profile, address, subject, content);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDisable -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDisable (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  r				record;

  uInvoice      uuid;
  uClient       uuid;
  uMessage      uuid;
  uOrderId      uuid;

  jBindings		jsonb;
  jHashList		jsonb;

  aBindList		text[];
  aHashList		text[];

  nIndex		integer;

  vBindingId	text;
  vSecret       text;

  profile		text;
  subject		text;
  address		text;
  content		text;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'disable', 'Ордер выполнен.', pObject);

  SELECT invoice, orderid, client INTO uInvoice, uOrderId, uClient FROM db.order WHERE id = pObject;

  IF uOrderId IS NULL THEN
    PERFORM WriteToEventLog('W', 2000, 'disable', 'Order Id cannot be empty.', pObject);
	RETURN;
  END IF;

  IF GetObjectTypeCode(pObject) = 'validation.order' THEN
    vSecret := GetObjectData(pObject, 'text', 'hidden');
    PERFORM SetObjectData(pObject, 'text', 'hidden', null);

    vBindingId := GetObjectData(pObject, 'text', 'bindingId');

    IF vBindingId IS NOT NULL THEN
	  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile');
	  profile := coalesce(profile, 'main');

	  subject := 'paymentOrderBinding.do';
	  address := '/payment/rest/paymentOrderBinding.do';

	  content := format('mdOrder=%s', uOrderId::text);
	  content := content || format('&bindingId=%s', vBindingId);

	  IF vSecret IS NOT NULL THEN
	    content := content || format('&cvc=%s', vSecret);
	  END IF;

	  --uMessage := SendMessage(pObject, GetAgent('sba.agent'), profile, address, subject, content);
	ELSE
      PERFORM WriteToEventLog('W', 2000, 'disable', 'Binding Id cannot be empty.', pObject);
	END IF;

	RETURN;
  END IF;

  IF uInvoice IS NULL THEN
	RETURN;
  END IF;

  IF NOT IsEnabled(uInvoice) THEN
	RETURN;
  END IF;

  jBindings := GetObjectDataJSON(uClient, 'bindings')::jsonb;

  IF nullif(jBindings, '[]'::jsonb) IS NULL THEN
    PERFORM EditDocument(uInvoice, pDescription => 'Оплата невозможна. Список привязанных карт пуст.');
    PERFORM ExecuteObjectAction(uInvoice, GetAction('fail'));
	RETURN;
  END IF;

  FOR r IN SELECT * FROM jsonb_to_recordset(jBindings) AS x("bindingId" text)
  LOOP
	aBindList := array_append(aBindList, r."bindingId");
	aHashList := array_append(aHashList, encode(digest(r."bindingId", 'md5'), 'hex'));
  END LOOP;

  IF aBindList IS NULL THEN
	RETURN;
  END IF;

  jHashList := coalesce(GetObjectDataJSON(uInvoice, 'hash_list')::jsonb, '[]'::jsonb);

  SELECT info->>'active_card_bindingid' INTO vBindingId FROM db.client WHERE id = uClient;

  nIndex := coalesce(array_position(aBindList, vBindingId), 1);
  vBindingId := aBindList[nIndex];

  IF jHashList ? aHashList[nIndex] THEN
    nIndex := 1;
    vBindingId := aBindList[nIndex];
    WHILE vBindingId IS NOT NULL AND jHashList ? aHashList[nIndex]
	LOOP
      nIndex := nIndex + 1;
      vBindingId := aBindList[nIndex];
	END LOOP;
  END IF;

  IF vBindingId IS NULL THEN
    PERFORM SetObjectDataJSON(uInvoice, 'params', '{"auto_payment": false}');
    PERFORM EditDocument(uInvoice, pDescription => format('Автоплатеж по данному счету отключен до %s.', Now() + interval '1 day'));
    PERFORM ExecuteObjectAction(uInvoice, GetAction('fail'));
  ELSE
	profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile');
	profile := coalesce(profile, 'main');

	subject := 'paymentOrderBinding.do';
	address := '/payment/rest/paymentOrderBinding.do';

	content := format('mdOrder=%s', uOrderId::text);
	content := content || format('&bindingId=%s', vBindingId);

	--uMessage := SendMessage(pObject, GetAgent('sba.agent'), profile, address, subject, content);

	jHashList := jHashList || jsonb_build_array(aHashList[nIndex]);
	PERFORM SetObjectDataJSON(uInvoice, 'hash_list', jHashList::json);

	PERFORM AddMethodStack(jsonb_build_object('profile', profile, 'address', address, 'content', content, 'message', uMessage));
  END IF;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDelete ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Ордер удалён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderRestore -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Ордер восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDrop --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r		record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.order WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Ордер уничтожен.');
END;
$$ LANGUAGE plpgsql;
