$(document).on('shiny:inputchanged', function(event) {
    if (event.name === 'sidebarCollapsed') {
        window.dispatchEvent(new CustomEvent("resize"));
    }
});

$(document).on('shiny:disconnected', function(event) {
    // reload page after 10s
    setTimeout(() => {
        location.reload();
    }, 10*1000);
});
