--------------------------------------------------------------------------------
-- PostContent -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW PostContent
AS
  SELECT pc.id, pc.post,
         pc.locale, l.code, l.name, l.description,
         pc.hash, pc.content, pc.rendered, pc.raw,
         pc.revision, pc.version, pc.validFromDate, pc.validToDate
    FROM db.post_content pc INNER JOIN db.locale l ON l.id = pc.locale
   WHERE pc.locale = current_locale();

GRANT SELECT ON PostContent TO administrator;

--------------------------------------------------------------------------------
-- Post ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Post (Id, Document, Code, Lock,
  Client, ClientCode, ClientName,
  ContentId, Rendered, Content, Raw,
  Hash, Revision, Version, ValidFromDate, ValidToDate
)
AS
  SELECT p.id, p.document, p.code, p.lock,
         p.client, c.code, c.fullname,
         pc.id, pc.rendered, pc.content, pc.raw,
         pc.hash, pc.revision, pc.version, pc.validFromDate, pc.validToDate
    FROM db.post p INNER JOIN Client       c ON p.client = c.id
                    LEFT JOIN PostContent pc ON pc.post = p.id AND pc.validFromDate <= Now() AND pc.validToDate > Now();

GRANT SELECT ON Post TO administrator;

--------------------------------------------------------------------------------
-- AccessPost ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessPost
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('post'), current_userid())
  )
  SELECT p.* FROM db.post p INNER JOIN access ac ON p.id = ac.object;

GRANT SELECT ON AccessPost TO administrator;

--------------------------------------------------------------------------------
-- ObjectPost ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectPost (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName,
  ContentId, Rendered, Content, Data, Raw,
  Hash, Revision, Version, ValidFromDate, ValidToDate,
  Code, Label, Description, Lock,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Priority, PriorityCode, PriorityName, PriorityDescription,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, o.parent,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         t.client, c.code, cn.name,
         mc.post, mc.rendered, mc.content, ot.text, mc.raw,
         mc.hash, mc.revision, mc.version, mc.validFromDate, mc.validToDate,
         t.code, ot.label, dt.description, t.lock,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         d.priority, p.code, pt.name, pt.description,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, w.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessPost t INNER JOIN db.document          d ON t.document = d.id
                      INNER JOIN DocumentAreaTree     a ON d.area = a.id
                       LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()
                      INNER JOIN db.priority          p ON d.priority = p.id
                       LEFT JOIN db.priority_text    pt ON pt.priority = p.id AND pt.locale = current_locale()
                      INNER JOIN db.object            o ON t.document = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                      INNER JOIN db.entity            e ON o.entity = e.id
                       LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()
                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()
                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                       LEFT JOIN db.client            c ON t.client = c.id
                       LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                       LEFT JOIN db.post_content   mc ON mc.post = t.id AND mc.locale = current_locale() AND mc.validFromDate <= oper_date() AND mc.validToDate > oper_date()
                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                      INNER JOIN db.user              w ON o.owner = w.id
                      INNER JOIN db.user              u ON o.oper = u.id
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectPost TO administrator;
