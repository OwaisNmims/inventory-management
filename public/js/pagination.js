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
            filters: config.filters || {},
            customParams: config.customParams || {},
            ...config
        };

        this.currentPage = 1;
        this.currentLimit = this.config.pageSize;
        this.currentSearch = '';
        this.currentFilters = {};
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
        if (this.config.searchInputId) {
            $(this.config.searchInputId).on('input', (e) => {
                const searchTerm = $(e.target).val().trim();
                this.handleSearch(searchTerm);
            });
        }

        const prevButton = $(`#${this.config.containerId} .pagination-prev`);
        const nextButton = $(`#${this.config.containerId} .pagination-next`);

        prevButton.on('click', () => {
            if (this.currentPage > 1) {
                this.loadData(this.currentPage - 1, this.currentLimit, this.currentSearch, this.currentFilters);
            }
        });

        nextButton.on('click', () => {
            if (this.currentPage < this.totalPages) {
                this.loadData(this.currentPage + 1, this.currentLimit, this.currentSearch, this.currentFilters);
            }
        });

        $(`#${this.config.containerId} .pagination-items-per-page`).on('change', (e) => {
            const newLimit = parseInt($(e.target).val());
            this.loadData(1, newLimit, this.currentSearch, this.currentFilters);
        });

        $(`#${this.config.containerId} .pagination-clear-search`).on('click', () => {
            if (this.config.searchInputId) {
                $(this.config.searchInputId).val('');
            }
            this.loadData(1, this.currentLimit, '');
        });

        if (this.config.filters) {
            Object.keys(this.config.filters).forEach((filterKey) => {
                const filterSelector = this.config.filters[filterKey];
                $(filterSelector).on('change', () => {
                    this.handleFilterChange();
                });
            });
        }
    }

    handleFilterChange() {
        if (this.config.filters) {
            Object.keys(this.config.filters).forEach((filterKey) => {
                const filterSelector = this.config.filters[filterKey];
                this.currentFilters[filterKey] = $(filterSelector).val() || '';
            });
        }
        this.loadData(1, this.currentLimit, this.currentSearch, this.currentFilters);
    }

    handleSearch(searchTerm) {
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        this.searchTimeout = setTimeout(() => {
            this.loadData(1, this.currentLimit, searchTerm, this.currentFilters);
        }, this.config.searchDelay);
    }

    async loadData(page = 1, limit = 20, search = '', filters = {}) {
        if (this.isLoading) return;

        this.isLoading = true;
        this.currentPage = page;
        this.currentLimit = limit;
        this.currentSearch = search;
        this.currentFilters = filters;

        this.showLoading();
        this.updatePaginationControls();

        try {
            const requestData = {
                page: page,
                limit: limit,
                search: search,
                sortBy: this.config.sortBy || 'created_at',
                sortOrder: this.config.sortOrder || 'DESC',
                ...this.config.customParams,
                ...filters
            };

            const response = await $.ajax({
                method: "GET",
                url: this.config.apiUrl,
                data: requestData
            });

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
            this.updatePaginationControls();
        }
    }

    handleSuccess(data) {
        this.totalPages = data.pagination.totalPages;
        this.totalRecords = data.pagination.totalRecords;
        this.config.onDataLoad(data);
    }

    handleError(message) {
        this.config.onError(message);
        this.updatePaginationControls();
    }

    showLoading() {}

    updatePaginationControls() {
        const container = $(`#${this.config.containerId}`);

        const prevButton = container.find('.pagination-prev');
        const nextButton = container.find('.pagination-next');

        prevButton.prop('disabled', this.currentPage <= 1 || this.isLoading);
        nextButton.prop('disabled', this.currentPage >= this.totalPages || this.isLoading);

        container.find('.pagination-page-info').text(`Page ${this.currentPage} of ${this.totalPages}`);
        container.find('.pagination-info').text(`Showing ${this.currentPage} of ${this.totalPages} pages (${this.totalRecords} total items)`);
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
            tbody.html(`<tr><td colspan="100%" class="text-center">No data found</td></tr>`);
        }
    }

    defaultErrorHandler(message) {
        const container = $(`#${this.config.containerId}`);
        const tbody = container.find('.pagination-table tbody');
        tbody.html(`<tr><td colspan="100%" class="text-center text-danger">${message}</td></tr>`);
    }
}

window.PaginationManager = PaginationManager;
window.InventoryPaginationManager = InventoryPaginationManager;
