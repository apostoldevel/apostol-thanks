--------------------------------------------------------------------------------
-- CARD ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.card
AS
  SELECT * FROM ObjectCard;

GRANT SELECT ON api.card TO administrator;

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.card (
  pState	uuid
) RETURNS	SETOF api.card
AS $$
  SELECT * FROM api.card WHERE state = pState;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.card --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.card (
  pState	text
) RETURNS	SETOF api.card
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.card(GetState(GetClass('card'), pState));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет карту.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pClient - Идентификатор
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpiry - Дата окончания
 * @param {text} pBinding - Привязка
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {integer} pSequence - Очерёдность
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_card (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateCard(pParent, coalesce(pType, GetType('rfid.card')), pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_card -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные карты.
 * @param {uuid} pId - Идентификатор карты (api.get_card)
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Tип
 * @param {uuid} pClient - Идентификатор
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpiry - Дата окончания
 * @param {text} pBinding - Привязка
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {integer} pSequence - Очерёдность
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_card (
  pId           uuid,
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.card c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('card', 'id', pId);
  END IF;

  PERFORM EditCard(pId, pParent, pType, pClient,pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_card ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_card (
  pId           uuid,
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       SETOF api.card
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_card(pParent, pType, pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
  ELSE
    PERFORM api.update_card(pId, pParent, pType, pClient, pCode, pName, pExpiry, pBinding, pLabel, pDescription, pSequence);
  END IF;

  RETURN QUERY SELECT * FROM api.card WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_card ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает карту
 * @param {uuid} pId - Идентификатор
 * @return {api.card} - Клиент
 */
CREATE OR REPLACE FUNCTION api.get_card (
  pId		uuid
) RETURNS	api.card
AS $$
  SELECT * FROM api.card WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_card ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список карт.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.card} - Клиенты
 */
CREATE OR REPLACE FUNCTION api.list_card (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.card
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'card', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.bind_card ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.bind_card (
  pCode         text,
  pName         text,
  pExpiry       date default null,
  pHidden       text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       json
AS $$
DECLARE
  uUserId		uuid;
  uClient       uuid;
  uCard         uuid;
  uMessage      uuid;

  vBinding		text;

  host			text;
  profile		text;
  address		text;
  subject		text;
  content		text;
BEGIN
  SELECT id INTO uClient FROM db.client WHERE userid = current_userid();

  IF uClient IS NULL THEN
	PERFORM AccessDenied();
  END IF;

  host := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', uUserId);
  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile', uUserId);

  profile := coalesce(profile, 'main');

  address := '/payment/rest/createBindingNoPayment.do';
  subject := 'createBindingNoPayment.do';

  content := format('clientId=%s', uClient);
  content := content || format('&pan=%s', pCode);
  content := content || format('&expiryDate=%s', DateToStr(pExpiry, 'YYYYMM'));
  content := content || format('&cardholderName=%s', pName);

  IF pHidden IS NOT NULL THEN
    content := content || format('&cvc=%s', pHidden);
  END IF;

  pCode := SubStr(pCode, 1, 6) || 'XXXXXX' || SubStr(pCode, 13, 4);

  SELECT id, binding INTO uCard, vBinding FROM db.card WHERE client = uClient AND code = pCode;

  IF uCard IS NULL THEN
    uCard := api.add_card(uClient, GetType('credit.card'), uClient, pCode, pName, pExpiry, null, pLabel, pDescription);
  ELSE
    PERFORM api.update_card(uCard, uClient, GetType('credit.card'), uClient, pCode, pName, pExpiry, null, pLabel, pDescription);

    IF IsEnabled(uCard) AND vBinding IS NOT NULL THEN
      RETURN json_build_object('status', 'Accepted');
    END IF;

    IF IsDisabled(uCard) THEN
	  PERFORM DoDelete(uCard);
	END IF;

    IF IsDeleted(uCard) THEN
	  PERFORM DoRestore(uCard);
	END IF;
  END IF;

  PERFORM SetObjectData(uCard, 'text', 'hidden', pHidden);

  --uMessage := SendMessage(uCard, GetAgent('sba.agent'), profile, address, subject, content, pDescription);

  RETURN json_build_object('status', 'InProgress');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.unbind_card -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.unbind_card (
  pId           uuid,
  pCode         text
) RETURNS       json
AS $$
DECLARE
  uUserId		uuid;
  uClient       uuid;
  uCard         uuid;
  uMessage      uuid;

  subject		text;
  bindingId		text;

  host			text;
  profile		text;
  address		text;
  content		text;
BEGIN
  SELECT id INTO uClient FROM db.client WHERE userid = current_userid();

  IF uClient IS NULL THEN
	PERFORM AccessDenied();
  END IF;

  pCode := SubStr(pCode, 1, 6) || 'XXXXXX' || SubStr(pCode, 13, 4);

  IF pId IS NOT NULL THEN
    SELECT id, code, binding INTO uCard, pCode, bindingId FROM db.card WHERE id = pId;
  ELSE
    SELECT id, binding INTO uCard, bindingId FROM db.card WHERE client = uClient AND code = pCode;
  END IF;

  IF uCard IS NULL THEN
    PERFORM NotFound();
  END IF;

  IF bindingId IS NULL THEN
    RAISE EXCEPTION 'Not found binding id for card: %.', pCode;
  END IF;

  host := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', uUserId);
  profile := RegGetValueString('CURRENT_CONFIG', 'CONFIG\Sberbank\Acquiring', 'Profile', uUserId);

  profile := coalesce(profile, 'main');

  address := '/payment/rest/unBindCard.do';
  subject := 'unBindCard.do';

  content := format('bindingId=%s', bindingId);

  --uMessage := SendMessage(uCard, GetAgent('sba.agent'), profile, address, subject, content, 'Unbind card.');

  RETURN json_build_object('status', 'InProgress');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
