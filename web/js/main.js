/* ===================================================================
 * Rockville Tolland SDA Church 1.0.0 - Main JS
 *
 * ------------------------------------------------------------------- */

const cfg = {
    scrollDuration : 800, // smoothscroll duration
    mailChimpURL   : ''   // mailchimp url
};

// Add the User Agent to the <html>
// will be used for IE10/IE11 detection (Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0; rv:11.0))
const doc = document.documentElement;
doc.setAttribute('data-useragent', navigator.userAgent);

/* Preloader
 * -------------------------------------------------- */
const ssPreloader = function() {
    const preloader = document.querySelector('#preloader');
    if (!preloader) return;

    // Remove preloader once everything is loaded
    function removePreloader() {
        document.body.classList.remove('ss-preload');
        document.body.classList.add('ss-loaded');
    }

    // If not first visit, remove preloader immediately
    if (sessionStorage.getItem('hasVisited')) {
        removePreloader();
        return;
    }

    // Remove preloader after a longer timeout for splash screen
    setTimeout(removePreloader, 3000);

    // Also remove preloader on normal load event, but with a delay
    window.addEventListener('load', function() {
        if (!sessionStorage.getItem('hasVisited')) {
            setTimeout(removePreloader, 3000);
        }
    });

    // force page scroll position to top at page refresh
    window.addEventListener('beforeunload', function () {
        window.scrollTo(0, 0);
    });
};

/* Mobile Menu
 * ---------------------------------------------------- */ 
const ssMobileMenu = function() {
    const toggleButton = document.querySelector('.header-menu-toggle');
    const headerNavWrap = document.querySelector('.header-nav-wrap');
    const siteBody = document.querySelector("body");

    if (!(toggleButton && headerNavWrap)) return;

    toggleButton.addEventListener('click', function(event) {
        event.preventDefault();
        toggleButton.classList.toggle('is-clicked');
        siteBody.classList.toggle('menu-is-open');
    });

    headerNavWrap.querySelectorAll('.header-nav a').forEach(function(link) {
        link.addEventListener('click', function(evt) {
            // at 800px and below
            if (window.matchMedia('(max-width: 800px)').matches) {
                toggleButton.classList.toggle('is-clicked');
                siteBody.classList.toggle('menu-is-open');
            }
        });
    });

    window.addEventListener('resize', function() {
        // above 800px
        if (window.matchMedia('(min-width: 801px)').matches) {
            if (siteBody.classList.contains('menu-is-open')) siteBody.classList.remove('menu-is-open');
            if (toggleButton.classList.contains("is-clicked")) toggleButton.classList.remove("is-clicked");
        }
    });
};

/* Alert Boxes
 * ------------------------------------------------------ */
const ssAlertBoxes = function() {

    document.querySelectorAll('.alert-box').forEach(function(alertBox) {
        alertBox.querySelector('.alert-box__close').addEventListener('click', function() {
            alertBox.style.display = 'none';
        });
    });

};

/* Smooth Scrolling
 * ------------------------------------------------------ */
const ssSmoothScroll = function() {
    
    document.querySelectorAll('.smoothscroll').forEach(function(anchor) {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            
            const target = document.querySelector(this.getAttribute('href'));
            if (!target) return;

            const offset = Math.floor(target.offsetTop);

            window.scrollTo({
                top: offset,
                left: 0,
                behavior: 'smooth'
            });
        });
    });
};

/* Back to Top
 * ------------------------------------------------------ */
const ssBackToTop = function() {

    const pxShow      = 500;
    const $goTopButton = document.querySelector(".ss-go-top")

    // Show or hide the button
    if (window.scrollY >= pxShow) $goTopButton.classList.add('link-is-visible');

    window.addEventListener('scroll', function() {
        if (window.scrollY >= pxShow) {
            if(!$goTopButton.classList.contains('link-is-visible')) $goTopButton.classList.add('link-is-visible')
        } else {
            $goTopButton.classList.remove('link-is-visible')
        }
    });
};

/* Initialize
 * ------------------------------------------------------ */
(function ssInit() {

    ssPreloader();
    ssMobileMenu();
    ssAlertBoxes();
    ssSmoothScroll();
    ssBackToTop();

})();
