--------------------------------------------------------------------------------
-- FUNCTION CardCodeExists -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CardCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Карта с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION CardNotAssociated --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CardNotAssociated (
  pCode     text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Карта "%" не связана с клиентом.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
