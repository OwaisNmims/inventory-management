const { pool } = require("../../../config/dbConfig");

module.exports = {
    // Get all inventory units with product, company, and status details
    getAllInventoryUnits: () => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.id as product_id,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   p.price,
                   ist.name as status,
                   ist.description as status_description,
                   c.name as current_company_name,
                   c.company_code as current_company_code,
                   c.company_type,
                   icm.id as mapping_id,
                   icm.company_lid as mapped_company_id,
                   mc.name as mapped_company_name,
                   mc.company_code as mapped_company_code,
                   ml.name as mapping_label,
                   ml.description as mapping_label_description,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at,
                   iu.created_at as inventory_created_at,
                   iu.updated_at as inventory_updated_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company mc ON mc.id = icm.company_lid
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE
                   ORDER BY p.name, iu.id;`,
            values: []
        };
        return pool.query(statement);
    },

    // Get inventory units by product ID
    getInventoryByProduct: (productId) => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.name as product_name,
                   p.product_code,
                   ist.name as status,
                   c.name as current_company_name,
                   c.company_code as current_company_code,
                   icm.id as mapping_id,
                   mc.name as mapped_company_name,
                   ml.name as mapping_label,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company mc ON mc.id = icm.company_lid
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE AND p.id = $1
                   ORDER BY iu.id;`,
            values: [productId]
        };
        return pool.query(statement);
    },

    // Get inventory units by company ID
    getInventoryByCompany: (companyId) => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   p.price,
                   ist.name as status,
                   c.name as current_company_name,
                   icm.id as mapping_id,
                   ml.name as mapping_label,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE AND icm.company_lid = $1
                   ORDER BY p.name, iu.id;`,
            values: [companyId]
        };
        return pool.query(statement);
    },

    // Get inventory summary by status
    getInventorySummary: () => {
        const statement = {
            text: `SELECT 
                   ist.name as status,
                   COUNT(iu.id) as count,
                   COUNT(DISTINCT p.id) as unique_products
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   WHERE iu.active = TRUE AND p.active = TRUE
                   GROUP BY ist.name, ist.id
                   ORDER BY ist.name;`,
            values: []
        };
        return pool.query(statement);
    },

    // Get available inventory units for mapping
    getAvailableInventory: () => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.id as product_id,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   p.price,
                   ist.name as status
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   WHERE iu.active = TRUE AND p.active = TRUE AND ist.name = 'AVAILABLE'
                   ORDER BY p.name, iu.id;`,
            values: []
        };
        return pool.query(statement);
    },

    // Update inventory unit status
    updateInventoryStatus: (inventoryId, statusName, updatedBy = 1) => {
        const statement = {
            text: `UPDATE inventory_unit 
                   SET status_lid = (SELECT id FROM inventory_status WHERE name = $2 AND active = TRUE),
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = $3
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [inventoryId, statusName, updatedBy]
        };
        return pool.query(statement);
    },

    // Get paginated available inventory with search
    getAvailableInventoryPaginated: (page = 1, limit = 20, search = '', sortBy = 'product_name', sortOrder = 'ASC') => {
        const offset = (parseInt(page) - 1) * parseInt(limit);
        const searchTerm = `%${search.toLowerCase()}%`;

        // Build search conditions
        let searchCondition = '';
        let searchParams = [];
        
        if (search.trim()) {
            searchCondition = `
                AND (
                    LOWER(p.name) LIKE $${searchParams.length + 1} OR 
                    LOWER(p.product_code) LIKE $${searchParams.length + 1} OR 
                    LOWER(p.category) LIKE $${searchParams.length + 1}
                )
            `;
            searchParams.push(searchTerm);
        }

        // Validate sort parameters
        const allowedSortFields = ['product_name', 'product_code', 'category', 'price', 'inventory_id'];
        const allowedSortOrders = ['ASC', 'DESC'];
        
        const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'product_name';
        const validSortOrder = allowedSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'ASC';

        // Get total count for pagination
        const countStatement = {
            text: `
                SELECT COUNT(*) as total
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                JOIN company c ON c.id = icm.company_lid
                WHERE iu.active = TRUE 
                    AND p.active = TRUE 
                    AND ist.name = 'AVAILABLE'
                    AND c.company_type = 'SELF'
                    ${searchCondition}
            `,
            values: searchParams
        };

        // Get paginated data
        const dataStatement = {
            text: `
                SELECT
                    iu.id as inventory_id,
                    p.id as product_id,
                    p.name as product_name,
                    p.product_code,
                    p.category,
                    p.price,
                    ist.name as status
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                JOIN company c ON c.id = icm.company_lid
                WHERE iu.active = TRUE 
                    AND p.active = TRUE 
                    AND ist.name = 'AVAILABLE'
                    AND c.company_type = 'SELF'
                    ${searchCondition}
                ORDER BY ${validSortBy} ${validSortOrder}, iu.id
                LIMIT $${searchParams.length + 1} OFFSET $${searchParams.length + 2}
            `,
            values: [...searchParams, parseInt(limit), offset]
        };

        return Promise.all([
            pool.query(countStatement),
            pool.query(dataStatement)
        ]);
    },

    // Get grouped inventory mappings (by product and company) with counts
    getInventoryMappingsGrouped: (page = 1, limit = 20, search = '', filters = {}, sortBy = 'product_name', sortOrder = 'ASC') => {
        const offset = (parseInt(page) - 1) * parseInt(limit);
        const searchTerm = `%${search.toLowerCase()}%`;

        // Build search and filter conditions (for WHERE clause - before GROUP BY)
        let whereConditions = ['icm.active = TRUE', 'iu.active = TRUE', 'p.active = TRUE'];
        let params = [];
        
        // Search condition
        if (search.trim()) {
            whereConditions.push(`
                (
                    LOWER(p.name) LIKE $${params.length + 1} OR 
                    LOWER(p.product_code) LIKE $${params.length + 1} OR 
                    LOWER(c.name) LIKE $${params.length + 1}
                )
            `);
            params.push(searchTerm);
        }

        // Company filter
        if (filters.company && filters.company.trim()) {
            whereConditions.push(`LOWER(c.name) = LOWER($${params.length + 1})`);
            params.push(filters.company);
        }

        // Product filter (partial match)
        if (filters.product && filters.product.trim()) {
            whereConditions.push(`LOWER(p.name) LIKE $${params.length + 1}`);
            params.push(`%${filters.product.toLowerCase()}%`);
        }

        // Combine all WHERE conditions
        const whereClause = `WHERE ${whereConditions.join(' AND ')}`;

        // Validate sort parameters
        const allowedSortFields = ['product_name', 'product_code', 'company_name', 'company_type', 'total_units', 'available_units', 'mapped_units', 'sold_units'];
        const allowedSortOrders = ['ASC', 'DESC'];
        
        const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'product_name';
        const validSortOrder = allowedSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'ASC';

        // Get total count for pagination (count of unique product-company combinations)
        const countStatement = {
            text: `
                SELECT COUNT(*) as total
                FROM (
                    SELECT 
                        p.id as product_id,
                        c.id as company_id
                    FROM inventory_company_mapping icm
                    JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                    JOIN product p ON p.id = iu.product_lid
                    JOIN company c ON c.id = icm.company_lid
                    JOIN mapping_label ml ON ml.id = icm.label_lid
                    JOIN inventory_status ist ON ist.id = iu.status_lid
                    ${whereClause}
                    GROUP BY p.id, p.name, p.product_code, c.id, c.name, c.company_type
                ) as unique_mappings
            `,
            values: params
        };

        // Get grouped data with counts
        const dataStatement = {
            text: `
                SELECT 
                    p.id as product_id,
                    p.name as product_name,
                    p.product_code,
                    p.price,
                    p.category,
                    c.id as company_id,
                    c.name as company_name,
                    c.company_code,
                    c.company_type,
                    COUNT(*) as total_units,
                    COUNT(CASE WHEN ist.name = 'AVAILABLE' THEN 1 END) as available_units,
                    COUNT(CASE WHEN ist.name = 'MAPPED' THEN 1 END) as mapped_units,
                    COUNT(CASE WHEN ist.name = 'SOLD' THEN 1 END) as sold_units,
                    COUNT(CASE WHEN ml.name = 'NEW' AND ist.name != 'SOLD' THEN 1 END) as new_stock,
                    COUNT(CASE WHEN ml.name = 'OLD' AND ist.name != 'SOLD' THEN 1 END) as old_stock,
                    SUM(p.price) as total_value,
                    SUM(CASE WHEN ist.name = 'SOLD' THEN p.price ELSE 0 END) as sold_value,
                    MIN(icm.created_at) as first_mapped_at,
                    MAX(icm.created_at) as last_mapped_at
                FROM inventory_company_mapping icm
                JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                JOIN product p ON p.id = iu.product_lid
                JOIN company c ON c.id = icm.company_lid
                JOIN mapping_label ml ON ml.id = icm.label_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                ${whereClause}
                GROUP BY p.id, p.name, p.product_code, p.price, p.category, c.id, c.name, c.company_code, c.company_type
                ORDER BY ${validSortBy} ${validSortOrder}
                LIMIT $${params.length + 1} OFFSET $${params.length + 2}
            `,
            values: [...params, parseInt(limit), offset]
        };

        return Promise.all([
            pool.query(countStatement),
            pool.query(dataStatement)
        ]);
    },

    // Get paginated inventory mappings with search and filters (original detailed view)
    getInventoryMappingsPaginated: (page = 1, limit = 20, search = '', filters = {}, sortBy = 'icm.created_at', sortOrder = 'DESC') => {
        const offset = (parseInt(page) - 1) * parseInt(limit);
        const searchTerm = `%${search.toLowerCase()}%`;

        // Build search and filter conditions
        let conditions = [];
        let params = [];
        
        // Search condition
        if (search.trim()) {
            conditions.push(`
                (
                    LOWER(p.name) LIKE $${params.length + 1} OR 
                    LOWER(p.product_code) LIKE $${params.length + 1} OR 
                    LOWER(c.name) LIKE $${params.length + 1} OR
                    LOWER(ml.name) LIKE $${params.length + 1}
                )
            `);
            params.push(searchTerm);
        }

        // Company filter
        if (filters.company && filters.company.trim()) {
            conditions.push(`LOWER(c.name) = LOWER($${params.length + 1})`);
            params.push(filters.company);
        }

        // Label filter
        if (filters.label && filters.label.trim()) {
            if (filters.label === 'SOLD') {
                conditions.push(`ist.name = 'SOLD'`);
            } else {
                conditions.push(`ml.name = $${params.length + 1} AND ist.name != 'SOLD'`);
                params.push(filters.label);
            }
        }

        // Product filter (exact or partial match based on exactProduct flag)
        if (filters.product && filters.product.trim()) {
            if (filters.exactProduct === 'true' || filters.exactProduct === true) {
                // Exact match
                console.log('Using EXACT product match for:', filters.product);
                conditions.push(`LOWER(p.name) = LOWER($${params.length + 1})`);
                params.push(filters.product);
            } else {
                // Partial match
                console.log('Using PARTIAL product match for:', filters.product);
                conditions.push(`LOWER(p.name) LIKE $${params.length + 1}`);
                params.push(`%${filters.product.toLowerCase()}%`);
            }
        }

        // Combine all conditions
        const whereClause = conditions.length > 0 
            ? `AND (${conditions.join(' AND ')})` 
            : '';

        console.log('getInventoryMappingsPaginated - WHERE clause:', whereClause);
        console.log('getInventoryMappingsPaginated - Params:', params);

        // Validate sort parameters
        const allowedSortFields = ['icm.created_at', 'p.name', 'p.product_code', 'c.name', 'ml.name', 'ist.name'];
        const allowedSortOrders = ['ASC', 'DESC'];
        
        const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'icm.created_at';
        const validSortOrder = allowedSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'DESC';

        // Get total count for pagination
        const countStatement = {
            text: `
                SELECT COUNT(*) as total
                FROM inventory_company_mapping icm
                JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                JOIN product p ON p.id = iu.product_lid
                JOIN company c ON c.id = icm.company_lid
                JOIN mapping_label ml ON ml.id = icm.label_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                WHERE icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                ${whereClause}
            `,
            values: params
        };

        // Get paginated data
        const dataStatement = {
            text: `
                SELECT 
                    icm.id as mapping_id,
                    iu.id as inventory_id,
                    p.name as product_name,
                    p.product_code,
                    p.price,
                    p.category,
                    c.name as company_name,
                    c.company_code,
                    c.company_type,
                    CASE 
                        WHEN ist.name = 'SOLD' THEN 'SOLD'
                        ELSE ml.name 
                    END as label,
                    icm.notes,
                    icm.created_at as mapped_at,
                    ist.name as status
                FROM inventory_company_mapping icm
                JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                JOIN product p ON p.id = iu.product_lid
                JOIN company c ON c.id = icm.company_lid
                JOIN mapping_label ml ON ml.id = icm.label_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                WHERE icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                ${whereClause}
                ORDER BY ${validSortBy} ${validSortOrder}
                LIMIT $${params.length + 1} OFFSET $${params.length + 2}
            `,
            values: [...params, parseInt(limit), offset]
        };

        return Promise.all([
            pool.query(countStatement),
            pool.query(dataStatement)
        ]);
    },

    // Get paginated inventory units with search and filters
    getInventoryUnitsPaginated: (page = 1, limit = 20, search = '', filters = {}, sortBy = 'iu.id', sortOrder = 'DESC') => {
        const offset = (parseInt(page) - 1) * parseInt(limit);
        const searchTerm = `%${search.toLowerCase()}%`;

        // Build search and filter conditions
        let conditions = [];
        let params = [];
        
        // Search condition
        if (search.trim()) {
            conditions.push(`
                (
                    LOWER(p.name) LIKE $${params.length + 1} OR 
                    LOWER(p.product_code) LIKE $${params.length + 1} OR 
                    LOWER(c.name) LIKE $${params.length + 1} OR
                    LOWER(ist.name) LIKE $${params.length + 1}
                )
            `);
            params.push(searchTerm);
        }

        // Status filter
        if (filters.status && filters.status.trim()) {
            conditions.push(`ist.name = $${params.length + 1}`);
            params.push(filters.status);
        }

        // Product filter
        if (filters.product && filters.product.trim()) {
            conditions.push(`p.id = $${params.length + 1}`);
            params.push(parseInt(filters.product));
        }

        // Company filter
        if (filters.company && filters.company.trim()) {
            conditions.push(`icm.company_lid = $${params.length + 1}`);
            params.push(parseInt(filters.company));
        }

        // Combine all conditions
        const whereClause = conditions.length > 0 
            ? `AND (${conditions.join(' AND ')})` 
            : '';

        // Validate sort parameters
        const allowedSortFields = ['iu.id', 'p.name', 'p.product_code', 'ist.name', 'c.name', 'iu.created_at'];
        const allowedSortOrders = ['ASC', 'DESC'];
        
        const validSortBy = allowedSortFields.includes(sortBy) ? sortBy : 'iu.id';
        const validSortOrder = allowedSortOrders.includes(sortOrder.toUpperCase()) ? sortOrder.toUpperCase() : 'DESC';

        // Get total count for pagination
        const countStatement = {
            text: `
                SELECT COUNT(DISTINCT iu.id) as total
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                LEFT JOIN company c ON c.id = icm.company_lid
                WHERE iu.active = TRUE AND p.active = TRUE
                ${whereClause}
            `,
            values: params
        };

        // Get paginated data
        const dataStatement = {
            text: `
                SELECT 
                    iu.id as inventory_id,
                    p.id as product_id,
                    p.name as product_name,
                    p.product_code,
                    p.category,
                    p.price,
                    ist.name as status,
                    ist.description as status_description,
                    c.name as current_company_name,
                    c.company_code as current_company_code,
                    c.company_type,
                    icm.id as mapping_id,
                    icm.company_lid as mapped_company_id,
                    mc.name as mapped_company_name,
                    mc.company_code as mapped_company_code,
                    ml.name as mapping_label,
                    ml.description as mapping_label_description,
                    icm.notes as mapping_notes,
                    icm.created_at as mapped_at,
                    iu.created_at as inventory_created_at,
                    iu.updated_at as inventory_updated_at
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                LEFT JOIN company c ON c.id = iu.current_company_lid
                LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                LEFT JOIN company mc ON mc.id = icm.company_lid
                LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                WHERE iu.active = TRUE AND p.active = TRUE
                ${whereClause}
                ORDER BY ${validSortBy} ${validSortOrder}
                LIMIT $${params.length + 1} OFFSET $${params.length + 2}
            `,
            values: [...params, parseInt(limit), offset]
        };

        return Promise.all([
            pool.query(countStatement),
            pool.query(dataStatement)
        ]);
    },

    // Get products with their available unit counts for mapping
    getProductsWithAvailableUnits: async (page, limit, search, sortBy = 'p.name', sortOrder = 'ASC') => {
        const offset = (page - 1) * limit;
        let searchCondition = '';
        const params = [];
        let paramCount = 0;

        if (search) {
            paramCount++;
            searchCondition = `AND (LOWER(p.name) LIKE $${paramCount} OR LOWER(p.product_code) LIKE $${paramCount} OR LOWER(p.category) LIKE $${paramCount})`;
            params.push(`%${search.toLowerCase()}%`);
        }

        // Count query
        const countQuery = `
            SELECT COUNT(DISTINCT p.id) as total
            FROM product p
            JOIN inventory_unit iu ON iu.product_lid = p.id
            JOIN inventory_status ist ON ist.id = iu.status_lid
            JOIN company c ON c.id = iu.current_company_lid
            WHERE p.active = TRUE 
            AND iu.active = TRUE 
            AND c.company_code = 'SELF'
            AND ist.name = 'AVAILABLE'
            ${searchCondition}
        `;

        // Data query - group by product and sum available units
        const dataQuery = `
            SELECT 
                p.id as product_id,
                p.name as product_name,
                p.product_code,
                p.category,
                p.price,
                COUNT(iu.id) as available_units,
                MIN(iu.created_at) as first_created,
                MAX(iu.created_at) as last_created
            FROM product p
            JOIN inventory_unit iu ON iu.product_lid = p.id
            JOIN inventory_status ist ON ist.id = iu.status_lid
            JOIN company c ON c.id = iu.current_company_lid
            WHERE p.active = TRUE 
            AND iu.active = TRUE 
            AND c.company_code = 'SELF'
            AND ist.name = 'AVAILABLE'
            ${searchCondition}
            GROUP BY p.id, p.name, p.product_code, p.category, p.price
            ORDER BY ${sortBy} ${sortOrder}
            LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
        `;

        params.push(limit, offset);

        return await Promise.all([
            pool.query(countQuery, params.slice(0, paramCount)),
            pool.query(dataQuery, params)
        ]);
    }
};
