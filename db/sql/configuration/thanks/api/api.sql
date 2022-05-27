--------------------------------------------------------------------------------
-- API -------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.signup ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Регистрация.
 * @param {text} pType - Tип клиента
 * @param {text} pUserName - Имя пользователя (login)
 * @param {text} pPassword - Пароль
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {text} pPhone - Телефон
 * @param {text} pEmail - Электронный адрес
 * @param {jsonb} pProfile - Дополнительная информация учётной записи пользователя
 * @param {text} pDescription - Информация о клиенте
 * @out param {uuid} id - Идентификатор клиента
 * @out param {uuid} userId - Идентификатор учетной записи
 * @out param {text} uid - Login пользователя
 * @out param {text} secret - Секретный код пользователя
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.signup (
  pType         text,
  pUserName     text,
  pPassword     text,
  pName         jsonb,
  pPhone        text DEFAULT null,
  pEmail        text DEFAULT null,
  pProfile		jsonb DEFAULT null,
  pDescription  text DEFAULT null,
  OUT id		uuid,
  OUT userId	uuid,
  OUT uid		text,
  OUT secret	text
) RETURNS       record
AS $$
DECLARE
  r				record;
  p				record;
  cn            record;

  uClient       uuid;
  uUserId       uuid;
  uArea         uuid;

  jPhone        jsonb;
  jEmail        jsonb;

  vOAuthSecret	text;
  vSecret		text;

  arKeys        text[];
BEGIN
  pType := lower(coalesce(pType, 'author'));
  pUserName := NULLIF(trim(pUserName), '');
  pPhone := NULLIF(TrimPhone(trim(pPhone)), '');
  pEmail := NULLIF(trim(pEmail), '');
  pUserName := coalesce(pUserName, pEmail, pPhone);
  pPassword := coalesce(NULLIF(pPassword, ''), GenSecretKey(9));
  pDescription := NULLIF(pDescription, '');

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND username = pUserName;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись "%" уже зарегистрирована.', pUserName;
  END IF;

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND phone = pPhone;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись с номером телефона "%" уже зарегистрирована.', pPhone;
  END IF;

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND email = pEmail;

  IF found THEN
    RAISE EXCEPTION 'ERR-40005: Учётная запись с электронным адресом "%" уже зарегистрирована.', pEmail;
  END IF;

  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('/sign/up', arKeys, pName);

  SELECT * INTO cn FROM jsonb_to_record(pName) AS x(name text, short text, first text, last text, middle text);

  IF NULLIF(cn.name, '') IS NULL THEN
    cn.name := pUserName;
  END IF;

  IF IsUserRole(GetGroup('system'), session_userid()) THEN
	SELECT a.secret INTO vOAuthSecret FROM oauth2.audience a WHERE a.code = session_username();
	IF FOUND THEN
	  PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);
	END IF;
  END IF;

  FOR r IN SELECT unnest(ARRAY['00000000-0000-4002-a001-000000000001'::uuid, '00000000-0000-4002-a001-000000000000'::uuid, '00000000-0000-4002-a000-000000000002'::uuid]) AS type
  LOOP
	SELECT a.id INTO uArea FROM db.area a WHERE a.type = r.type AND a.scope = current_scope();
	EXIT WHEN uArea IS NOT NULL;
  END LOOP;

  PERFORM SetSessionArea('00000000-0000-4003-a001-000000000001');

  uUserId := CreateUser(pUserName, pPassword, coalesce(NULLIF(trim(cn.short), ''), cn.name), pPhone, pEmail, cn.name, true, false);

  PERFORM AddMemberToGroup(uUserId, GetGroup('guest'));
  PERFORM AddMemberToArea(uUserId, GetArea('guest'));
  PERFORM AddMemberToInterface(uUserId, GetInterface('guest'));

  IF pType = 'author' THEN
    PERFORM AddMemberToGroup(uUserId, GetGroup('author'));
    PERFORM AddMemberToInterface(uUserId, GetInterface('author'));
    PERFORM SetDefaultInterface(GetInterface('author'), uUserId);
  ELSE
    PERFORM AddMemberToGroup(uUserId, GetGroup('subscriber'));
    PERFORM AddMemberToInterface(uUserId, GetInterface('subscriber'));
    PERFORM SetDefaultInterface(GetInterface('subscriber'), uUserId);
  END IF;

  IF pProfile IS NOT NULL THEN
	FOR p IN SELECT * FROM jsonb_to_record(pProfile) AS x(locale uuid, area uuid, interface uuid, email_verified bool, phone_verified bool, picture text)
	LOOP
	  IF NOT UpdateProfile(uUserId, current_scope(), cn.first, cn.last, cn.middle, p.locale, p.area, p.interface, p.email_verified, p.phone_verified, p.picture) THEN
		PERFORM CreateProfile(uUserId, current_scope(), cn.first, cn.last, cn.middle, p.locale, p.area, p.interface, p.email_verified, p.phone_verified, p.picture);
	  END IF;
	END LOOP;
  ELSE
    PERFORM SetDefaultLocale(GetLocale(locale_code()), uUserId);
  END IF;

  SELECT encode(hmac(u.secret::text, GetSecretKey(), 'sha512'), 'hex') INTO vSecret FROM db.user u WHERE u.id = uUserId;

  IF pPhone IS NOT NULL THEN
    jPhone := jsonb_build_object('mobile', pPhone);
  END IF;

  IF pEmail IS NOT NULL THEN
    jEmail := jsonb_build_array(pEmail);
  END IF;

  uClient := CreateClient(null, CodeToType(pType, 'client'), pUserName, uUserId, pName, jPhone, jEmail, null, null, null, pDescription);

  IF vOAuthSecret IS NOT NULL THEN
    PERFORM SubstituteUser(session_userid(), vOAuthSecret);
  END IF;

  id := uClient;
  userId := uUserId;
  uid := pUserName;
  secret := vSecret;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает информацию о виртуальном пользователе.
 * @field {uuid} id - Идентификатор клиента
 * @field {uuid} userid - Идентификатор виртуального пользователя (учётной записи)
 * @field {uuid} suid - Идентификатор системного пользователя (учётной записи)
 * @field {boolean} admin - Признак администратора системы
 * @field {boolean} guest - Признак гостевого входа в систему
 * @field {json} profile - Профиль пользователя
 * @field {json} name - Ф.И.О. клиента
 * @field {json} email - Справочник электронных адресов клиента
 * @field {json} phone - Телефоный справочник клиента
 * @field {json} session - Сессия
 * @field {json} locale - Язык
 * @field {json} scope - Область видимости объектов
 * @field {json} area - Область видимости документов
 * @field {json} interface - Интерфейс
 */
