'use strict';

/**
 * Ring buffer of dry-run / would-send log entries for admin inspection.
 */
class DryRunLog {
  /**
   * @param {number} maxEntries
   */
  constructor(maxEntries = 200) {
    this._max = maxEntries;
    /** @type {object[]} */
    this._entries = [];
  }

  /**
   * @param {object} entry
   */
  append(entry) {
    this._entries.push({
      ...entry,
      loggedAt: new Date().toISOString(),
    });
    if (this._entries.length > this._max) {
      this._entries.splice(0, this._entries.length - this._max);
    }
  }

  /**
   * @param {number} [limit]
   */
  list(limit) {
    const n = limit == null ? this._entries.length : Math.max(0, limit);
    return this._entries.slice(-n).reverse();
  }

  clear() {
    this._entries = [];
  }

  get size() {
    return this._entries.length;
  }
}

module.exports = { DryRunLog };
