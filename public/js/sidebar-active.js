// Sidebar Active State Management
$(document).ready(function() {
    // Get current URL path
    const currentPath = window.location.pathname;
    
    // Remove any existing active classes
    $('.menu').removeClass('active');
    $('.submenu li a').removeClass('active');
    
    // Function to set active menu item
    function setActiveMenu(menuItem, parentCollapse = null) {
        // Add active class to the menu item
        menuItem.addClass('active');
        
        // If it's a submenu item, also activate parent
        if (parentCollapse) {
            const parentMenu = $(`a[href="#${parentCollapse}"]`).closest('.menu');
            parentMenu.addClass('active');
            
            // Expand the parent menu
            $(`#${parentCollapse}`).addClass('show');
            $(`a[href="#${parentCollapse}"]`).attr('aria-expanded', 'true').removeClass('collapsed');
        }
    }
    
    // Check for exact matches first (direct menu items)
    const directMenus = {
        '/admin/dashboard': $('.menu a[href="/admin/dashboard"]').closest('.menu'),
        '/admin/users': $('.menu a[href="/admin/users"]').closest('.menu')
    };
    
    // Check direct menu matches
    for (const [path, menuElement] of Object.entries(directMenus)) {
        if (currentPath === path && menuElement.length) {
            setActiveMenu(menuElement);
            return;
        }
    }
    
    // Check submenu items
    const submenuItems = {
        // Master Data
        '/admin/country': { element: $('.submenu a[href="/admin/country"]'), parent: 'masterElements' },
        '/admin/state': { element: $('.submenu a[href="/admin/state"]'), parent: 'masterElements' },
        '/admin/city': { element: $('.submenu a[href="/admin/city"]'), parent: 'masterElements' },
        '/admin/company': { element: $('.submenu a[href="/admin/company"]'), parent: 'masterElements' },
        '/admin/company-type': { element: $('.submenu a[href="/admin/company-type"]'), parent: 'masterElements' },
        '/admin/currency': { element: $('.submenu a[href="/admin/currency"]'), parent: 'masterElements' },
        
        // Inventory Management
        '/admin/product': { element: $('.submenu a[href="/admin/product"]'), parent: 'inventoryElements' },
        '/admin/inventory': { element: $('.submenu a[href="/admin/inventory"]'), parent: 'inventoryElements' },
        '/admin/inventory-mapping': { element: $('.submenu a[href="/admin/inventory-mapping"]'), parent: 'inventoryElements' }
    };
    
    // Check submenu matches
    for (const [path, config] of Object.entries(submenuItems)) {
        if (currentPath === path && config.element.length) {
            // Add active class to the specific submenu link
            config.element.addClass('active');
            // Also activate and expand the parent menu
            setActiveMenu(config.element.closest('.menu'), config.parent);
            return;
        }
    }
    
    // Check for masters dashboard route
    if (currentPath === '/admin/masters') {
        const masterMenu = $('.menu a[href="#masterElements"]').closest('.menu');
        if (masterMenu.length) {
            setActiveMenu(masterMenu, 'masterElements');
            return;
        }
    }
    
    // If no exact match, try partial matches for dynamic routes
    if (currentPath.startsWith('/admin/product/')) {
        const productMenu = $('.submenu a[href="/admin/product"]');
        if (productMenu.length) {
            productMenu.addClass('active');
            setActiveMenu(productMenu.closest('.menu'), 'inventoryElements');
        }
    } else if (currentPath.startsWith('/admin/inventory/')) {
        const inventoryMenu = $('.submenu a[href="/admin/inventory"]');
        if (inventoryMenu.length) {
            inventoryMenu.addClass('active');
            setActiveMenu(inventoryMenu.closest('.menu'), 'inventoryElements');
        }
    } else if (currentPath.startsWith('/admin/company/')) {
        const companyMenu = $('.submenu a[href="/admin/company"]');
        if (companyMenu.length) {
            companyMenu.addClass('active');
            setActiveMenu(companyMenu.closest('.menu'), 'masterElements');
        }
    } else if (currentPath.startsWith('/admin/users/')) {
        const usersMenu = $('.menu a[href="/admin/users"]');
        if (usersMenu.length) {
            setActiveMenu(usersMenu.closest('.menu'));
        }
    } else if (currentPath.startsWith('/admin/country/')) {
        const countryMenu = $('.submenu a[href="/admin/country"]');
        if (countryMenu.length) {
            countryMenu.addClass('active');
            setActiveMenu(countryMenu.closest('.menu'), 'masterElements');
        }
    } else if (currentPath.startsWith('/admin/state/')) {
        const stateMenu = $('.submenu a[href="/admin/state"]');
        if (stateMenu.length) {
            stateMenu.addClass('active');
            setActiveMenu(stateMenu.closest('.menu'), 'masterElements');
        }
    } else if (currentPath.startsWith('/admin/city/')) {
        const cityMenu = $('.submenu a[href="/admin/city"]');
        if (cityMenu.length) {
            cityMenu.addClass('active');
            setActiveMenu(cityMenu.closest('.menu'), 'masterElements');
        }
    } else if (currentPath.startsWith('/admin/currency/')) {
        const currencyMenu = $('.submenu a[href="/admin/currency"]');
        if (currencyMenu.length) {
            currencyMenu.addClass('active');
            setActiveMenu(currencyMenu.closest('.menu'), 'masterElements');
        }
    } else if (currentPath.startsWith('/admin/inventory-mapping/')) {
        const mappingMenu = $('.submenu a[href="/admin/inventory-mapping"]');
        if (mappingMenu.length) {
            mappingMenu.addClass('active');
            setActiveMenu(mappingMenu.closest('.menu'), 'inventoryElements');
        }
    } else if (currentPath.startsWith('/admin/masters/')) {
        const masterMenu = $('.menu a[href="#masterElements"]').closest('.menu');
        if (masterMenu.length) {
            setActiveMenu(masterMenu, 'masterElements');
        }
    }
    
    // Handle menu clicks to update active state
    $('.menu a').on('click', function(e) {
        const href = $(this).attr('href');
        
        // Don't handle collapse toggles
        if (href && href.startsWith('#')) {
            return;
        }
        
        // Remove existing active classes
        $('.menu').removeClass('active');
        $('.submenu li a').removeClass('active');
        
        // Add active to clicked item
        if ($(this).closest('.submenu').length) {
            // It's a submenu item
            $(this).addClass('active');
            $(this).closest('.menu').addClass('active');
        } else {
            // It's a direct menu item
            $(this).closest('.menu').addClass('active');
        }
    });
});
