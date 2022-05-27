--------------------------------------------------------------------------------
-- Transaction -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Transaction
AS
  SELECT t.id, t.document,
         t.client, c.code AS ClientCode, c.fullname AS ClientName,
         t.service, s.code AS ServiceCode, s.name AS ServiceName,
         t.invoice, i.code AS InvoiceCode,
         t.price, t.volume, t.amount
    FROM db.transaction t INNER JOIN Client  c ON t.client = c.id
                          INNER JOIN Service s ON t.service = s.id
                           LEFT JOIN Invoice i ON t.invoice = i.id;

GRANT SELECT ON Transaction TO administrator;

--------------------------------------------------------------------------------
-- AccessTransaction -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessTransaction
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('transaction'), current_userid())
  )
  SELECT t.* FROM db.transaction t INNER JOIN access ac ON t.id = ac.object;

GRANT SELECT ON AccessTransaction TO administrator;

--------------------------------------------------------------------------------
-- ObjectTransaction------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTransaction(Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName,
  Service, ServiceCode, ServiceName,
  Invoice, InvoiceCode,
  Price, Volume, Amount,
  Label, Description,
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
         t.client, c.code, cn.name,
         t.service, sr.code, srt.name,
         t.invoice, i.code,
         t.price, t.volume, t.amount,
         ot.label, dt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, w.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessTransaction t INNER JOIN db.document          d ON t.document = d.id
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
                             INNER JOIN db.client            c ON t.client = c.id
                              LEFT JOIN db.client_name      cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                             INNER JOIN db.reference        sr ON t.service = sr.id
                              LEFT JOIN db.reference_text  srt ON srt.reference = sr.id AND srt.locale = current_locale()
                              LEFT JOIN db.invoice           i ON t.invoice = i.id
                             INNER JOIN db.state_type       st ON o.state_type = st.id
                              LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                             INNER JOIN db.state             s ON o.state = s.id
                              LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                             INNER JOIN db.user              w ON o.owner = w.id
                             INNER JOIN db.user              u ON o.oper = u.id
                             INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectTransaction TO administrator;
