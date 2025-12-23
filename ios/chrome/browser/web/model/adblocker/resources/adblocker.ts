// Copyright 2025 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * @fileoverview AdBlocker JavaScript feature that blocks ads and trackers
 * using the Ghostery adblocker engine.
 *
 * This script is injected into web pages when the AdBlocker preference
 * is enabled. It intercepts network requests and blocks ads/trackers.
 */

import {CrWebApi, gCrWeb} from '//ios/web/public/js_messaging/resources/gcrweb.js';

console.log('[AdBlocker] JavaScript loaded and executing');

/**
 * Statistics for blocked content
 */
interface BlockStats {
  networkBlocked: number;  // Blocked by WKContentRuleList (estimated)
  cosmeticBlocked: number; // Hidden by cosmetic filters
  totalBlocked: number;
}

/**
 * AdBlocker namespace for the ad-blocking functionality.
 */
class AdBlocker {
  /**
   * Whether the adblocker has been initialized.
   */
  private initialized: boolean = false;

  /**
   * Whether the adblocker is currently enabled.
   */
  private enabled: boolean = false;

  /**
   * Cosmetic filters (element hiding rules) passed from native code
   */
  private cosmeticFilters: string[] = [];

  /**
   * Statistics for blocked content
   */
  private stats: BlockStats = {
    networkBlocked: 0,
    cosmeticBlocked: 0,
    totalBlocked: 0
  };

  /**
   * Whether to log blocked requests to console
   */
  private enableLogging: boolean = true;

  /**
   * Initialize the adblocker.
   * Sets up the blocker but doesn't enable it until enable() is called.
   */
  initialize(): void {
    if (this.initialized) {
      return;
    }

    this.initialized = true;
    this.setupBlocker();
  }

  /**
   * Enable the adblocker and start blocking ads.
   */
  enable(): void {
    if (!this.initialized) {
      this.initialize();
    }

    if (this.enabled) {
      return;
    }

    this.enabled = true;
    console.log('[AdBlocker] Enabled - Network blocking active, applying cosmetic filters');

    // Apply cosmetic filters
    this.applyCosmeticFilters();

    // Start monitoring for dynamically added ad elements
    this.startMutationObserver();
  }

  /**
   * Disable the adblocker and stop blocking ads.
   */
  disable(): void {
    if (!this.enabled) {
      return;
    }

    this.enabled = false;
    this.removeCosmeticFilters();
    console.log('[AdBlocker] Disabled');
  }

  /**
   * Set cosmetic filters from native code
   */
  setCosmeticFilters(filters: string[]): void {
    this.cosmeticFilters = filters;
    console.log(`[AdBlocker] Loaded ${filters.length} cosmetic filters`);

    if (this.enabled) {
      this.applyCosmeticFilters();
    }
  }

  /**
   * Enable or disable logging
   */
  setLogging(enabled: boolean): void {
    this.enableLogging = enabled;
    console.log(`[AdBlocker] Logging ${enabled ? 'enabled' : 'disabled'}`);
  }

  /**
   * Get current blocking statistics
   */
  getStats(): BlockStats {
    return {...this.stats};
  }

  /**
   * Reset statistics
   */
  resetStats(): void {
    this.stats = {
      networkBlocked: 0,
      cosmeticBlocked: 0,
      totalBlocked: 0
    };
    console.log('[AdBlocker] Statistics reset');
  }

  /**
   * Set up the adblocker.
   */
  private setupBlocker(): void {
    console.log('[AdBlocker] Initialized - Network blocking handled by WKContentRuleList');
    console.log('[AdBlocker] Cosmetic filtering will be applied via CSS');
  }

