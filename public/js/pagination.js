/**
 * Reusable Pagination Component
 * Follows DRY principle for consistent pagination across the application
 */

class PaginationManager {
    constructor(config) {
        this.config = {
            containerId: config.containerId,
            apiUrl: config.apiUrl,
            pageSize: config.pageSize || 20,
            searchInputId: config.searchInputId,
            searchDelay: config.searchDelay || 500,
            onDataLoad: config.onDataLoad || function() {},
            onError: config.onError || function() {},
            filters: config.filters || {}, // Custom filter configuration
            customParams: config.customParams || {}, // Fixed params always sent with requests
            ...config
        };
        
        this.currentPage = 1;
        this.currentLimit = this.config.pageSize;
        this.currentSearch = '';
        this.currentFilters = {}; // Store current filter values
        this.totalPages = 1;
        this.totalRecords = 0;
        this.isLoading = false;
        this.searchTimeout = null;
        
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.loadData(1, this.currentLimit, this.currentSearch);
    }
    
    bindEvents() {
        console.log(`Binding events for container: ${this.config.containerId}`);
        
        // Search functionality with debouncing
        if (this.config.searchInputId) {
            console.log(`Binding search input: ${this.config.searchInputId}`);
            $(this.config.searchInputId).on('input', (e) => {
                const searchTerm = $(e.target).val().trim();
                this.handleSearch(searchTerm);
            });
        }
        
        // Pagination controls
        const prevButton = $(`#${this.config.containerId} .pagination-prev`);
        const nextButton = $(`#${this.config.containerId} .pagination-next`);
        
        console.log(`Found prev button: ${prevButton.length}, next button: ${nextButton.length}`);
        
        prevButton.on('click', () => {
            console.log('Previous button clicked');
            if (this.currentPage > 1) {
                this.loadData(this.currentPage - 1, this.currentLimit, this.currentSearch, this.currentFilters);
            }
        });
        
        nextButton.on('click', () => {
            console.log('Next button clicked');
            if (this.currentPage < this.totalPages) {
                this.loadData(this.currentPage + 1, this.currentLimit, this.currentSearch, this.currentFilters);
            }
        });
        
        // Items per page change
        $(`#${this.config.containerId} .pagination-items-per-page`).on('change', (e) => {
            const newLimit = parseInt($(e.target).val());
            this.loadData(1, newLimit, this.currentSearch, this.currentFilters);
        });
        
        // Clear search
        $(`#${this.config.containerId} .pagination-clear-search`).on('click', () => {
            if (this.config.searchInputId) {
                $(this.config.searchInputId).val('');
            }
            this.loadData(1, this.currentLimit, '');
        });
        
        // Bind filter change events
        if (this.config.filters) {
            Object.keys(this.config.filters).forEach((filterKey) => {
                const filterSelector = this.config.filters[filterKey];
                console.log(`Binding filter: ${filterKey} -> ${filterSelector}`);
                
                $(filterSelector).on('change', () => {
                    this.handleFilterChange();
                });
            });
        }
        
        console.log('Events bound successfully');
    }
    
    handleFilterChange() {
        // Collect current filter values
        if (this.config.filters) {
            Object.keys(this.config.filters).forEach((filterKey) => {
                const filterSelector = this.config.filters[filterKey];
                this.currentFilters[filterKey] = $(filterSelector).val() || '';
            });
        }
        
        // Load data with filters
        this.loadData(1, this.currentLimit, this.currentSearch, this.currentFilters);
    }
    
    handleSearch(searchTerm) {
        // Clear previous timeout
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        // Set new timeout for debounced search
        this.searchTimeout = setTimeout(() => {
            this.loadData(1, this.currentLimit, searchTerm, this.currentFilters);
        }, this.config.searchDelay);
    }
    
