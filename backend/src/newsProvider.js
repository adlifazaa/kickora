'use strict';

const config = require('./config');

const WC_QUERY =
  '"FIFA World Cup" OR "World Cup 2026" OR "World Cup" host OR FIFA announcement';
const FOOTBALL_FALLBACK_QUERY =
  'international football OR "national team" OR soccer world cup';

/**
 * @param {string} query
 * @param {number} pageSize
 * @returns {Promise<object|null>}
 */
async function fetchNewsApi(query, pageSize = 15) {
  const key = config.newsApiKey;
  if (!key) return null;

  const url = new URL('https://newsapi.org/v2/everything');
  url.searchParams.set('q', query);
  url.searchParams.set('language', 'en');
  url.searchParams.set('sortBy', 'publishedAt');
  url.searchParams.set('pageSize', String(pageSize));

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15_000);

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: { 'X-Api-Key': key },
      signal: controller.signal,
    });

    const text = await res.text();
    let body;
    try {
      body = text ? JSON.parse(text) : {};
    } catch {
      const err = new Error('Invalid JSON from NewsAPI');
      err.statusCode = 502;
      throw err;
    }

    if (res.status === 401 || res.status === 403) {
      const err = new Error('NewsAPI unauthorized');
      err.statusCode = 503;
      err.code = 'news_not_configured';
      throw err;
    }

    if (res.status === 429) {
      const err = new Error('NewsAPI rate limit');
      err.statusCode = 429;
      throw err;
    }

    if (!res.ok) {
      const err = new Error(`NewsAPI HTTP ${res.status}`);
      err.statusCode = res.status >= 500 ? 502 : res.status;
      throw err;
    }

    if (body.status && body.status !== 'ok') {
      const err = new Error(body.message || 'NewsAPI error');
      err.statusCode = 502;
      throw err;
    }

    return body;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * @param {object} body
 * @returns {Array<object>}
 */
function normalizeArticles(body) {
  if (!body || !Array.isArray(body.articles)) return [];

  const seen = new Set();
  const out = [];

  for (const article of body.articles) {
    if (!article || !article.url) continue;
    const title = (article.title || '').trim();
    if (!title || title === '[Removed]') continue;
    if (seen.has(article.url)) continue;
    seen.add(article.url);

    out.push({
      id: Buffer.from(article.url).toString('base64url').slice(0, 40),
      title,
      summary: (article.description || '').trim(),
      source: article.source?.name?.trim() || '',
      imageUrl: (article.urlToImage || '').trim(),
      url: article.url.trim(),
      publishedAt: article.publishedAt || '',
    });
  }

  return out;
}

async function fetchWorldCupNews() {
  if (!config.newsApiKey) {
    return {
      configured: false,
      fallback: false,
      articles: [],
    };
  }

  const wcBody = await fetchNewsApi(WC_QUERY, 20);
  let articles = normalizeArticles(wcBody);
  let fallback = false;

  if (articles.length < 3) {
    const fbBody = await fetchNewsApi(FOOTBALL_FALLBACK_QUERY, 20);
    const fbArticles = normalizeArticles(fbBody);
    if (fbArticles.length > 0) {
      articles = fbArticles;
      fallback = true;
    }
  }

  return {
    configured: true,
    fallback,
    articles,
  };
}

module.exports = {
  fetchWorldCupNews,
  normalizeArticles,
};
