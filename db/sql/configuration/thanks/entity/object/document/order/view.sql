--------------------------------------------------------------------------------
-- Orders ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Orders
AS
  SELECT o.id, o.document, o.code,
         o.client, c.code AS ClientCode,
         o.invoice, i.code AS InvoiceCode,
         o.amount, o.orderId
    FROM db.order o INNER JOIN db.client c  ON c.id = o.client
                     LEFT JOIN db.invoice i ON i.id = o.invoice;

GRANT SELECT ON Orders TO administrator;

--------------------------------------------------------------------------------
-- AccessOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessOrder
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('order'), current_userid())
  )
  SELECT o.* FROM Orders o INNER JOIN access ac ON o.id = ac.object;

GRANT SELECT ON AccessOrder TO administrator;

--------------------------------------------------------------------------------
-- ObjectOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectOrder (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Label, Description,
  Client, ClientCode, Amount,
  Invoice, InvoiceCode, OrderId,
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
         t.code, d.label, d.description,
         t.client, t.clientcode, t.amount,
         t.invoice, t.invoicecode, t.orderid,
         d.statetype, d.statetypecode, d.statetypename,
         d.state, d.statecode, d.statelabel, d.lastupdate,
         d.owner, d.ownercode, d.ownername, d.created,
         d.oper, d.opercode, d.opername, d.operdate,
         d.area, d.areacode, d.areaname, d.areadescription
    FROM AccessOrder t INNER JOIN ObjectDocument d ON t.document = d.id;

GRANT SELECT ON ObjectOrder TO administrator;
