CREATE TABLE IF NOT EXISTS item_fulfillments (
  item_fulfillment_internal_id INTEGER,
  assembly_internal_id INTEGER,
  shipment_date DATE,
  item_name TEXT,
  quantity_shipped INTEGER,
  PRIMARY KEY (item_fulfillment_internal_id, assembly_internal_id) );
  
CREATE TABLE IF NOT EXISTS assembly_bom_match (
  assembly_internal_id INTEGER,
  assembly_name TEXT,
  bom_internal_id INTEGER,
  bom_name TEXT,
  PRIMARY KEY (assembly_internal_id, bom_internal_id) );

CREATE TABLE IF NOT EXISTS bom_data (
  bom_name TEXT,
  bom_internal_id INTEGER,
  revision_name TEXT,
  component_internal_id INTEGER,
  component_name TEXT,
  bom_quantity NUMERIC,
  PRIMARY KEY (component_internal_id, bom_internal_id) );

CREATE TABLE IF NOT EXISTS component_lead_times (
  internal_id INTEGER PRIMARY KEY,
  part_number TEXT,
  avg_lead_time INTEGER,
  variability INTEGER,
  is_critical BOOLEAN,
  is_on_blanket_po BOOLEAN,
  non_blanket_lt INTEGER,
  non_blanket_lt_variability INTEGER );

CREATE TABLE IF NOT EXISTS current_stock (
  internal_id INTEGER PRIMARY KEY,
  part_number TEXT,
  current_stock INTEGER );
