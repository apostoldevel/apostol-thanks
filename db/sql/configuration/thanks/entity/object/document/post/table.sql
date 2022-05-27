--------------------------------------------------------------------------------
-- POST ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.post ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.post (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid REFERENCES db.client(id),
    code            text NOT NULL,
    lock			timestamptz
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.post IS 'Публикация.';

COMMENT ON COLUMN db.post.id IS 'Идентификатор.';
COMMENT ON COLUMN db.post.document IS 'Документ.';
COMMENT ON COLUMN db.post.client IS 'Клиент.';
COMMENT ON COLUMN db.post.code IS 'Код.';
COMMENT ON COLUMN db.post.lock IS 'Дата и признак блокировки изменений содержимого.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.post (code);

CREATE INDEX ON db.post (document);
CREATE INDEX ON db.post (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_post_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(12), 'hex');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_post_before_insert
  BEFORE INSERT ON db.post
  FOR EACH ROW
  EXECUTE PROCEDURE ft_post_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_post_after_insert()
RETURNS trigger AS $$
BEGIN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_post_after_insert
  AFTER INSERT ON db.post
  FOR EACH ROW
  EXECUTE PROCEDURE ft_post_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_post_after_update()
RETURNS trigger AS $$
BEGIN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_post_after_update
  AFTER UPDATE ON db.post
  FOR EACH ROW
  EXECUTE PROCEDURE ft_post_after_update();

--------------------------------------------------------------------------------
-- POST CONTENT ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.post_content -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.post_content (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    post		    uuid NOT NULL REFERENCES db.post(id) ON DELETE CASCADE,
    locale		    uuid NOT NULL REFERENCES db.locale(id) ON DELETE RESTRICT,
    revision        int NOT NULL,
    version         text,
    hash			text,
    content         text,
    rendered        text,
    raw         	text,
    validFromDate	timestamptz DEFAULT Now() NOT NULL,
    validToDate		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.post_content IS 'Содержимое публикации.';

COMMENT ON COLUMN db.post_content.id IS 'Идентификатор';
COMMENT ON COLUMN db.post_content.post IS 'Идентификатор публикации';
COMMENT ON COLUMN db.post_content.locale IS 'Идентификатор локали';
COMMENT ON COLUMN db.post_content.revision IS 'Пересмотр.';
COMMENT ON COLUMN db.post_content.version IS 'Версия.';
COMMENT ON COLUMN db.post_content.hash IS 'Хеш.';
COMMENT ON COLUMN db.post_content.content IS 'Содержимое.';
COMMENT ON COLUMN db.post_content.rendered IS 'Обработанные данные.';
COMMENT ON COLUMN db.post_content.raw IS 'Необработанные данные.';
COMMENT ON COLUMN db.post_content.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.post_content.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE INDEX ON db.post_content (post);
CREATE INDEX ON db.post_content (locale);
CREATE INDEX ON db.post_content (hash);

CREATE UNIQUE INDEX ON db.post_content (post, locale, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_post_content_before()
RETURNS trigger AS $$
BEGIN
  IF NEW.locale IS NULL THEN
    NEW.locale := current_locale();
  END IF;

  NEW.hash := encode(digest(NEW.content, 'md5'), 'hex');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_post_content_before
  BEFORE INSERT OR UPDATE ON db.post_content
  FOR EACH ROW
  EXECUTE PROCEDURE ft_post_content_before();
