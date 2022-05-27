--------------------------------------------------------------------------------
-- MESSAGE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ParseInboxSBA ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ParseInboxSBA (
  pMessage      uuid
) RETURNS       boolean
AS $$
DECLARE
  r             record;
  m             db.message%rowtype;

  params        text[];

  uParent       uuid;
  uClient		uuid;
  uAccount		uuid;
  uInvoice		uuid;
  uMessageId	uuid;
  uOrder        uuid;
  uCard         uuid;

  clientId		uuid;
  orderId       uuid;
  mdOrder		uuid;

  orderNumber   text;
  maskedPan     text;
  bindingId     text;

  actionCode	integer;

  nAmount       numeric;

  profile		text;
  description	text;

  reply         jsonb;
  bindingInfo   jsonb;

  vContent      text;
  vMessage      text;
  vContext      text;
  vStateCode    text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  SELECT * INTO m FROM db.message WHERE id = pMessage;

  uParent := GetObjectParent(m.id);
  IF uParent IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Parent cannot be null.';
  END IF;

  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile');
  profile := coalesce(profile, 'main');

  SELECT content INTO vContent FROM db.message WHERE id = uParent;

  params := string_to_array(vContent, '&');

  reply := m.content::jsonb;

  IF m.address = '/payment/rest/register.do' THEN

    orderNumber := find_value_in_array(params, 'orderNumber');
    IF orderNumber IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: Order number cannot be null.';
    END IF;

    IF reply ? 'errorCode' THEN
      errorCode := StrToInt(reply->>'errorCode');
    ELSE
      errorCode := 0;
    END IF;

    IF errorCode = 0 THEN
      orderId := reply->>'orderId';

      uOrder := GetOrder(orderNumber);
      IF uOrder IS NULL THEN
        RAISE EXCEPTION 'ERR-40000: Not found order by code: %', orderNumber;
      END IF;

      PERFORM EditOrder(uOrder, pOrderId => orderId);
      PERFORM DoDisable(uOrder);
    END IF;

  ELSIF m.address = '/payment/rest/registerPreAuth.do' THEN

    orderNumber := find_value_in_array(params, 'orderNumber');
    IF orderNumber IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: Order number cannot be null.';
    END IF;

    IF reply ? 'errorCode' THEN
      errorCode := StrToInt(reply->>'errorCode');
    ELSE
      errorCode := 0;
    END IF;

    IF errorCode = 0 THEN
      orderId := reply->>'orderId';

      uOrder := GetOrder(orderNumber);
      IF uOrder IS NULL THEN
        RAISE EXCEPTION 'ERR-40000: Not found order by code: %', orderNumber;
      END IF;

      PERFORM EditOrder(uOrder, pOrderId => orderId);
      PERFORM DoDisable(uOrder);
    END IF;

  ELSIF m.address = '/payment/rest/getBindings.do' THEN

	clientId := find_value_in_array(params, 'clientId');
	IF clientId IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: Client ID cannot be null.';
	END IF;

    PERFORM SetObjectDataJSON(clientId, 'bindings', (reply->'bindings')::json);

  ELSIF m.address = '/payment/rest/createBindingNoPayment.do' THEN

    IF reply ? 'errorCode' THEN
      errorCode := StrToInt(reply->>'errorCode');
    ELSE
      errorCode := -1;
    END IF;

    IF reply ? 'errorMessage' THEN
      errorMessage := reply->>'errorMessage';
    END IF;

	IF reply ? 'clientId' THEN
	  clientId := reply->>'clientId';
	ELSE
	  clientId := find_value_in_array(params, 'clientId');
	END IF;

	IF reply ? 'maskedPan' THEN
	  maskedPan := reply->>'maskedPan';
	ELSE
	  maskedPan := '<null>';
	END IF;

	SELECT id INTO uCard FROM db.card WHERE client = clientId AND code = maskedPan;

	IF NOT FOUND THEN
	  RAISE EXCEPTION 'No card found for the client "%" by masked code: %', clientId, maskedPan;
	END IF;

    PERFORM EditDocument(uCard, pDescription => coalesce(errorMessage, '<null>'));

    IF errorCode = 0 THEN

