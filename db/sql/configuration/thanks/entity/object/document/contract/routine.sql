--------------------------------------------------------------------------------
-- CreateContract --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт договор
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION CreateContract (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pCode         text,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;
  nContract     uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'contract' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.contract WHERE code = pCode;

  IF FOUND THEN
    PERFORM ContractCodeExists(pCode);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.contract (id, document, client, code, content, data)
  VALUES (uDocument, uDocument, pClient, pCode, pContent, pData)
  RETURNING id INTO nContract;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(nContract, uMethod);

  RETURN nContract;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditContract ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует договор.
 * @param {uuid} pId - Идентификатор клиента
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pClient - Клиент
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditContract (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pClient       uuid default null,
  pCode         text default null,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uId           uuid;
  uClass        uuid;
  uMethod       uuid;

  -- current
  cCode         text;
BEGIN
  SELECT code INTO cCode FROM db.contract WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    SELECT id INTO uId FROM db.contract WHERE code = pCode;
    IF FOUND THEN
      PERFORM ContractCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.contract
     SET client = coalesce(pClient, client),
         code = pCode,
         content = CheckNull(coalesce(pContent, content, '')),
         data = CheckNull(coalesce(pData, data, ''))
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetContract -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetContract (
  pCode		text
) RETURNS	uuid
AS $$
  SELECT id FROM db.contract WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetContractCode -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetContractCode (
  pContract   uuid
) RETURNS     text
AS $$
  SELECT code FROM db.contract WHERE id = pContract;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetContractClient -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetContractClient (
  pContract   uuid
) RETURNS     uuid
AS $$
  SELECT client FROM db.contract WHERE id = pContract;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
