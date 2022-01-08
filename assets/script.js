$(document).on('shiny:inputchanged', function(event) {
    if (event.name === 'sidebarCollapsed') {
        window.dispatchEvent(new CustomEvent("resize"));
    }
});
