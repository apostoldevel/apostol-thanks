--------------------------------------------------------------------------------
-- Currency --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Currency (Id, Reference,
  Code, Digital, Name, Description, Decimal
) AS
  SELECT c.id, c.reference, r.code, c.digital, r.name, r.description, c.decimal
    FROM db.currency c INNER JOIN Reference r ON r.id = c.reference;

GRANT SELECT ON Currency TO administrator;

--------------------------------------------------------------------------------
-- AccessCurrency ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCurrency
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('currency'), current_userid())
  )
  SELECT c.* FROM Currency c INNER JOIN access ac ON c.id = ac.object;

GRANT SELECT ON AccessCurrency TO administrator;

--------------------------------------------------------------------------------
-- ObjectCurrency ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCurrency (Id, Object, Parent,
  Event, EventCode, EventName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Digital, Name, Label, Description, Decimal,
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
         r.code, t.digital, r.name, r.label, r.description, t.decimal,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate,
         r.scope, r.scopecode, r.scopename, r.scopedescription
    FROM AccessCurrency t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectCurrency TO administrator;