-- 	  IF clientId IS NOT NULL THEN
-- 		PERFORM SendMessage(pMessage, GetAgent('sba.agent'), profile, '/payment/rest/getBindings.do', 'getBindings.do', format('clientId=%s', clientId));
-- 	  END IF;

	  IF reply ? 'bindingId' THEN
        bindingId := reply->>'bindingId';

		orderNumber := encode(gen_random_bytes(12), 'hex');
		uOrder := CreateOrder(uCard, GetType('validation.order'), orderNumber, clientId, null, 1, null, 'Card validation.');

		PERFORM SetObjectData(uOrder, 'text', 'hidden', GetObjectData(uCard, 'text', 'hidden'));
		PERFORM SetObjectData(uCard, 'text', 'hidden', null);

		PERFORM EditCard(uCard, pBinding => bindingId);

	    PERFORM SetObjectData(uOrder, 'text', 'bindingId', bindingId);
        PERFORM DoEnable(uOrder);
	  END IF;

	ELSE

	  IF IsActive(uCard) THEN
        PERFORM DoDisable(uCard);
      END IF;

	END IF;

  ELSIF m.address = '/payment/rest/unBindCard.do' THEN

	bindingId := find_value_in_array(params, 'bindingId');
	IF bindingId IS NOT NULL THEN
	  SELECT id INTO uCard FROM db.card WHERE binding = bindingId;
	  IF FOUND THEN
        IF IsActive(uCard) THEN
		  PERFORM DoDisable(uCard); -- disabled card
		END IF;
	  END IF;

-- 	  FOR r IN SELECT object FROM db.object_data WHERE type = 'json' AND code = 'bindings' AND data::jsonb @> jsonb_build_array(jsonb_build_object('bindingId', bindingId))
-- 	  LOOP
--      PERFORM SendMessage(pMessage, GetAgent('sba.agent'), profile, '/payment/rest/getBindings.do', 'getBindings.do', format('clientId=%s', r.object));
--    END LOOP;
	END IF;

  ELSIF m.address = '/payment/rest/paymentOrderBinding.do' THEN

    IF reply ? 'errorCode' THEN
      errorCode := StrToInt(reply->>'errorCode');
    ELSE
      errorCode := -1;
    END IF;

    IF errorCode = 0 THEN
	  mdOrder := find_value_in_array(params, 'mdOrder');
	  IF mdOrder IS NULL THEN
		RAISE EXCEPTION 'ERR-40000: Value "mdOrder" cannot be null.';
	  END IF;

--	  uMessageId := SendMessage(pMessage, GetAgent('sba.agent'), profile, '/payment/rest/getOrderStatusExtended.do', 'getOrderStatusExtended.do', format('orderId=%s', mdOrder));
	END IF;

  ELSIF m.address = '/payment/rest/getOrderStatusExtended.do' THEN

	mdOrder := find_value_in_array(params, 'orderId');
	IF mdOrder IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: Order Id cannot be null.';
	END IF;

    actionCode := StrToInt(reply->>'actionCode');

    errorMessage := nullif(reply->>'errorMessage', '');
    description := nullif(reply->>'actionCodeDescription', '');

	SELECT id, invoice INTO uOrder, uInvoice FROM db.order o WHERE o.orderid = mdOrder;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'ERR-40000: Not found order by number: %', mdOrder;
    END IF;

	PERFORM EditDocument(uOrder, pLabel => coalesce(errorMessage, '<null>'), pDescription => coalesce(description, '<null>'));

	uCard := GetObjectParent(uOrder);
	IF uCard IS NOT NULL THEN
	  PERFORM EditDocument(uCard, pLabel => coalesce(errorMessage, '<null>'), pDescription => coalesce(description, '<null>'));
	END IF;

	IF uInvoice IS NOT NULL THEN

	  IF coalesce(actionCode, -1) = 0 THEN
		SELECT statecode INTO vStateCode FROM Object WHERE id = uInvoice;
		IF vStateCode = 'in_progress' THEN
		  PERFORM DoDisable(uInvoice);
--		  PERFORM SendCloudPayment(uInvoice);
		END IF;
	  ELSE
		IF IsActive(uInvoice) THEN
		  PERFORM ExecuteObjectAction(uInvoice, GetAction('cancel'));
		END IF;
	  END IF;

	  PERFORM EditDocument(uInvoice, pLabel => coalesce(description, errorMessage, '<null>'));

	ELSE

	  IF coalesce(actionCode, -1) = 0 THEN
		IF IsDisabled(uOrder) THEN
		  PERFORM ExecuteObjectAction(uOrder, GetAction('cancel'));
		END IF;

		IF NOT IsEnabled(uCard) AND NOT IsDeleted(uCard) THEN
		  PERFORM DoEnable(uCard); -- enabled card
		END IF;
	  ELSE
	    IF reply ? 'bindingInfo' THEN
		  bindingInfo = reply->'bindingInfo';
		  IF bindingInfo ? 'bindingId' THEN
			bindingId := bindingInfo->>'bindingId';
