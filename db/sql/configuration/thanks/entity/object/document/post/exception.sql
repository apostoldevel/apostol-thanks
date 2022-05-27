--------------------------------------------------------------------------------
-- FUNCTION PostExists ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION PostExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Публикация с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION PostLocked ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION PostLocked (
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Установлен запрет на изменение данных.';
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
