--------------------------------------------------------------------------------
-- SERVICE ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.service ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.service (
    id			    uuid PRIMARY KEY,
    reference		uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    category        uuid NOT NULL REFERENCES db.category(id),
    measure         uuid NOT NULL REFERENCES db.measure(id),
    value           numeric
);

COMMENT ON TABLE db.service IS 'Услуга.';

COMMENT ON COLUMN db.service.id IS 'Идентификатор.';
COMMENT ON COLUMN db.service.reference IS 'Справочник.';
COMMENT ON COLUMN db.service.category IS 'Категория.';
COMMENT ON COLUMN db.service.measure IS 'Мера.';
COMMENT ON COLUMN db.service.value IS 'Величина.';

CREATE INDEX ON db.service (reference);
CREATE INDEX ON db.service (category);
CREATE INDEX ON db.service (measure);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_service_insert()
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

CREATE TRIGGER t_service_insert
  BEFORE INSERT ON db.service
  FOR EACH ROW
  EXECUTE PROCEDURE ft_service_insert();
