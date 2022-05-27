--------------------------------------------------------------------------------
-- Contract --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Contract
AS
  SELECT c.id, c.document, c.code, c.content, c.data, c.validFromDate, c.validToDate,
         c.client, cl.code AS ClientCode, cl.fullname AS ClientName
    FROM db.contract c LEFT JOIN Client cl on c.client = cl.id;

GRANT SELECT ON Contract TO administrator;

--------------------------------------------------------------------------------
-- AccessContract --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessContract
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('contract'), current_userid())
  )
  SELECT c.* FROM Contract c INNER JOIN access ac ON c.id = ac.object;

GRANT SELECT ON AccessContract TO administrator;

--------------------------------------------------------------------------------
-- ObjectContract --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectContract (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName,
  Code, Label, Description,
  Content, Data, ValidFromDate, ValidToDate,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription
)
AS
  SELECT t.id, d.object, d.parent,
         d.entity, d.entitycode, d.entityname,
         d.class, d.classcode, d.classlabel,
         d.type, d.typecode, d.typename, d.typedescription,
         t.client, t.clientcode, t.clientname,
         t.code, d.label, d.description,
         t.content, t.data, t.validfromdate, t.validtodate,
         d.statetype, d.statetypecode, d.statetypename,
         d.state, d.statecode, d.statelabel, d.lastupdate,
         d.owner, d.ownercode, d.ownername, d.created,
         d.oper, d.opercode, d.opername, d.operdate,
         d.area, d.areacode, d.areaname, d.areadescription
    FROM AccessContract t INNER JOIN ObjectDocument d ON t.document = d.id;

GRANT SELECT ON ObjectContract TO administrator;
