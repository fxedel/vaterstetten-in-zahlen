window.addEventListener('popstate', () => {
    const params = new URLSearchParams(window.location.search);
    const tab = params.get('tab') ?? 'main';
    Shiny.setInputValue('tab', tab);
});

document.addEventListener('DOMContentLoaded', () => {
    preventWidgetsFromRendering();

    const logo = document.querySelector('.logo');
    logo.addEventListener('click', () => {
        Shiny.setInputValue('logo', 1, {priority: 'event'});
    })
    console.log(logo, 'listener added')
});

$(document).on('shiny:connected', event => {
    renderVisibleWidgets();
});

$(document).on('shiny:inputchanged', event => {
    if (event.name === 'sidebarCollapsed') {
        window.dispatchEvent(new CustomEvent("resize"));
    } else if (event.name === 'tab') {
        renderVisibleWidgets();
        document.body.parentElement.scrollTo(0, 0);

        if (document.body.classList.contains('sidebar-open')) {
            document.body.classList.remove('sidebar-open')
        }
    }
});

$(document).on('shiny:disconnected', event => {
    // reload page after 10s
    setTimeout(() => {
        location.reload();
    }, 10*1000);
});

function preventWidgetsFromRendering() {
    const widgets = document.querySelectorAll('.html-widget');

    for (const widget of widgets) {
        if (!widget.classList.contains('html-widget-static-bound')) {
            // html-widget-static-bound will prevent HTMLWidgets.staticRender() from rendering this widget,
            // since html-widget-static-bound is actually the class for already rendered widgets.
            // We also add not-yet-rendered so we know the widget has actually been prevented from rendering.
            widget.classList.add('html-widget-static-bound', 'not-yet-rendered');
        }
    }
}

function renderVisibleWidgets() {
    const activeWidgets = document.querySelectorAll('.tab-pane.active .html-widget');

    var renderNeeded = false;
    
    for (const widget of activeWidgets) {
        if (widget.classList.contains('not-yet-rendered')) {
            widget.classList.remove('html-widget-static-bound', 'not-yet-rendered');
            renderNeeded = true;
        }
    }

    if (renderNeeded) {
        // wait some millis, so a new tab page can be shown without the blocking call to staticRender()
        setTimeout(async () => {
            window.HTMLWidgets.staticRender();
        }, 20);
    }
}
