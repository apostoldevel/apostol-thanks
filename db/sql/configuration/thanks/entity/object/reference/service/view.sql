--------------------------------------------------------------------------------
-- Service ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Service (Id, Reference,
    Category, CategoryCode, CategoryName, CategoryDescription,
    Measure, MeasureCode, MeasureName, MeasureDescription,
    Code, Name, Value, Description
)
AS
  SELECT s.id, s.reference,
         s.category, c.code, c.name, c.description,
         s.measure, m.code, m.name, m.description,
         d.code, d.name, s.value, d.description
    FROM db.service s INNER JOIN Reference d ON s.reference = d.id
                      INNER JOIN Reference c ON s.category = c.id
                      INNER JOIN Reference m ON s.measure = m.id;

GRANT SELECT ON Service TO administrator;

--------------------------------------------------------------------------------
-- AccessService ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessService
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('service'), current_userid())
  )
  SELECT s.* FROM Service s INNER JOIN access ac ON s.id = ac.object;

GRANT SELECT ON AccessService TO administrator;

--------------------------------------------------------------------------------
-- ObjectService ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectService (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Category, CategoryCode, CategoryName,
  Measure, MeasureCode, MeasureName,
  Code, Name, Label, Value, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate
)
AS
  SELECT t.id, r.object, r.parent,
         r.entity, r.entitycode, r.entityname,
         r.class, r.classcode, r.classlabel,
         r.type, r.typecode, r.typename, r.typedescription,
         t.category, t.categorycode, t.categoryname,
         t.measure, t.measurecode, t.measurename,
         r.code, r.name, r.label, t.value, r.description,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate
    FROM AccessService t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectService TO administrator;