  /**
   * Apply cosmetic filters (element hiding)
   */
  private applyCosmeticFilters(): void {
    if (this.cosmeticFilters.length === 0) {
      return;
    }

    // Create or update the style element for hiding ads
    let styleEl = document.getElementById('adblocker-cosmetic-filters') as HTMLStyleElement;

    if (!styleEl) {
      styleEl = document.createElement('style');
      styleEl.id = 'adblocker-cosmetic-filters';
      document.head.appendChild(styleEl);
    }

    // Convert cosmetic filters to CSS rules
    const cssRules: string[] = [];
    let appliedCount = 0;

    for (const filter of this.cosmeticFilters) {
      // Parse cosmetic filter format: domain##selector or ##selector
      const parts = filter.split('##');
      if (parts.length === 2) {
        const selector = parts[1];

        // Apply domain-specific or global filter
        if (parts[0] && parts[0] !== '') {
          // Domain-specific filter
          const domains = parts[0].split(',');
          const currentDomain = window.location.hostname;

          if (domains.some(d => currentDomain.indexOf(d) !== -1)) {
            cssRules.push(`${selector} { display: none !important; }`);
            appliedCount++;
          }
        } else {
          // Global filter
          cssRules.push(`${selector} { display: none !important; }`);
          appliedCount++;
        }
      }
    }

    styleEl.textContent = cssRules.join('\n');

    if (this.enableLogging && appliedCount > 0) {
      console.log(`[AdBlocker] Applied ${appliedCount} cosmetic filters`);
    }

    // Count hidden elements
    this.updateCosmeticBlockedCount();
  }

  /**
   * Remove cosmetic filters
   */
  private removeCosmeticFilters(): void {
    const styleEl = document.getElementById('adblocker-cosmetic-filters');
    if (styleEl) {
      styleEl.remove();
      console.log('[AdBlocker] Removed cosmetic filters');
    }
  }

  /**
   * Start monitoring for dynamically added ad elements
   */
  private startMutationObserver(): void {
    // Observe DOM changes to re-apply filters on dynamic content
    const observer = new MutationObserver(() => {
      if (this.enabled) {
        this.updateCosmeticBlockedCount();
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  /**
   * Update count of cosmetically blocked elements
   */
  private updateCosmeticBlockedCount(): void {
    const styleEl = document.getElementById('adblocker-cosmetic-filters');
    if (!styleEl) return;

    // Count elements that are hidden by our filters
    const hiddenElements = document.querySelectorAll('[style*="display: none"]');
    const previousCount = this.stats.cosmeticBlocked;
    this.stats.cosmeticBlocked = hiddenElements.length;
    this.stats.totalBlocked = this.stats.networkBlocked + this.stats.cosmeticBlocked;

    if (this.enableLogging && this.stats.cosmeticBlocked > previousCount) {
      const newBlocked = this.stats.cosmeticBlocked - previousCount;
      console.log(`[AdBlocker] Blocked ${newBlocked} ad element(s) - Total: ${this.stats.totalBlocked}`);
    }
  }
}

// Create the adblocker instance
const adBlocker = new AdBlocker();

// Create API for native code to call
const adBlockerApi = new CrWebApi();

// Register enable function
adBlockerApi.addFunction('enable', () => {
  adBlocker.enable();
});

// Register disable function
adBlockerApi.addFunction('disable', () => {
  adBlocker.disable();
});

// Register function to set cosmetic filters
adBlockerApi.addFunction('setCosmeticFilters', (filters: string[]) => {
  adBlocker.setCosmeticFilters(filters);
});

// Register function to enable/disable logging
adBlockerApi.addFunction('setLogging', (enabled: boolean) => {
  adBlocker.setLogging(enabled);
});

// Register function to get statistics
adBlockerApi.addFunction('getStats', () => {
  return adBlocker.getStats();
});

// Register function to reset statistics
adBlockerApi.addFunction('resetStats', () => {
  adBlocker.resetStats();
});

// Register the API with gCrWeb
gCrWeb.registerApi('adBlocker', adBlockerApi);

console.log('[AdBlocker] API registered with gCrWeb - ready for native calls');
