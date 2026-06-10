'use strict';

/**
 * In-memory deduplication store with TTL.
 * Swap for Redis/DB later by implementing the same interface.
 */
class DedupStore {
  /**
   * @param {{ ttlSeconds?: number, now?: () => number }} [options]
   */
  constructor(options = {}) {
    this._ttlMs = (options.ttlSeconds ?? 6 * 60 * 60) * 1000;
    this._now = options.now ?? (() => Date.now());
    /** @type {Map<string, number>} */
    this._entries = new Map();
  }

  /**
   * @param {string} key
   * @returns {boolean} true if this key was not seen recently (caller should send)
   */
  tryClaim(key) {
    this._purgeExpired();
    if (this._entries.has(key)) return false;
    this._entries.set(key, this._now() + this._ttlMs);
    return true;
  }

  has(key) {
    this._purgeExpired();
    return this._entries.has(key);
  }

  size() {
    this._purgeExpired();
    return this._entries.size;
  }

  clear() {
    this._entries.clear();
  }

  _purgeExpired() {
    const now = this._now();
    for (const [key, expiresAt] of this._entries) {
      if (now >= expiresAt) this._entries.delete(key);
    }
  }
}

/**
 * Stable dedup key for a notification event.
 * @param {{
 *   fixtureId: number|string,
 *   type: string,
 *   minute?: string|number,
 *   teamId?: number|string,
 *   playerId?: number|string,
 *   score?: string,
 * }} parts
 */
function buildDedupKey(parts) {
  const fixtureId = `${parts.fixtureId ?? ''}`;
  const type = `${parts.type ?? ''}`;
  const minute = `${parts.minute ?? ''}`;
  const teamId = `${parts.teamId ?? ''}`;
  const playerId = `${parts.playerId ?? ''}`;
  const score = `${parts.score ?? ''}`;
  return `${fixtureId}:${type}:${minute}:${teamId}:${playerId}:${score}`;
}

/**
 * Per-topic send key — same logical event may fan out to multiple topics once each.
 * @param {string} eventKey
 * @param {string} topic
 */
function buildTopicSendKey(eventKey, topic) {
  return `${eventKey}@${topic}`;
}

module.exports = { DedupStore, buildDedupKey, buildTopicSendKey };
