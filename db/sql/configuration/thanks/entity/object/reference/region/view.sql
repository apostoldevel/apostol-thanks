--------------------------------------------------------------------------------
-- REGION ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Region (Id, Reference, Code, Name, Description,
  Country, CountryCode, CountryName, CountryDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, t.reference, r.code, r.name, r.description,
         t.country, c.code, c.name, c.description,
         r.scope, r.scopecode, r.scopename, r.scopedescription
    FROM db.region t INNER JOIN Reference r ON t.reference = r.id
                     INNER JOIN Country   c ON t.country = c.id;

GRANT SELECT ON Region TO administrator;

--------------------------------------------------------------------------------
-- AccessRegion ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessRegion
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('region'), current_userid())
  )
  SELECT r.* FROM Region r INNER JOIN access ac ON r.id = ac.object;

GRANT SELECT ON AccessRegion TO administrator;

--------------------------------------------------------------------------------
-- ObjectRegion ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectRegion (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Country, CountryCode, CountryName, CountryDescription,
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
         t.country, t.countrycode, t.countryname, t.countrydescription,
         r.code, r.name, r.label, r.description,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate,
         r.scope, r.scopecode, r.scopename, r.scopedescription
    FROM AccessRegion t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectRegion TO administrator;
