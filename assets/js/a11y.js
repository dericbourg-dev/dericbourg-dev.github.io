/**
 * Accessibility enhancements for WCAG 2.2 AA compliance
 */

(function() {
  'use strict';

  /**
   * Enhance theme switcher for keyboard accessibility
   * WCAG 2.1.1 Keyboard, 4.1.2 Name/Role/Value
   */
  function enhanceThemeSwitcher() {
    const themeSwitcher = document.querySelector('.themeswitch a');
    if (!themeSwitcher) return;

    // Add proper ARIA attributes
    themeSwitcher.setAttribute('role', 'button');
    themeSwitcher.setAttribute('tabindex', '0');

    // Set accessible label based on current theme
    function updateAriaLabel() {
      const isDark = document.documentElement.classList.contains('theme--dark');
      const lang = document.documentElement.lang;

      if (lang === 'fr') {
        themeSwitcher.setAttribute('aria-label',
          isDark ? 'Passer au thème clair' : 'Passer au thème sombre'
        );
      } else {
        themeSwitcher.setAttribute('aria-label',
          isDark ? 'Switch to light theme' : 'Switch to dark theme'
        );
      }
    }

    updateAriaLabel();

    // Handle keyboard events (Enter and Space)
    themeSwitcher.addEventListener('keydown', function(event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        themeSwitcher.click();
        // Update label after theme change
        setTimeout(updateAriaLabel, 100);
      }
    });

    // Update label when theme changes via click
    themeSwitcher.addEventListener('click', function() {
      setTimeout(updateAriaLabel, 100);
    });
  }

  /**
   * Enhance language picker for better keyboard navigation
   * WCAG 2.1.1 Keyboard
   */
  function enhanceLanguagePicker() {
    const languageLabel = document.querySelector('.optionswitch__label');
    const languagePicker = document.querySelector('#languagepicker');

    if (!languageLabel || !languagePicker) return;

    // Add ARIA attributes to label
    languageLabel.setAttribute('role', 'button');
    languageLabel.setAttribute('aria-expanded', 'false');
    languageLabel.setAttribute('aria-haspopup', 'listbox');

    // Update aria-expanded when checkbox changes
    languagePicker.addEventListener('change', function() {
      languageLabel.setAttribute('aria-expanded', this.checked ? 'true' : 'false');
    });

    // Allow Escape to close
    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape' && languagePicker.checked) {
        languagePicker.checked = false;
        languageLabel.setAttribute('aria-expanded', 'false');
        languageLabel.focus();
      }
    });
  }

  /**
   * Ensure hamburger menu is keyboard accessible
   * WCAG 2.1.1 Keyboard
   */
  function enhanceHamburgerMenu() {
    const burger = document.querySelector('.navbar-burger');
    if (!burger) return;

    burger.addEventListener('keydown', function(event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        burger.click();
      }
    });
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  function init() {
    enhanceThemeSwitcher();
    enhanceLanguagePicker();
    enhanceHamburgerMenu();
  }
})();
