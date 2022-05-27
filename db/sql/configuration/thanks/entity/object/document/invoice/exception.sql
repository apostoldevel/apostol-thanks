--------------------------------------------------------------------------------
-- FUNCTION InvoiceCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InvoiceCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Счёт с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION InvoiceTransactionExists -------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InvoiceTransactionExists()
RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Заказ по этой транзакции уже создан.';
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION InvalidInvoiceAmount -----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InvalidInvoiceAmount() RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Неверная сумма заказа.';
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
