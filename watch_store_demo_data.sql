-- DEMO DATA FOR WATCH STORES AND WATCHES
-- Run this after your main database setup

-- Insert Companies (Watch Stores)
-- JEAN FENDI as SELF company
INSERT INTO company (name, company_code, email, phone, address_line1, city_lid, company_type_lid, website, created_by) VALUES
('JEAN FENDI', 'JF001', 'contact@jeanfendi.com', '+1-555-0101', '123 Luxury Avenue', 1, 1, 'www.jeanfendi.com', 1);

-- Vendor Watch Stores
INSERT INTO company (name, company_code, email, phone, address_line1, city_lid, company_type_lid, website, created_by) VALUES
('Rolex Authorized Dealer', 'RAD001', 'sales@rolexdealer.com', '+1-555-0102', '456 Watch Street', 1, 2, 'www.rolexdealer.com', 1),
('Omega Boutique', 'OMG001', 'info@omegaboutique.com', '+1-555-0103', '789 Time Square', 1, 2, 'www.omegaboutique.com', 1),
('Seiko Premium Store', 'SEI001', 'contact@seikopremium.com', '+1-555-0104', '321 Precision Plaza', 1, 2, 'www.seikopremium.com', 1),
('Citizen Watch Center', 'CIT001', 'sales@citizencenter.com', '+1-555-0105', '654 Chronograph Circle', 1, 2, 'www.citizencenter.com', 1),
('Casio Official Store', 'CAS001', 'support@casiostore.com', '+1-555-0106', '987 Digital Drive', 1, 2, 'www.casiostore.com', 1),
('Tag Heuer Specialist', 'TAG001', 'info@tagheuerspec.com', '+1-555-0107', '147 Swiss Lane', 1, 2, 'www.tagheuerspec.com', 1),
('Breitling Gallery', 'BRE001', 'contact@breitlinggallery.com', '+1-555-0108', '258 Aviation Avenue', 1, 2, 'www.breitlinggallery.com', 1),
('IWC Boutique', 'IWC001', 'sales@iwcboutique.com', '+1-555-0109', '369 Engineering Street', 1, 2, 'www.iwcboutique.com', 1),
('Panerai Store', 'PAN001', 'info@paneraistore.com', '+1-555-0110', '741 Marine Boulevard', 1, 2, 'www.paneraistore.com', 1),
('Tissot Showroom', 'TIS001', 'contact@tissotshowroom.com', '+1-555-0111', '852 Heritage Plaza', 1, 2, 'www.tissotshowroom.com', 1);

-- Insert Products (Watches)
INSERT INTO product (name, product_code, description, category, price, unit, specifications, created_by) VALUES
-- Luxury Watches
('Rolex Submariner', 'RLX-SUB-001', 'Professional diving watch with date', 'Luxury', 8500.00, 'piece', 'Water resistant 300m, Automatic movement, Oystersteel case', 1),
('Omega Speedmaster', 'OMG-SPD-001', 'Moonwatch Professional Chronograph', 'Luxury', 6200.00, 'piece', 'Manual winding, Chronograph, Hesalite crystal', 1),
('Tag Heuer Carrera', 'TAG-CAR-001', 'Racing inspired chronograph watch', 'Luxury', 4500.00, 'piece', 'Automatic chronograph, Sapphire crystal, Steel bracelet', 1),
('Breitling Navitimer', 'BRE-NAV-001', 'Aviation chronograph with slide rule', 'Luxury', 5800.00, 'piece', 'Automatic movement, Slide rule bezel, 70h power reserve', 1),
('IWC Pilot Watch', 'IWC-PIL-001', 'Big Pilot automatic watch', 'Luxury', 7200.00, 'piece', '46mm case, 7 days power reserve, Soft iron inner case', 1),
('Panerai Luminor', 'PAN-LUM-001', 'Marina automatic watch', 'Luxury', 6800.00, 'piece', '44mm case, Crown protection bridge, Super-LumiNova', 1),

-- Mid-Range Watches
('Seiko Prospex Diver', 'SEI-PRO-001', 'Automatic diving watch', 'Sport', 350.00, 'piece', 'Water resistant 200m, 4R36 movement, Hardlex crystal', 1),
('Citizen Eco-Drive', 'CIT-ECO-001', 'Solar powered analog watch', 'Casual', 280.00, 'piece', 'Solar movement, 6 month power reserve, WR 100m', 1),
('Tissot PRC 200', 'TIS-PRC-001', 'Swiss quartz sports watch', 'Sport', 425.00, 'piece', 'Swiss quartz, 200m water resistance, Sapphire crystal', 1),
('Seiko 5 Sports', 'SEI-5SP-001', 'Automatic sports watch', 'Sport', 180.00, 'piece', '4R36 automatic, Day-date display, 100m water resistance', 1),

-- Entry-Level Watches
('Casio G-Shock', 'CAS-GSH-001', 'Digital shock resistant watch', 'Digital', 120.00, 'piece', 'Shock resistant, 200m water resistance, Multi-function', 1),
('Casio Edifice', 'CAS-EDI-001', 'Solar chronograph watch', 'Sport', 250.00, 'piece', 'Solar powered, Bluetooth connectivity, Smartphone link', 1),
('Citizen Corso', 'CIT-COR-001', 'Eco-Drive dress watch', 'Dress', 195.00, 'piece', 'Solar movement, Date display, Leather strap', 1),
('Seiko Solar', 'SEI-SOL-001', 'Solar powered dress watch', 'Dress', 165.00, 'piece', 'Solar movement, Date display, Stainless steel', 1),

