document.addEventListener("DOMContentLoaded", function () {
  const searchInputs = Array.from(document.querySelectorAll("[data-manage-search]"));

  searchInputs.forEach((input) => {
    const scope = input.closest("[data-manage-search-scope]");
    if (!scope) return;

    const items = Array.from(scope.querySelectorAll("[data-manage-search-item]"));
    const emptyState = scope.querySelector("[data-manage-empty-state]");
    const visibleCount = scope.querySelector("[data-manage-visible-count]");
    const primaryItems = Array.from(scope.querySelectorAll("[data-manage-search-primary]"));
    const countItems = primaryItems.length ? primaryItems : items;

    function getSearchText(item) {
      return (item.dataset.manageSearchText || item.textContent || "").toLowerCase();
    }

    function filterItems() {
      const query = input.value.trim().toLowerCase();

      items.forEach((item) => {
        item.hidden = Boolean(query) && !getSearchText(item).includes(query);
      });

      const matchedCount = countItems.filter((item) => !item.hidden).length;

      if (visibleCount) {
        visibleCount.textContent = String(matchedCount);
      }

      if (emptyState) {
        emptyState.hidden = !query || matchedCount > 0;
      }
    }

    // Debounce: wait 150ms after last keystroke before filtering (smoother on mobile)
    var debounceTimer;
    input.addEventListener("input", function () {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(filterItems, 150);
    });
    filterItems();
  });
});
