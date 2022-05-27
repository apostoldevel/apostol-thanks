--------------------------------------------------------------------------------
-- CreateTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт тариф
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {uuid} pService - Услуга
 * @param {numeric} pPrice - Цена
 * @param {numeric} pCommission - Комиссия
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION CreateTariff (
  pParent           uuid,
  pType             uuid,
  pCode             text,
  pName             text,
  pService          uuid,
  pPrice            numeric,
  pCommission       numeric default null,
  pDescription	    text default null
) RETURNS           uuid
AS $$
DECLARE
  uReference        uuid;
  uClass            uuid;
  uMethod           uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'tariff' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.tariff (id, reference, service, price, commission)
  VALUES (uReference, uReference, pService, pPrice, pCommission);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTariff ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует тариф
 * @param {uuid} pId - Идентификатор
 * @param {uuid} pParent - Идентификатор объекта родителя
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - Код
 * @param {text} pName - Наименование
 * @param {uuid} pService - Услуга
 * @param {uuid} pNetwork - Электросеть
 * @param {uuid} pMode - Режим зарядки
 * @param {numeric} pPrice - Цена
 * @param {numeric} pCommission - Комиссия
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditTariff (
  pId               uuid,
  pParent           uuid default null,
  pType             uuid default null,
  pCode             text default null,
  pName             text default null,
  pService          uuid default null,
  pPrice            numeric default null,
  pCommission       numeric default null,
  pDescription	    text default null
) RETURNS           void
AS $$
DECLARE
  uClass            uuid;
  uMethod           uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription);

  UPDATE db.tariff
     SET service = coalesce(pService, service),
         price = coalesce(pPrice, price),
         commission = CheckNull(coalesce(pCommission, commission, -1))
   WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariff ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTariff (
  pCode		text
) RETURNS 	uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'tariff');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariffPrice -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTariffPrice (
  pId       uuid
) RETURNS 	numeric
AS $$
  SELECT price FROM db.tariff WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetPrice -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetPrice (
  pService  uuid
) RETURNS 	numeric
AS $$
  SELECT price
    FROM db.tariff
   WHERE service = pService
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetServicePrice ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetServicePrice (
  pService  uuid
) RETURNS 	numeric
AS $$
  SELECT t.price / s.value
    FROM db.tariff t INNER JOIN db.service s ON t.service = s.id
   WHERE t.service = pService
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
