--------------------------------------------------------------------------------
-- Target ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Target
AS
  SELECT t.id, t.document, t.code, t.content, t.data, t.validFromDate, t.validToDate,
         t.post, p.code AS PostCode, ot.label AS PostName
    FROM db.target t INNER JOIN db.post p ON t.post = p.id
                      LEFT JOIN db.object_text ot ON ot.object = p.id AND ot.locale = current_locale();

GRANT SELECT ON Target TO administrator;

--------------------------------------------------------------------------------
-- AccessTarget ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessTarget
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('target'), current_userid())
  )
  SELECT t.* FROM db.target t INNER JOIN access ac ON t.id = ac.object;

GRANT SELECT ON AccessTarget TO administrator;

--------------------------------------------------------------------------------
-- ObjectTarget ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTarget (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Post, PostCode, PostName,
  Code, Label, Description,
  Content, Data, ValidFromDate, ValidToDate,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
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
         t.post, p.code, pt.label,
         t.code, ot.label, dt.description,
         t.content, t.data, t.validfromdate, t.validtodate,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessTarget t INNER JOIN db.document          d ON t.document = d.id
                        INNER JOIN DocumentAreaTree     a ON d.area = a.id
                         LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()
                        INNER JOIN db.object            o ON t.document = o.id
                         LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                        INNER JOIN db.entity            e ON o.entity = e.id
                         LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()
                        INNER JOIN db.class_tree       ct ON o.class = ct.id
                         LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()
                        INNER JOIN db.type              y ON o.type = y.id
                         LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                        INNER JOIN db.post              p ON t.post = p.id
                         LEFT JOIN db.object_text      pt ON pt.object = p.id AND pt.locale = current_locale()
                        INNER JOIN db.state_type       st ON o.state_type = st.id
                         LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                        INNER JOIN db.state             s ON o.state = s.id
                         LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                        INNER JOIN db.user              w ON o.owner = w.id
                        INNER JOIN db.user              u ON o.oper = u.id
                        INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectTarget TO administrator;