-- 			IF bindingId IS NOT NULL THEN
-- 			  PERFORM SendMessage(pMessage, GetAgent('sba.agent'), profile, '/payment/rest/unBindCard.do', 'unBindCard.do', format('bindingId=%s', bindingId));
-- 			END IF;
		  END IF;
		END IF;
	  END IF;

	END IF;

	PERFORM EditDocument(pMessage, pLabel => coalesce(errorMessage, '<null>'), pDescription => coalesce(description, '<null>'));

  ELSIF m.address = '/payment/rest/refund.do' THEN

    IF reply ? 'errorCode' THEN
      errorCode := StrToInt(reply->>'errorCode');
    ELSE
      errorCode := -1;
    END IF;

    IF errorCode = 0 THEN
	  mdOrder := find_value_in_array(params, 'orderId');
	  IF mdOrder IS NULL THEN
		RAISE EXCEPTION 'ERR-40000: Value "orderId" cannot be null.';
	  END IF;

	  SELECT id, client, invoice, amount INTO uOrder, uClient, uInvoice, nAmount FROM db.order o WHERE o.orderid = mdOrder;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'ERR-40000: Not found order by number: %', mdOrder;
      END IF;

      uAccount := GetAccount(encode(digest(uClient::text, 'sha1'), 'hex'), GetCurrency('RUB'));

      PERFORM UpdateBalance(uAccount, nAmount);

	  IF IsDisabled(uInvoice) THEN
		PERFORM DoDelete(uInvoice);
	  END IF;
	END IF;

  ELSE

    RETURN false;

  END IF;

  RETURN true;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  PERFORM SetObjectLabel(pMessage, errorMessage, null);

  RETURN false;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- ParseInboxCloudKassir -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ParseInboxCloudKassir (
  pMessage      uuid
) RETURNS       boolean
AS $$
DECLARE
  m             db.message%rowtype;

  uParent       uuid;
  uInvoiceId	uuid;

  Model			json;

  request		json;
  reply         json;

  vContent      text;
  vMessage      text;
  vContext      text;

  errorCode     integer;
  errorMessage  text;
