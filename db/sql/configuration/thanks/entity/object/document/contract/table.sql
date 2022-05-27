--------------------------------------------------------------------------------
-- db.contract -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.contract (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client		    uuid REFERENCES db.client(id),
    code		    text NOT NULL,
    content         text,
    data            text,
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.contract IS 'Договор.';

COMMENT ON COLUMN db.contract.id IS 'Идентификатор';
COMMENT ON COLUMN db.contract.document IS 'Ссылка на документ';
COMMENT ON COLUMN db.contract.client IS 'Клиент';
COMMENT ON COLUMN db.contract.code IS 'Код';
COMMENT ON COLUMN db.contract.content IS 'Содержимое.';
COMMENT ON COLUMN db.contract.data IS 'Данные.';
COMMENT ON COLUMN db.contract.validFromDate IS 'Дата начала действия договора';
COMMENT ON COLUMN db.contract.validToDate IS 'Дата окончания действия договора';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.contract (code);
CREATE UNIQUE INDEX ON db.contract (client, validFromDate, validToDate);

CREATE INDEX ON db.contract (document);
CREATE INDEX ON db.contract (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_contract_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(8), 'hex');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_contract_before_insert
  BEFORE INSERT ON db.contract
  FOR EACH ROW
  EXECUTE PROCEDURE ft_contract_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_contract_after_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_contract_after_insert
  AFTER INSERT ON db.contract
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_contract_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_contract_after_update_client()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
	uUserId := GetClientUserId(NEW.client);
	IF uUserId IS NOT NULL THEN
	  UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
	  IF NOT FOUND THEN
		INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
	  END IF;
	END IF;
  END IF;

  IF OLD.client IS NOT NULL THEN
	uUserId := GetClientUserId(OLD.client);
	IF uUserId IS NOT NULL THEN
	  DELETE FROM db.aou WHERE object = OLD.document AND userid = uUserId;
	END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_contract_after_update_client
  AFTER UPDATE ON db.contract
  FOR EACH ROW
  WHEN (OLD.client IS DISTINCT FROM NEW.client)
  EXECUTE PROCEDURE ft_contract_after_update_client();
