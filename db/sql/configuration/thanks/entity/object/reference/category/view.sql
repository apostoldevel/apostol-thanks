--------------------------------------------------------------------------------
-- Category --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Category (Id, Reference, Code, Name, Description)
AS
  SELECT c.id, c.reference, r.code, r.name, r.description
    FROM db.category c INNER JOIN Reference r ON r.id = c.reference;

GRANT SELECT ON Category TO administrator;

--------------------------------------------------------------------------------
-- AccessCategory --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessCategory
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('category'), current_userid())
  )
  SELECT c.* FROM Category c INNER JOIN access ac ON c.id = ac.object;

GRANT SELECT ON AccessCategory TO administrator;

--------------------------------------------------------------------------------
-- ObjectCategory --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCategory (Id, Object, Parent,
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
    FROM AccessCategory t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectCategory TO administrator;
