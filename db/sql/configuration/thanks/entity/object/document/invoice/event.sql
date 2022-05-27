--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventInvoiceCreate ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Счёт на оплату создан.', pObject);
  BEGIN
    PERFORM DoEnable(pObject);
  END;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceOpen ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Счёт на оплату открыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceEdit ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Счёт на оплату изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceSave ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Счёт на оплату сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceEnable ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceEnable (
  pObject		uuid default context_object(),
  pParams		jsonb default context_params()
) RETURNS		void
AS $$
DECLARE
  uClient		uuid;
  uOrder		uuid;

  nAmount		numeric;

  clear_hash	boolean DEFAULT true;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Счёт передан на оплату.', pObject);

  SELECT client, amount INTO uClient, nAmount FROM db.invoice WHERE id = pObject;

  IF pParams IS NOT NULL THEN
    clear_hash := coalesce((pParams->'clear_hash')::bool, clear_hash);
  END IF;

  PERFORM SetObjectDataJSON(pObject, 'params', '{"auto_payment": true}');

  IF clear_hash THEN
	PERFORM SetObjectDataJSON(pObject, 'hash_list', null);
  END IF;

  uOrder := CreateOrder(pObject, GetType('payment.order'), encode(gen_random_bytes(12), 'hex'), uClient, pObject, nAmount, null, GetDocumentDescription(pObject));
  PERFORM DoEnable(uOrder);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceCancel ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceCancel (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Счёт на оплату отменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceFail ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceFail (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'fail', 'Сбой при выполнении операции.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceDisable ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceDisable (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  uClient		uuid;
  uAccount		uuid;

  nAmount		numeric;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.invoice WHERE id = pObject;

  uAccount := GetAccount(encode(digest(uClient::text, 'sha1'), 'hex'), GetCurrency('RUB'));

  PERFORM UpdateBalance(uAccount, nAmount);

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Счёт на оплату оплачен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceDelete ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Счёт на оплату удалён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceRestore ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Счёт на оплату восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventInvoiceDrop ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventInvoiceDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r		record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.invoice WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Счёт на оплату уничтожен.');
END;
$$ LANGUAGE plpgsql;
