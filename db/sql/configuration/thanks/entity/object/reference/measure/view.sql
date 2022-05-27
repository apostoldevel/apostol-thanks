--------------------------------------------------------------------------------
-- Measure ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Measure (Id, Reference, Code, Name, Description)
AS
  SELECT c.id, c.reference, r.code, r.name, r.description
    FROM db.measure c INNER JOIN Reference r ON r.id = c.reference;

GRANT SELECT ON Measure TO administrator;

--------------------------------------------------------------------------------
-- AccessMeasure ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessMeasure
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('measure'), current_userid())
  )
  SELECT c.* FROM Measure c INNER JOIN access ac ON c.id = ac.object;

GRANT SELECT ON AccessMeasure TO administrator;

--------------------------------------------------------------------------------
-- ObjectMeasure ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectMeasure (Id, Object, Parent,
  Event, EventCode, EventName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, r.object, r.parent,
         r.entity, r.entitycode, r.entityname,
         r.class, r.classcode, r.classlabel,
         r.type, r.typecode, r.typename, r.typedescription,
         r.code, r.name, r.label, r.description,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate,
         r.scope, r.scopecode, r.scopename, r.scopedescription
    FROM AccessMeasure t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectMeasure TO administrator;
