--------------------------------------------------------------------------------
-- CreateCard ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт новую карту
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpiry - Дата окончания
 * @param {text} pBinding - Привязка
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {integer} pSequence - Очерёдность
 * @return {uuid} - Id карты
 */
CREATE OR REPLACE FUNCTION CreateCard (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text default null,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       uuid
AS $$
DECLARE
  uCard         uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'card' THEN
    PERFORM IncorrectClassType();
  END IF;

  IF pClient IS NOT NULL THEN
	PERFORM FROM db.client WHERE id = pClient;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('client', 'id', pClient);
	END IF;

	PERFORM FROM db.card WHERE client = pClient AND code = pCode;
	IF FOUND THEN
	  PERFORM CardCodeExists(pCode);
	END IF;
  ELSE
	PERFORM FROM db.card WHERE code = pCode;
	IF FOUND THEN
	  PERFORM CardCodeExists(pCode);
	END IF;
  END IF;

  IF NULLIF(pSequence, -1) IS NULL THEN
    SELECT max(sequence) + 1 INTO pSequence FROM db.card WHERE client IS NOT DISTINCT FROM pClient;
  ELSE
    PERFORM SetCardSequence(pClient, pSequence, 1);
  END IF;
  
  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.card (id, document, client, code, name, expiry, binding, sequence)
  VALUES (uDocument, uDocument, pClient, pCode, pName, pExpiry, pBinding, coalesce(pSequence, 0))
  RETURNING id INTO uCard;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uCard, uMethod);

  RETURN uCard;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCard --------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует основные параметры клиента.
 * @param {uuid} pId - Идентификатор клиента
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpiry - Дата окончания
 * @param {text} pBinding - Привязка
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @param {integer} pSequence - Очерёдность
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditCard (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCode         text default null,
  pName         text default null,
  pExpiry       date default null,
  pBinding      text default null,
  pLabel        text default null,
  pDescription  text default null,
  pSequence     integer default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  nSequence     integer;

  -- current
  cClient       uuid;
  cCode         text;
BEGIN
  SELECT code, client, sequence INTO cCode, cClient, nSequence FROM db.card WHERE id = pId;

  pCode := coalesce(pCode, cCode);
  pClient := coalesce(pClient, cClient);
  pSequence := coalesce(pSequence, nSequence);

  IF pCode IS DISTINCT FROM cCode THEN
    PERFORM FROM db.card WHERE client = pClient AND code = pCode;
    IF FOUND THEN
      PERFORM CardCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.card
     SET code = pCode,
         name = coalesce(pName, name),
         expiry = coalesce(pExpiry, expiry),
         binding = CheckNull(coalesce(pBinding, binding, '')),
         client = CheckNull(coalesce(pClient, client, null_uuid())),
         sequence = pSequence
   WHERE id = pId;

  IF pSequence < nSequence THEN
    PERFORM SetCardSequence(pId, pSequence, 1);
  END IF;

  IF pSequence > nSequence THEN
    PERFORM SetCardSequence(pId, pSequence, -1);
  END IF;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCard ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCard (
  pCode		text
) RETURNS	uuid
AS $$
  SELECT id FROM db.card WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardCode -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCardCode (
  pCard		uuid
) RETURNS	text
AS $$
  SELECT code FROM db.card WHERE id = pCard;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardClient ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCardClient (
  pCard		uuid
) RETURNS	uuid
AS $$
  SELECT client FROM db.card WHERE id = pCard;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetClientCardsJson ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientCardsJson (
  pClient   uuid
) RETURNS   json
AS $$
DECLARE
  arResult	    json[];
  r		        record;
BEGIN
  FOR r IN SELECT * FROM Card WHERE client = pClient
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetCardSequence ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SetCardSequence (
  pId		uuid,
  pSequence	integer,
  pDelta	integer
) RETURNS 	void
AS $$
DECLARE
  uId		uuid;
  uClient   uuid;
BEGIN
  IF pDelta <> 0 THEN
    SELECT client INTO uClient FROM db.card WHERE id = pId;
    SELECT id INTO uId
      FROM db.card
     WHERE client IS NOT DISTINCT FROM uClient
       AND sequence = pSequence
       AND id <> pId;

    IF FOUND THEN
      PERFORM SetCardSequence(uId, pSequence + pDelta, pDelta);
    END IF;
  END IF;

  UPDATE db.card SET sequence = pSequence WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SortCard -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SortCard (
  pClient     uuid
) RETURNS 	void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT id, (row_number() OVER(order by sequence))::int as newsequence
      FROM db.card
     WHERE client IS NOT DISTINCT FROM pClient
  LOOP
    PERFORM SetCardSequence(r.id, r.newsequence - 1, 0);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
