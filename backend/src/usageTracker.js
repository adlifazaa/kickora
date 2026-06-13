'use strict';

/**
 * In-memory daily counters for upstream API-Football usage and proxy cache stats.
 * Resets at UTC midnight. No secrets stored.
 */
class UsageTracker {
  constructor() {
    this._dayKey = this._todayKey();
    /** @type {Map<string, number>} */
    this._upstreamByRoute = new Map();
    /** @type {Map<string, number>} */
    this._upstreamByPattern = new Map();
    /** @type {Map<string, number>} */
    this._cacheHits = new Map();
    /** @type {Map<string, number>} */
    this._cacheMisses = new Map();
    this._workerEventCallsToday = 0;
    this._workerLiveCallsToday = 0;
  }

  _todayKey() {
    return new Date().toISOString().slice(0, 10);
  }

  _rollDayIfNeeded() {
    const today = this._todayKey();
    if (today === this._dayKey) return;
    this._dayKey = today;
    this._upstreamByRoute.clear();
    this._upstreamByPattern.clear();
    this._cacheHits.clear();
    this._cacheMisses.clear();
    this._workerEventCallsToday = 0;
    this._workerLiveCallsToday = 0;
  }

  /**
   * @param {{ callerRoute?: string, urlPattern?: string, source?: string }} meta
   */
  recordUpstream(meta = {}) {
    this._rollDayIfNeeded();
    const route = meta.callerRoute || 'unknown';
    const pattern = meta.urlPattern || 'unknown';
    const source = meta.source || 'proxy';

    this._upstreamByRoute.set(route, (this._upstreamByRoute.get(route) || 0) + 1);
    this._upstreamByPattern.set(
      pattern,
      (this._upstreamByPattern.get(pattern) || 0) + 1,
    );

    if (source === 'notification-worker') {
      if (pattern.includes('/fixtures/events')) {
        this._workerEventCallsToday += 1;
      } else if (pattern.includes('/fixtures')) {
        this._workerLiveCallsToday += 1;
      }
    }

    console.log(
      `[kickora-usage] upstream source=${source} route=${route} pattern=${pattern} dailyTotal=${this.totalUpstreamToday()}`,
    );
  }

  recordCache(route, hit) {
    this._rollDayIfNeeded();
    const map = hit ? this._cacheHits : this._cacheMisses;
    map.set(route, (map.get(route) || 0) + 1);
  }

  totalUpstreamToday() {
    let total = 0;
    for (const n of this._upstreamByRoute.values()) total += n;
    return total;
  }

  isProtectionActive(threshold) {
    if (!threshold || threshold <= 0) return false;
    return this.totalUpstreamToday() >= threshold;
  }

  _mapToObject(map) {
    const out = {};
    for (const [k, v] of map) out[k] = v;
    return out;
  }

  getStatus({ dailyThreshold, pollSeconds, protectionPollSeconds }) {
    this._rollDayIfNeeded();
    const upstreamTotal = this.totalUpstreamToday();
    const protectionActive = this.isProtectionActive(dailyThreshold);

    return {
      date: this._dayKey,
      upstreamTotal,
      dailyThreshold: dailyThreshold || null,
      protectionActive,
      effectivePollSeconds: protectionActive ? protectionPollSeconds : pollSeconds,
      upstreamByRoute: this._mapToObject(this._upstreamByRoute),
      upstreamByPattern: this._mapToObject(this._upstreamByPattern),
      cacheHits: this._mapToObject(this._cacheHits),
      cacheMisses: this._mapToObject(this._cacheMisses),
      worker: {
        liveCallsToday: this._workerLiveCallsToday,
        eventCallsToday: this._workerEventCallsToday,
      },
    };
  }
}

const usageTracker = new UsageTracker();

module.exports = { UsageTracker, usageTracker };
