--------------------------------------------------------------------------------
-- FUNCTION PostCodeExists -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION PostCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Договор с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
