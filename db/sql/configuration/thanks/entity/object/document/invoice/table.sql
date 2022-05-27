--------------------------------------------------------------------------------
-- INVOICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.invoice ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.invoice (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid NOT NULL REFERENCES db.client(id),
    code		    text NOT NULL,
    amount		    numeric(12,2) NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.invoice IS 'Счёт.';

COMMENT ON COLUMN db.invoice.id IS 'Идентификатор';
COMMENT ON COLUMN db.invoice.document IS 'Документ';
COMMENT ON COLUMN db.invoice.client IS 'Клиент';
COMMENT ON COLUMN db.invoice.code IS 'Код';
COMMENT ON COLUMN db.invoice.amount IS 'Сумма';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.invoice (code);

CREATE INDEX ON db.invoice (document);
CREATE INDEX ON db.invoice (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_invoice_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(8), 'hex');
  END IF;

  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.aou SET allow = allow | B'110' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'110';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_invoice_insert
  BEFORE INSERT ON db.invoice
  FOR EACH ROW
  EXECUTE PROCEDURE ft_invoice_insert();
