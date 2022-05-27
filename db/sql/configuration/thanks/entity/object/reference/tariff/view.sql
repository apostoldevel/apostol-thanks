--------------------------------------------------------------------------------
-- Tariff ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Tariff (Id, Reference, Price, Commission,
  Service, ServiceCode, ServiceName, Value,
  Measure, MeasureCode, MeasureName
)
AS
  SELECT t.id, t.reference, t.price, t.commission,
         t.service, s.code, s.name, s.value,
         s.measure, s.measurecode, s.measurename
    FROM db.tariff t INNER JOIN Service s ON t.service = s.id;

GRANT SELECT ON Tariff TO administrator;

--------------------------------------------------------------------------------
-- AccessTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessTariff
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('tariff'), current_userid())
  )
  SELECT t.* FROM Tariff t INNER JOIN access ac ON t.id = ac.object;

GRANT SELECT ON AccessTariff TO administrator;

--------------------------------------------------------------------------------
-- ObjectTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTariff (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Service, ServiceCode, ServiceName, Value,
  Measure, MeasureCode, MeasureName,
  Code, Name, Label, Price, Commission, Description,
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
         t.service, t.servicecode, t.servicename, t.value,
         t.measure, t.measurecode, t.measurename,
         r.code, r.name, r.label, t.price, t.commission, r.description,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate
    FROM AccessTariff t INNER JOIN ObjectReference r ON t.reference = r.id;

GRANT SELECT ON ObjectTariff TO administrator;
