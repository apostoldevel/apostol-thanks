--------------------------------------------------------------------------------
-- TRANSACTION -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.transaction --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.transaction (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid NOT NULL REFERENCES db.client(id),
    service         uuid NOT NULL REFERENCES db.service(id),
    invoice         uuid REFERENCES db.invoice(id),
    price		    numeric(12,2) NOT NULL,
    volume          numeric NOT NULL,
    amount		    numeric(12,2) NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.transaction IS 'Транзакция.';

COMMENT ON COLUMN db.transaction.id IS 'Идентификатор';
COMMENT ON COLUMN db.transaction.document IS 'Документ';
COMMENT ON COLUMN db.transaction.client IS 'Клиент';
COMMENT ON COLUMN db.transaction.service IS 'Услуга';
COMMENT ON COLUMN db.transaction.invoice IS 'Счёт';
COMMENT ON COLUMN db.transaction.price IS 'Цена';
COMMENT ON COLUMN db.transaction.volume IS 'Объём';
COMMENT ON COLUMN db.transaction.amount IS 'Сумма';

--------------------------------------------------------------------------------

CREATE INDEX ON db.transaction (document);
CREATE INDEX ON db.transaction (client);
CREATE INDEX ON db.transaction (service);
CREATE INDEX ON db.transaction (invoice);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_transaction_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

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

CREATE TRIGGER t_transaction_insert
  BEFORE INSERT ON db.transaction
  FOR EACH ROW
  EXECUTE PROCEDURE ft_transaction_insert();
