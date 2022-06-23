--------------------------------------------------------------------------------
-- Invoice ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Invoice
AS
  SELECT i.id, i.document, i.code, i.amount,
         i.client, l.code AS ClientCode, l.fullname AS ClientName
    FROM db.invoice i INNER JOIN client l on l.id = i.client;

GRANT SELECT ON Invoice TO administrator;

--------------------------------------------------------------------------------
-- AccessInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessInvoice
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('invoice'), current_userid())
  )
  SELECT i.* FROM db.invoice i INNER JOIN access ac ON i.id = ac.object;

GRANT SELECT ON AccessInvoice TO administrator;

--------------------------------------------------------------------------------
-- ObjectInvoice ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectInvoice (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Label, Description, Amount,
  Client, ClientCode, FullName, ShortName, LastName, FirstName, MiddleName,
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
         t.code, ot.label, dt.description, t.amount,
         t.client, c.code, cn.name, cn.short, cn.last, cn.first, cn.middle,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessInvoice t INNER JOIN db.document          d ON t.document = d.id
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
                          LEFT JOIN db.client            c ON t.client = c.id
                          LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                         INNER JOIN db.state_type       st ON o.state_type = st.id
                          LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                         INNER JOIN db.state             s ON o.state = s.id
                          LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                         INNER JOIN db.user              w ON o.owner = w.id
                         INNER JOIN db.user              u ON o.oper = u.id
                         INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectInvoice TO administrator;
