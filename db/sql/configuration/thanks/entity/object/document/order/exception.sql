--------------------------------------------------------------------------------
-- FUNCTION OrderCodeExists ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION OrderCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Заказ с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
