--------------------------------------------------------------------------------
-- CreateService ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт услугу
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pCategory - Категория
 * @param {uuid} pMeasure - Мера
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {integer} pValue - Величина
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION CreateService (
  pParent           uuid,
  pType             uuid,
  pCategory         uuid,
  pMeasure          uuid,
  pCode             text,
  pName             text,
  pValue            integer,
  pDescription	    text DEFAULT null
) RETURNS           uuid
AS $$
DECLARE
  uReference        uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'service' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.service (id, reference, category, measure, value)
  VALUES (uReference, uReference, pCategory, pMeasure, pValue);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditService -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует услугу
 * @param {uuid} pId - Идентификатор
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pCategory - Категория
 * @param {uuid} pMeasure - Мера
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {integer} pValue - Величина
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditService (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCategory         uuid default null,
  pMeasure          uuid default null,
  pCode             text default null,
  pName             text default null,
  pValue            integer default null,
  pDescription	    text DEFAULT null
) RETURNS           void
AS $$
DECLARE
  uClass            uuid;
  uMethod           uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription);

  UPDATE db.service
     SET category = coalesce(pCategory, category),
         measure = coalesce(pMeasure, measure),
         value = coalesce(pValue, value)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetService ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetService (
  pCode		text
) RETURNS 	uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'service');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServiceValue ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetServiceValue (
  pId		uuid
) RETURNS 	numeric
AS $$
  SELECT value FROM db.service WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