-- Limited Editions
('Rolex GMT-Master II', 'RLX-GMT-001', 'Pepsi bezel GMT watch', 'Luxury', 12500.00, 'piece', 'Dual time zone, Cerachrom bezel, Oystersteel', 1),
('Omega Planet Ocean', 'OMG-PLO-001', 'Professional diving watch', 'Luxury', 5200.00, 'piece', '600m water resistance, Co-Axial movement, Helium escape valve', 1),
('Tag Heuer Monaco', 'TAG-MON-001', 'Square chronograph watch', 'Luxury', 6800.00, 'piece', 'Iconic square case, Automatic chronograph, Gulf racing colors', 1),
('Breitling Superocean', 'BRE-SUP-001', 'Professional diving watch', 'Sport', 3200.00, 'piece', '1000m water resistance, Unidirectional bezel, Rubber strap', 1),
('IWC Aquatimer', 'IWC-AQU-001', 'Diving watch with internal bezel', 'Sport', 4500.00, 'piece', 'Internal rotating bezel, 300m water resistance, Quick-change strap', 1),
('Panerai Radiomir', 'PAN-RAD-001', 'Historic military watch', 'Heritage', 5800.00, 'piece', 'Hand-wound movement, 45mm case, Historic design', 1);

-- Product Company Mappings (Realistic distribution)
-- JEAN FENDI (SELF) gets premium watches - mostly NEW status
INSERT INTO product_company_mapping (product_lid, company_lid, label_lid, notes, created_by) VALUES
-- JEAN FENDI gets luxury watches
(1, 1, 1, 'Latest Submariner model for premium customers', 1), -- Rolex Submariner - NEW
(2, 1, 1, 'Speedmaster for space enthusiasts', 1), -- Omega Speedmaster - NEW
(5, 1, 1, 'IWC Pilot for aviation collectors', 1), -- IWC Pilot - NEW
(15, 1, 1, 'Exclusive GMT-Master II limited stock', 1), -- Rolex GMT - NEW
(17, 1, 1, 'Monaco limited edition arrival', 1), -- Tag Monaco - NEW

-- Some older luxury inventory
(6, 1, 2, 'Previous season Luminor inventory', 1), -- Panerai Luminor - OLD
(16, 1, 2, 'Planet Ocean from last quarter', 1), -- Omega Planet Ocean - OLD

-- Rolex Dealer gets Rolex products
(1, 2, 1, 'Authorized Rolex Submariner dealer stock', 1), -- NEW
(15, 2, 1, 'GMT-Master II authorized dealer allocation', 1), -- NEW

-- Omega Boutique gets Omega products  
(2, 3, 1, 'Official Omega Speedmaster stock', 1), -- NEW
(16, 3, 1, 'New Planet Ocean arrival', 1), -- NEW

-- Seiko Premium gets Seiko products
(7, 4, 1, 'Prospex Diver new collection', 1), -- NEW
(10, 4, 1, 'Seiko 5 Sports latest models', 1), -- NEW
(14, 4, 2, 'Previous generation Solar watches', 1), -- OLD

-- Citizen Watch Center gets Citizen products
(8, 5, 1, 'New Eco-Drive collection', 1), -- NEW
(13, 5, 1, 'Corso dress watch new arrivals', 1), -- NEW

-- Casio Store gets Casio products
(11, 6, 1, 'Latest G-Shock models', 1), -- NEW
(12, 6, 1, 'New Edifice with Bluetooth', 1), -- NEW

-- Tag Heuer Specialist gets Tag products
(3, 7, 1, 'Carrera racing collection', 1), -- NEW
(17, 7, 1, 'Monaco heritage edition', 1), -- NEW

-- Breitling Gallery gets Breitling products
(4, 8, 1, 'Navitimer pilot collection', 1), -- NEW
(18, 8, 1, 'Superocean diving collection', 1), -- NEW

-- IWC Boutique gets IWC products
(5, 9, 1, 'Big Pilot latest edition', 1), -- NEW
(19, 9, 1, 'Aquatimer diving series', 1), -- NEW

-- Panerai Store gets Panerai products
(6, 10, 1, 'Luminor Marina collection', 1), -- NEW
(20, 10, 1, 'Radiomir heritage series', 1), -- NEW

-- Tissot Showroom gets Tissot products
(9, 11, 1, 'PRC 200 sports collection', 1), -- NEW

-- Some SOLD examples (realistic sales)
(7, 4, 3, 'Sold to diving enthusiast customer', 1), -- Seiko Prospex - SOLD
(8, 5, 3, 'Sold to business professional', 1), -- Citizen Eco-Drive - SOLD
(11, 6, 3, 'Sold to outdoor adventure customer', 1), -- Casio G-Shock - SOLD
(9, 11, 3, 'Sold to sports watch collector', 1); -- Tissot PRC - SOLD

-- Additional OLD inventory for variety
INSERT INTO product_company_mapping (product_lid, company_lid, label_lid, notes, created_by) VALUES
(10, 4, 2, 'Previous season Seiko 5 Sports', 1), -- OLD
(12, 6, 2, 'Previous Edifice model', 1), -- OLD
(13, 5, 2, 'Last year Corso collection', 1), -- OLD
(3, 7, 2, 'Previous Carrera edition', 1), -- OLD
(4, 8, 2, 'Previous Navitimer model', 1); -- OLD 