--------------------------------------------------------------------------------
-- Property --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Property (Id, Reference,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Description
) AS
  SELECT p.id, p.reference,
         r.type, t.code, t.name, t.description,
         r.code, r.name, r.description
    FROM db.property p INNER JOIN Reference r ON r.id = p.reference
                       INNER JOIN Type      t ON t.id = r.type;

GRANT SELECT ON Property TO administrator;

--------------------------------------------------------------------------------
-- AccessProperty --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessProperty
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('property'), current_userid())
  )
  SELECT c.* FROM Property c INNER JOIN access ac ON c.id = ac.object;

GRANT SELECT ON AccessProperty TO administrator;

--------------------------------------------------------------------------------
-- ObjectProperty --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectProperty (Id, Object, Parent,
  Entity, EntityCode, EntityName,
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
    FROM AccessProperty t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectProperty TO administrator;
