--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.order --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.order (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    code		    text NOT NULL,
    client          uuid NOT NULL REFERENCES db.client(id),
    invoice         uuid REFERENCES db.invoice(id),
    amount		    numeric(12,2) NOT NULL,
    orderId         uuid
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.order IS 'Заказ.';

COMMENT ON COLUMN db.order.id IS 'Идентификатор';
COMMENT ON COLUMN db.order.document IS 'Документ';
COMMENT ON COLUMN db.order.code IS 'Код';
COMMENT ON COLUMN db.order.client IS 'Клиент';
COMMENT ON COLUMN db.order.invoice IS 'Счёт';
COMMENT ON COLUMN db.order.amount IS 'Сумма';
COMMENT ON COLUMN db.order.orderId IS 'Номер заказа';

--------------------------------------------------------------------------------

CREATE INDEX ON db.order (document);
CREATE INDEX ON db.order (client);
CREATE INDEX ON db.order (invoice);

CREATE UNIQUE INDEX ON db.order (code);
CREATE UNIQUE INDEX ON db.order (orderId);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_order_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(12), 'hex');
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

CREATE TRIGGER t_order_insert
  BEFORE INSERT ON db.order
  FOR EACH ROW
  EXECUTE PROCEDURE ft_order_insert();
