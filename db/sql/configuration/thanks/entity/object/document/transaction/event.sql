--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventTransactionCreate ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Транзакция создана.', pObject);

  PERFORM DoEnable(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionOpen --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Транзакция открыта на просмотр.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionEdit --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionEdit (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'edit', 'Транзакция изменёна.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionSave --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Транзакция сохранёна.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionEnable ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  uClient   uuid;
  uAccount	uuid;
  nAmount   numeric;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.transaction WHERE id = pObject;

  uAccount := GetAccount(encode(digest(uClient::text, 'sha1'), 'hex'), GetCurrency('RUB'));

  PERFORM UpdateBalance(uAccount, nAmount * -1, 2);

  PERFORM WriteToEventLog('M', 1000, 'enable', 'Транзакция открыта.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDisable -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionDisable (
  pObject	    uuid default context_object()
) RETURNS	    void
AS $$
DECLARE
  uClient       uuid;
  uAccount		uuid;
  nAmount       numeric;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.transaction WHERE id = pObject;

  uAccount := GetAccount(encode(digest(uClient::text, 'sha1'), 'hex'), GetCurrency('RUB'));

  PERFORM UpdateBalance(uAccount, nAmount, 2);
  PERFORM UpdateBalance(uAccount, nAmount * -1);

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Транзакция закрыта.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDelete ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionDelete (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
DECLARE
  uClient       uuid;
  uAccount		uuid;
  nAmount       numeric;
BEGIN
  SELECT client, amount INTO uClient, nAmount FROM db.transaction WHERE id = pObject;

  uAccount := GetAccount(encode(digest(uClient::text, 'sha1'), 'hex'), GetCurrency('RUB'));

  PERFORM UpdateBalance(uAccount, nAmount);

  PERFORM WriteToEventLog('M', 1000, 'delete', 'Транзакция удалёна.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionRestore -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionRestore (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Транзакция восстановлена.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventTransactionDrop --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventTransactionDrop (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r		    record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  DELETE FROM db.transaction WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Транзакция уничтожена.');
END;
$$ LANGUAGE plpgsql;
