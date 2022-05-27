--------------------------------------------------------------------------------
-- db.target -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.target (
    id			    uuid PRIMARY KEY,
    document	    uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    post		    uuid NOT NULL REFERENCES db.post(id) ON DELETE RESTRICT,
    code		    text NOT NULL,
    content         text,
    data            text,
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.target IS 'Цель.';

COMMENT ON COLUMN db.target.id IS 'Идентификатор';
COMMENT ON COLUMN db.target.document IS 'Ссылка на документ';
COMMENT ON COLUMN db.target.code IS 'Код';
COMMENT ON COLUMN db.target.post IS 'Пост';
COMMENT ON COLUMN db.target.content IS 'Содержимое.';
COMMENT ON COLUMN db.target.data IS 'Данные.';
COMMENT ON COLUMN db.target.validFromDate IS 'Дата начала действия';
COMMENT ON COLUMN db.target.validToDate IS 'Дата окончания действия';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.target (code);
CREATE UNIQUE INDEX ON db.target (post, validFromDate, validToDate);

CREATE INDEX ON db.target (document);
CREATE INDEX ON db.target (post);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_target_before_insert()
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

CREATE TRIGGER t_target_before_insert
  BEFORE INSERT ON db.target
  FOR EACH ROW
  EXECUTE PROCEDURE ft_target_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_target_after_insert()
RETURNS trigger AS $$
BEGIN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_target_after_insert
  AFTER INSERT ON db.target
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_target_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_target_after_update_post()
RETURNS trigger AS $$
BEGIN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_target_after_update_post
  AFTER UPDATE ON db.target
  FOR EACH ROW
  WHEN (OLD.post IS DISTINCT FROM NEW.post)
  EXECUTE PROCEDURE ft_target_after_update_post();
