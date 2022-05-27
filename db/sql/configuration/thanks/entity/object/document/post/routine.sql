--------------------------------------------------------------------------------
-- POST ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CreatePost ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreatePost (
  pParent           uuid,
  pType             uuid,
  pClient           uuid,
  pContent          text default null,
  pRendered         text default null,
  pData             text default null,
  pRaw          	text default null,
  pCode             text default null,
  pLabel            text default null,
  pDescription	    text default null,
  pPriority         uuid default null
) RETURNS           uuid
AS $$
DECLARE
  l                 record;

  uId				uuid;
  uDocument         uuid;
  uClass            uuid;
  uMethod           uuid;
  vEntityCode		text;
BEGIN
  SELECT class, entitycode INTO uClass, vEntityCode FROM Type WHERE id = pType;

  IF uClass IS null OR vEntityCode <> 'post' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uDocument FROM db.post WHERE code = pCode;

  IF FOUND THEN
    PERFORM PostExists(pCode);
  END IF;

  IF pClient IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pClient;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('пользователь', 'id', pClient);
	END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, pCode), pDescription, pData, null, pPriority);

  INSERT INTO db.post (id, document, client, code)
  VALUES (uDocument, uDocument, pClient, pCode);

  FOR l IN SELECT id FROM db.locale
  LOOP
    PERFORM AddPostContent(uDocument, pContent, pRendered, pRaw, l.id);
  END LOOP;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditPost --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditPost (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pClient           uuid default null,
  pContent          text default null,
  pRendered         text default null,
  pData             text default null,
  pRaw          	text default null,
  pCode             text default null,
  pLabel            text default null,
  pDescription	    text default null,
  pPriority         uuid default null
) RETURNS           void
AS $$
DECLARE
  uId				uuid;
  uDocument         uuid;
  vCode             text;

  dtLock			timestamptz;

  old               Post%rowtype;
  new               Post%rowtype;

  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT code, lock INTO vCode, dtLock FROM db.post WHERE id = pId;

  IF NOT IsCreated(pId) THEN
    PERFORM ChangesNotAllowed();
  END IF;

  IF vCode <> coalesce(pCode, vCode) THEN
    SELECT id INTO uDocument FROM db.post WHERE code = pCode;
    IF FOUND THEN
      PERFORM PostExists(pCode);
    END IF;
  END IF;

  IF pClient IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pClient;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('пользователь', 'id', pClient);
	END IF;
  END IF;

  IF dtLock IS NOT NULL THEN
	PERFORM PostLocked();
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pData, current_locale(), pPriority);

  SELECT * INTO old FROM Post WHERE id = pId;

  UPDATE db.post
     SET client = coalesce(pClient, client),
         code = coalesce(pCode, code)
   WHERE id = pId;

  PERFORM SetPostContent(pId, pContent, pRendered, pRaw);

  SELECT * INTO new FROM Post WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod, jsonb_build_object('old', row_to_json(old), 'new', row_to_json(new)));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetPost ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetPost (
  pCode     text
) RETURNS	uuid
AS $$
  SELECT id FROM db.post WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- POST CONTENT ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- FUNCTION AddPostContent -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет содержимое руководства.
 * @param {uuid} pPost - Идентификатор руководства
 * @param {text} pContent - Содержимое
 * @param {text} pRendered - Обработанные данные
 * @param {text} pData - Данные
 * @param {text} pRaw - Необработанные данные
 * @param {uuid} pLocale - Локаль
 * @param {timestamptz} pDateFrom - Дата изменения
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION AddPostContent (
  pPost	    uuid,
  pContent		text default null,
  pRendered		text default null,
  pRaw			text default null,
  pLocale		uuid default current_locale(),
  pDateFrom	    timestamptz default oper_date()
) RETURNS 	    uuid
AS $$
DECLARE
  uId			uuid;
  nRevision     int;
  vVersion      text;
  dtDateFrom    timestamptz;
  dtDateTo 	    timestamptz;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT id, validFromDate, validToDate INTO uId, dtDateFrom, dtDateTo
    FROM db.post_content
   WHERE post = pPost
     AND locale = pLocale
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF coalesce(dtDateFrom, MINDATE()) = pDateFrom THEN
    -- обновим значения в текущем диапозоне дат
    UPDATE db.post_content
	   SET content = pContent,
		   rendered = pRendered,
		   raw = pRaw
     WHERE post = pPost
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.post_content SET validToDate = pDateFrom
     WHERE post = pPost
       AND locale = pLocale
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

	SELECT max(revision) + 1 INTO nRevision
	  FROM db.post_content
	 WHERE post = pPost
	   AND locale = pLocale;

    nRevision := coalesce(nRevision, 1);
    vVersion := format('THNX.%s.%s', DateToStr(pDateFrom, 'YY.MM.DD'), lpad(nRevision::text, 3, '0'));

    INSERT INTO db.post_content (post, locale, content, rendered, raw, revision, version, validfromdate, validToDate)
    VALUES (pPost, pLocale, pContent, pRendered, pRaw, nRevision, vVersion, pDateFrom, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO uId;
  END IF;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION UpdatePostContent --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет содержимое руководства.
 * @param {uuid} pPost - Идентификатор руководства
 * @param {text} pContent - Содержимое
 * @param {text} pRendered - Обработанные данные
 * @param {text} pData - Данные
 * @param {text} pRaw - Необработанные данные
 * @param {uuid} pLocale - Локаль
 * @param {timestamptz} pDateFrom - Дата изменения
 * @return {boolean}
 */
CREATE OR REPLACE FUNCTION UpdatePostContent (
  pPost	    uuid,
  pContent		text default null,
  pRendered		text default null,
  pRaw			text default null,
  pLocale		uuid default current_locale(),
  pDateFrom	    timestamptz default oper_date()
) RETURNS 	    boolean
AS $$
BEGIN
  UPDATE db.post_content
	 SET content = CheckNull(coalesce(pContent, content, '')),
		 rendered = CheckNull(coalesce(pRendered, rendered, '')),
		 raw = CheckNull(coalesce(pRaw, raw, ''))
   WHERE post = pPost
	 AND locale = pLocale
	 AND validFromDate <= pDateFrom
	 AND validToDate > pDateFrom;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetPostContent -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет/обновляет содержимое руководства.
 * @param {uuid} pPost - Идентификатор руководства
 * @param {text} pContent - Содержимое
 * @param {text} pRendered - Обработанные данные
 * @param {text} pData - Данные
 * @param {text} pRaw - Необработанные данные
 * @param {uuid} pLocale - Локаль
 * @param {timestamptz} pDateFrom - Дата изменения
 * @return {void}
 */
CREATE OR REPLACE FUNCTION SetPostContent (
  pPost	        uuid,
  pContent		text default null,
  pRendered		text default null,
  pRaw			text default null,
  pLocale		uuid default current_locale(),
  pDateFrom	    timestamptz default oper_date()
) RETURNS 	    void
AS $$
BEGIN
  IF NOT UpdatePostContent(pPost, pContent, pRendered, pRaw, pLocale, pDateFrom) THEN
	PERFORM AddPostContent(pPost, pContent, pRendered, pRaw, pLocale, pDateFrom);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION CopyPostContent ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CopyPostContent (
  pSource		uuid,
  pDestination	uuid
) RETURNS 	    void
AS $$
DECLARE
  l             record;
  r             record;
BEGIN
  FOR l IN SELECT id FROM db.locale
  LOOP
	FOR r IN
	  SELECT *
		FROM db.post_content
	   WHERE post = pSource
		 AND locale = l.id
		 AND validFromDate <= oper_date()
		 AND validToDate > oper_date()
    LOOP
	  PERFORM AddPostContent(pDestination, r.content, r.rendered, r.raw, l.id);
	END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION LockPostContent ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION LockPostContent (
  pPost	    uuid,
  pDateLock timestamptz DEFAULT oper_date()
) RETURNS   void
AS $$
BEGIN
  UPDATE db.post SET lock = pDateLock WHERE id = pPost;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION UnLockPostContent --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION UnLockPostContent (
  pPost	    uuid
) RETURNS   void
AS $$
BEGIN
  UPDATE db.post SET lock = null WHERE id = pPost;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