    async loadData(page = 1, limit = 20, search = '', filters = {}) {
        console.log(`Loading data: page=${page}, limit=${limit}, search="${search}", filters=`, filters);
        
        if (this.isLoading) {
            console.log('Already loading, skipping...');
            return;
        }
        
        this.isLoading = true;
        this.currentPage = page;
        this.currentLimit = limit;
        this.currentSearch = search;
        this.currentFilters = filters;
        
        // Show loading state
        this.showLoading();
        
        // Disable pagination controls (buttons should be disabled while loading)
        this.updatePaginationControls();
        
        try {
            console.log(`Making request to: ${this.config.apiUrl}`);
            
            // Build request data with filters and custom params
            const requestData = {
                page: page,
                limit: limit,
                search: search,
                sortBy: this.config.sortBy || 'created_at',
                sortOrder: this.config.sortOrder || 'DESC',
                ...this.config.customParams, // Always include fixed custom params
                ...filters // Spread filters into request data (can override customParams if needed)
            };
            
            const response = await $.ajax({
                method: "GET",
                url: this.config.apiUrl,
                data: requestData
            });
            
            console.log('Response received:', response);
            
            if (response.status === 200) {
                this.handleSuccess(response.data);
            } else {
                this.handleError('Invalid response from server');
            }
        } catch (error) {
            console.error('Pagination load error:', error);
            this.handleError('Failed to load data. Please try again.');
        } finally {
            this.isLoading = false;
            // Update controls after loading is complete
            this.updatePaginationControls();
        }
    }
    
    handleSuccess(data) {
        this.totalPages = data.pagination.totalPages;
        this.totalRecords = data.pagination.totalRecords;
        
        // Call custom data load handler
        this.config.onDataLoad(data);
    }
    
    handleError(message) {
        this.config.onError(message);
        this.updatePaginationControls();
    }
    
    showLoading() {
        // Override this method in child classes for specific loading UI
        console.log('Loading data...');
    }
    
    updatePaginationControls() {
        const container = $(`#${this.config.containerId}`);
        
        console.log(`Updating pagination controls: page=${this.currentPage}, totalPages=${this.totalPages}, isLoading=${this.isLoading}`);
        
        // Update pagination buttons
        const prevButton = container.find('.pagination-prev');
        const nextButton = container.find('.pagination-next');
        
        const prevDisabled = this.currentPage <= 1 || this.isLoading;
        const nextDisabled = this.currentPage >= this.totalPages || this.isLoading;
        
        prevButton.prop('disabled', prevDisabled);
        nextButton.prop('disabled', nextDisabled);
        
        console.log(`Buttons updated - Prev: ${prevDisabled ? 'disabled' : 'enabled'}, Next: ${nextDisabled ? 'disabled' : 'enabled'}`);
        
        // Update page info
        container.find('.pagination-page-info').text(`Page ${this.currentPage} of ${this.totalPages}`);
        container.find('.pagination-info').text(`Showing ${this.currentPage} of ${this.totalPages} pages (${this.totalRecords} total items)`);
        
        // Update search info
        container.find('.pagination-visible-count').text(this.currentSearch ? 'Filtered' : this.totalRecords);
        container.find('.pagination-total-count').text(this.totalRecords);
    }
    
    refresh() {
        this.loadData(this.currentPage, this.currentLimit, this.currentSearch, this.currentFilters);
    }
    
    reset() {
        this.currentPage = 1;
        this.currentLimit = this.config.pageSize;
        this.currentSearch = '';
        this.currentFilters = {};
        
        if (this.config.searchInputId) {
            $(this.config.searchInputId).val('');
        }
        
        // Reset filter selectors
        if (this.config.filters) {
            Object.keys(this.config.filters).forEach((filterKey) => {
                const filterSelector = this.config.filters[filterKey];
                $(filterSelector).val('');
            });
        }
        
        this.loadData(1, this.config.pageSize, '', {});
    }
}

/**
 * Inventory Pagination Manager - Specific implementation for inventory data
 */
class InventoryPaginationManager extends PaginationManager {
    constructor(config) {
        super({
            ...config,
            onDataLoad: config.onDataLoad || this.defaultDataLoadHandler.bind(this),
            onError: config.onError || this.defaultErrorHandler.bind(this)
        });
    }
    
    defaultDataLoadHandler(data) {
        const container = $(`#${this.config.containerId}`);
        const tbody = container.find('.pagination-table tbody');
        
        tbody.empty();
        
        if (data.items.length === 0) {
            tbody.html(`
                <tr>
                    <td colspan="100%" class="text-center">No data found</td>
                </tr>
            `);
        } else {
            // This should be overridden by the specific implementation
            console.log('Data loaded:', data.items.length, 'items');
        }
    }
    
    defaultErrorHandler(message) {
        const container = $(`#${this.config.containerId}`);
        const tbody = container.find('.pagination-table tbody');
        
        tbody.html(`
            <tr>
                <td colspan="100%" class="text-center text-danger">${message}</td>
            </tr>
        `);
    }
}

// Export for use in other files
window.PaginationManager = PaginationManager;
window.InventoryPaginationManager = InventoryPaginationManager;
