--------------------------------------------------------------------------------
-- FUNCTION DoCheckListenerFilter ----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoCheckListenerFilter (
  pPublisher	text,
  pFilter		jsonb
) RETURNS		void
AS $$
DECLARE
  arFilter		text[];
BEGIN
  IF pPublisher = 'transaction' THEN
  	arFilter := array_cat(arFilter, ARRAY['clients', 'connectors']);
  	PERFORM CheckJsonbKeys('/listener/transaction/filter', arFilter, pFilter);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoCheckListenerParams ----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoCheckListenerParams (
  pPublisher	text,
  pParams		jsonb
) RETURNS		void
AS $$
DECLARE
  type			text;

  arParams		text[];
  arValues      text[];
BEGIN
  IF pPublisher = 'transaction' THEN
	arParams := array_cat(null, ARRAY['type']);
	PERFORM CheckJsonbKeys('/listener/transaction/params', arParams, pParams);

	type := pParams->>'type';

	arValues := array_cat(null, ARRAY['notify']);
	IF NOT type = ANY (arValues) THEN
	  PERFORM IncorrectValueInArray(coalesce(type, '<null>'), 'type', arValues);
	END IF;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoFilterListener ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoFilterListener (
  pPublisher	text,
  pSession		text,
  pIdentity		text,
  pData			jsonb
) RETURNS		boolean
AS $$
DECLARE
  r				record;
  f				record;
  d				record;

  uUserId		uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.session WHERE code = pSession;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  SELECT filter, params INTO r FROM db.listener WHERE publisher = pPublisher AND session = pSession AND identity = pIdentity;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF pData IS NULL THEN
    RETURN false;
  END IF;

  IF pPublisher = 'transaction' THEN
	SELECT * INTO f FROM jsonb_to_record(r.filter) AS x(clients jsonb, connectors jsonb);
	SELECT * INTO d FROM jsonb_to_record(pData) AS x(client uuid, connector uuid);

	RETURN coalesce(d.client = ANY (JsonbToUUIDArray(f.clients)), true)       AND
           coalesce(d.connector = ANY (JsonbToUUIDArray(f.connectors)), true) AND
  	       CheckObjectAccess(d.client, B'100', uUserId);
  END IF;

  RETURN false;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DoEventListener ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DoEventListener (
  pPublisher    text,
  pSession      varchar,
  pIdentity     text,
  pData         jsonb
) RETURNS       SETOF json
AS $$
DECLARE
  e             record;
BEGIN
  IF pPublisher = 'transaction' THEN
	FOR e IN SELECT api.current_transaction((pData->>'client')::uuid, (pData->>'connector')::uuid) AS x
	LOOP
	  RETURN NEXT e.x;
	END LOOP;
  ELSE
    RETURN NEXT pData;
  END IF;

  RETURN;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