BEGIN
  SELECT * INTO m FROM db.message WHERE id = pMessage;

  uParent := GetObjectParent(m.id);
  IF uParent IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: Parent cannot be null.';
  END IF;

  SELECT content INTO vContent FROM db.message WHERE id = uParent;

  request := vContent::json;
  reply := m.content::json;

  IF lower(m.address) = '/kkt/receipt' THEN
    IF (reply->>'Success')::bool THEN
	  uInvoiceId := request->>'InvoiceId';
	  Model := reply->'Model';

	  --PERFORM SetObjectData(uInvoiceId, 'text', 'kkt', format('https://receipts.ru/%s', Model->>'Id'));
    END IF;
  END IF;

  RETURN true;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO errorCode, errorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', errorCode, errorMessage);
  PERFORM WriteToEventLog('D', errorCode, vContext);

  PERFORM SetObjectLabel(pMessage, errorMessage, null);

  RETURN false;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInboxCreate ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInboxCreate (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  vAgentCode	text;
  bSuccess		boolean;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Входящее сообщение создано.', pObject);

  SELECT agentcode INTO vAgentCode FROM Message WHERE id = pObject;

  bSuccess := false;

  IF vAgentCode = 'sba.agent' THEN
	bSuccess := ParseInboxSBA(pObject);
  ELSIF vAgentCode = 'cloudkassir.agent' THEN
	bSuccess := ParseInboxCloudKassir(pObject);
  ELSE
	bSuccess := true;
  END IF;

  IF bSuccess THEN
	PERFORM DoDisable(pObject);
	PERFORM WriteToEventLog('M', 1001, vAgentCode, 'Входящее сообщение обработано.', pObject);
  ELSE
	PERFORM WriteToEventLog('W', 1001, vAgentCode, 'Входящее сообщение не обработано.', pObject);
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventMessageFail ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventMessageFail (
  pObject	    uuid default context_object()
) RETURNS	    void
AS $$
DECLARE
  uAgent        uuid;
  uDevice       uuid;

  jContent      jsonb;
  jMessage      jsonb;

  sToken        text;

  vMessage      text;
  vContext      text;
BEGIN
  SELECT agent INTO uAgent FROM db.message WHERE id = pObject;

  IF uAgent = GetAgent('fcm.agent') THEN
    SELECT content INTO jContent FROM db.message WHERE id = pObject;

    jMessage := jContent->'message';
    sToken := jMessage->>'token';

    SELECT id INTO uDevice FROM db.device WHERE address = sToken;

    IF FOUND AND IsEnabled(uDevice) THEN
      IF StrPos(GetObjectLabel(pObject), 'NOT_FOUND') != 0 THEN
        PERFORM DoDisable(uDevice);
        PERFORM WriteToEventLog('W', 2000, 'Token', 'Недействительный токен отключен.', uDevice);
      END IF;
    END IF;
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'Fail', 'Сбой при отправке сообщения.', pObject);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventMessageConfirmEmail ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventMessageConfirmEmail (
  pObject		uuid default context_object(),
  pParams		jsonb default context_params()
) RETURNS		void
AS $$
DECLARE
  uUserId       uuid;
  vCode			text;
  vName			text;
  vDomain       text;
  vUserName     text;
  vEmail		text;
  vProject		text;
  vHost         text;
  vNoReply      text;
  vSupport		text;
  vSubject      text;
  vText			text;
  vHTML			text;
  vBody			text;
  vDescription  text;
  bVerified		bool;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;
  IF uUserId IS NOT NULL THEN

    IF pParams IS NOT NULL THEN
	  UPDATE db.client SET email = pParams WHERE id = uUserId;
	END IF;

	SELECT username, name, email, email_verified, locale INTO vUserName, vName, vEmail, bVerified
	  FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
	 WHERE id = uUserId;

	IF vEmail IS NOT NULL AND NOT bVerified THEN
	  vProject := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name', uUserId);
	  vHost := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', uUserId);
	  vDomain := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain', uUserId);

	  vCode := GetVerificationCode(NewVerificationCode(uUserId));

	  vNoReply := format('noreply@%s', vDomain);
	  vSupport := format('support@%s', vDomain);

	  IF locale_code() = 'ru' THEN
        vSubject := 'Подтвердите, пожалуйста, адрес Вашей электронной почты.';
        vDescription := 'Подтверждение email: ' || vEmail;
	  ELSE
        vSubject := 'Please confirm your email address.';
        vDescription := 'Confirm email: ' || vEmail;
	  END IF;

	  vText := GetConfirmEmailText(vName, vUserName, vCode, vProject, vHost, vSupport);
	  vHTML := GetConfirmEmailHTML(vName, vUserName, vCode, vProject, vHost, vSupport);

	  vBody := CreateMailBody(vProject, vNoReply, null, vEmail, vSubject, vText, vHTML);

      PERFORM SendMail(pObject, vNoReply, vEmail, vSubject, vBody, vDescription);
      PERFORM WriteToEventLog('M', 1001, 'email', vDescription, pObject);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventMessageAccountInfo -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventMessageAccountInfo (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  uUserId       uuid;
  vSecret       text;
  vName			text;
  vDomain       text;
  vUserName     text;
  vEmail		text;
  vProject		text;
  vHost         text;
  vNoReply      text;
  vSupport		text;
  vSubject      text;
  vText			text;
  vHTML			text;
  vBody			text;
  vDescription  text;
  bVerified		bool;
BEGIN
  SELECT userid INTO uUserId FROM db.client WHERE id = pObject;
  IF uUserId IS NOT NULL THEN

	SELECT username, name, encode(hmac(secret::text, GetSecretKey(), 'sha512'), 'hex'), email, email_verified INTO vUserName, vName, vSecret, vEmail, bVerified
	  FROM db.user u INNER JOIN db.profile p ON u.id = p.userid AND u.type = 'U'
	 WHERE id = uUserId;

	IF vEmail IS NOT NULL AND bVerified THEN
	  vProject := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name', uUserId);
	  vHost := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', uUserId);
	  vDomain := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain', uUserId);

	  vNoReply := format('noreply@%s', vDomain);
	  vSupport := format('support@%s', vDomain);

	  IF locale_code() = 'ru' THEN
        vSubject := 'Информация о Вашей учетной записи.';
        vDescription := 'Информация об учетной записи: ' || vUserName;
	  ELSE
        vSubject := 'Your account information.';
        vDescription := 'Account information: ' || vUserName;
	  END IF;

	  vText := GetAccountInfoText(vName, vUserName, vSecret, vProject, vSupport);
	  vHTML := GetAccountInfoHTML(vName, vUserName, vSecret, vProject, vSupport);

	  vBody := CreateMailBody(vProject, vNoReply, null, vEmail, vSubject, vText, vHTML);

      PERFORM SendMail(pObject, vNoReply, vEmail, vSubject, vBody, vDescription);
      PERFORM WriteToEventLog('M', 1001, 'email', vDescription, pObject);
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;
