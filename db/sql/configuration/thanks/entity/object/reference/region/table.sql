--------------------------------------------------------------------------------
-- REGION ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.region --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.region (
    id          uuid PRIMARY KEY,
    reference   uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    country     uuid REFERENCES db.country(id) ON DELETE RESTRICT
);

COMMENT ON TABLE db.region IS 'Справочник регионов стран мира.';

COMMENT ON COLUMN db.region.id IS 'Идентификатор.';
COMMENT ON COLUMN db.region.reference IS 'Справочник.';
COMMENT ON COLUMN db.region.country IS 'Страна.';

CREATE INDEX ON db.region (reference);
CREATE INDEX ON db.region (country);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_region_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.reference INTO NEW.id;
  END IF;

  IF NEW.country IS NULL THEN
    SELECT id INTO NEW.country FROM db.country WHERE alpha2 = 'RU';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_region_insert
  BEFORE INSERT ON db.region
  FOR EACH ROW
  EXECUTE PROCEDURE ft_region_insert();
