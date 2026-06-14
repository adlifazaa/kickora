'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeArticles } = require('../src/newsProvider');

test('normalizeArticles maps NewsAPI payload to Kickora shape', () => {
  const articles = normalizeArticles({
    articles: [
      {
        source: { name: 'BBC Sport' },
        title: 'World Cup 2026 draw',
        description: 'Summary line',
        url: 'https://example.com/a',
        urlToImage: 'https://example.com/img.jpg',
        publishedAt: '2026-06-11T10:00:00Z',
      },
      {
        source: { name: 'Removed' },
        title: '[Removed]',
        url: 'https://example.com/b',
      },
    ],
  });

  assert.equal(articles.length, 1);
  assert.equal(articles[0].title, 'World Cup 2026 draw');
  assert.equal(articles[0].source, 'BBC Sport');
  assert.equal(articles[0].summary, 'Summary line');
  assert.equal(articles[0].url, 'https://example.com/a');
  assert.equal(articles[0].imageUrl, 'https://example.com/img.jpg');
  assert.equal(articles[0].publishedAt, '2026-06-11T10:00:00Z');
  assert.ok(articles[0].id.length > 0);
});

test('normalizeArticles deduplicates by url', () => {
  const articles = normalizeArticles({
    articles: [
      { title: 'A', url: 'https://example.com/x' },
      { title: 'B', url: 'https://example.com/x' },
    ],
  });
  assert.equal(articles.length, 1);
});