CREATE OR REPLACE VIEW api.whoami
AS
  SELECT c.id, s.userid, s.suid,
         IsUserRole('00000000-0000-4000-a000-000000000001', s.userid) AS admin,
         IsUserRole('00000000-0000-4000-a000-000000000003', s.userid) AS guest,
         row_to_json(u.*) AS profile,
         json_build_object('name', cn.name, 'short', cn.short, 'first', cn.first, 'last', cn.last, 'middle', cn.middle) AS name,
         c.email::json, c.phone::json, ac.code AS account, GetBalance(ac.id) AS balance, c.info, b.data::json as bindings,
         GetClientCardsJson(c.id) AS rfid_cards,
         json_build_object('code', s.code, 'created', s.created, 'updated', s.updated, 'agent', s.agent, 'host', s.host) AS session,
         row_to_json(l.*) AS locale,
         row_to_json(e.*) AS scope,
         row_to_json(a.*) AS area,
         row_to_json(i.*) AS interface
    FROM db.session s INNER JOIN users u ON u.id = s.userid AND u.scope = current_scope(s.code)
                      INNER JOIN db.locale l ON l.id = s.locale
                      INNER JOIN db.area a ON a.id = s.area
                      INNER JOIN db.scope e ON e.id = a.scope
                      INNER JOIN db.interface i ON i.id = s.interface
                       LEFT JOIN db.client c ON c.userid = s.userid
                       LEFT JOIN db.client_name cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validfromdate <= oper_date() AND cn.validtodate > oper_date()
                       LEFT JOIN db.account ac ON ac.currency = GetCurrency('RUB') AND ac.code = encode(digest(c.id::text, 'sha1'), 'hex')
                       LEFT JOIN db.object_data b ON b.object = c.id AND b.type = 'json' AND b.code = 'bindings'
   WHERE s.code = current_session();

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS SETOF api.whoami
AS $$
  SELECT * FROM api.whoami
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.search_en ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.search_en (
  pText		text
) RETURNS	SETOF api.object
AS $$
  WITH access AS (
    SELECT object FROM aou(current_userid())
  ), search AS (
  SELECT o.object
    FROM db.object_text o INNER JOIN access a ON o.object = a.object
   WHERE o.locale = '00000000-0000-4001-a000-000000000001'
     AND (o.label ILIKE '%' || pText || '%'
      OR o.text ILIKE '%' || pText || '%'
      OR o.searchable_en @@ websearch_to_tsquery('english', pText))
   UNION
  SELECT r.object
    FROM db.reference r INNER JOIN access a ON r.object = a.object
   WHERE r.code LIKE '%' || pText || '%'
  ) SELECT o.* FROM api.object o INNER JOIN search s ON o.id = s.object;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.search_ru (
  pText		text
) RETURNS	SETOF api.object
AS $$
  WITH access AS (
    SELECT object FROM aou(current_userid())
  ), search AS (
  SELECT o.object
    FROM db.object_text o INNER JOIN access a ON o.object = a.object
   WHERE o.locale = '00000000-0000-4001-a000-000000000002'
     AND (o.label ILIKE '%' || pText || '%'
      OR o.text ILIKE '%' || pText || '%'
      OR o.searchable_ru @@ websearch_to_tsquery('russian', pText))
   UNION
  SELECT r.object
    FROM db.reference r INNER JOIN access a ON r.object = a.object
   WHERE r.code LIKE '%' || pText || '%'
  ) SELECT o.* FROM api.object o INNER JOIN search s ON o.id = s.object;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.check_session -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.check_session (
  pOffTime  interval DEFAULT '3 month'
) RETURNS   void
AS $$
DECLARE
  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
--  PERFORM CheckSession(pOffTime);
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage);
  PERFORM WriteToEventLog('D', ErrorCode, vContext);
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
