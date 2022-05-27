--------------------------------------------------------------------------------
-- db.card ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.card (
    id			uuid PRIMARY KEY,
    document	uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client		uuid REFERENCES db.client(id),
    code		text NOT NULL,
    name        text,
    expiry      date,
    binding     text,
    sequence	integer NOT NULL DEFAULT 0
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.card IS 'Пластиковая карта для зарядной станции.';

COMMENT ON COLUMN db.card.id IS 'Идентификатор';
COMMENT ON COLUMN db.card.document IS 'Ссылка на документ';
COMMENT ON COLUMN db.card.client IS 'Клиент';
COMMENT ON COLUMN db.card.code IS 'Код';
COMMENT ON COLUMN db.card.name IS 'Наименование';
COMMENT ON COLUMN db.card.expiry IS 'Дата окончания';
COMMENT ON COLUMN db.card.binding IS 'Привязка';
COMMENT ON COLUMN db.card.sequence IS 'Очерёдность';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.card (client, code);
CREATE UNIQUE INDEX ON db.card (binding);

CREATE INDEX ON db.card (document);
CREATE INDEX ON db.card (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(7), 'hex');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_before_insert
  BEFORE INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE ft_card_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_after_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.object SET owner = uUserId WHERE id = NEW.document;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_after_insert
  AFTER INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_card_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_before_update()
RETURNS trigger AS $$
DECLARE
  uParent	uuid;
  uUserId	uuid;
BEGIN
  IF OLD.client IS NULL AND NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    PERFORM CheckObjectAccess(NEW.document, B'010', uUserId);
    SELECT parent INTO uParent FROM db.object WHERE id = NEW.document;
    IF uParent IS NOT NULL THEN
      PERFORM CheckObjectAccess(uParent, B'010', uUserId);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_card_before_update
  BEFORE UPDATE ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE ft_card_before_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_after_update_client()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.client IS NOT NULL THEN
	uUserId := GetClientUserId(NEW.client);
	IF uUserId IS NOT NULL THEN
	  INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
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

CREATE TRIGGER t_card_after_update_client
  AFTER UPDATE ON db.card
  FOR EACH ROW
  WHEN (OLD.client IS DISTINCT FROM NEW.client)
  EXECUTE PROCEDURE ft_card_after_update_client();
