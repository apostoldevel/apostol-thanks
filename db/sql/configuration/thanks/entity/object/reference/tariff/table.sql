--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.tariff -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.tariff (
    id			    uuid PRIMARY KEY,
    reference		uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    service         uuid NOT NULL REFERENCES db.service(id),
    price           numeric(12,2) NOT NULL,
    commission      numeric(12,2)
);

COMMENT ON TABLE db.tariff IS 'Тариф.';

COMMENT ON COLUMN db.tariff.id IS 'Идентификатор.';
COMMENT ON COLUMN db.tariff.reference IS 'Справочник.';
COMMENT ON COLUMN db.tariff.service IS 'Услуга.';
COMMENT ON COLUMN db.tariff.price IS 'Цена.';
COMMENT ON COLUMN db.tariff.commission IS 'Комиссия.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.tariff (reference);
CREATE INDEX ON db.tariff (service);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_tariff_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.reference INTO NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_tariff_insert
  BEFORE INSERT ON db.tariff
  FOR EACH ROW
  EXECUTE PROCEDURE ft_tariff_insert();
