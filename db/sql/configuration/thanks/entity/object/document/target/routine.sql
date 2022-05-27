--------------------------------------------------------------------------------
-- CreateTarget ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт цель
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pPost - Публикация
 * @param {text} pCode - Код
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION CreateTarget (
  pParent       uuid,
  pType         uuid,
  pPost         uuid,
  pCode         text,
  pContent      text default null,
  pData         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;
  nTarget       uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'target' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.target WHERE code = pCode;

  IF found THEN
    PERFORM TargetCodeExists(pCode);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.target (id, document, post, code, content, data)
  VALUES (uDocument, uDocument, pPost, pCode, pContent, pData)
  RETURNING id INTO nTarget;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(nTarget, uMethod);

  RETURN nTarget;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTarget ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует цель.
 * @param {uuid} pId - Идентификатор клиента
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pPost - Публикация
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditTarget (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pPost         uuid default null,
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
  SELECT code INTO cCode FROM db.target WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    SELECT id INTO uId FROM db.target WHERE code = pCode;
    IF found THEN
      PERFORM TargetCodeExists(pCode);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.target
     SET post = coalesce(pPost, post),
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
-- GetTarget -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTarget (
  pCode		text
) RETURNS	uuid
AS $$
  SELECT id FROM db.target WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTargetCode ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTargetCode (
  pTarget   uuid
) RETURNS     text
AS $$
  SELECT code FROM db.target WHERE id = pTarget;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetTargetPost ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTargetPost (
  pTarget   uuid
) RETURNS   uuid
AS $$
  SELECT post FROM db.target WHERE id = pTarget;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
