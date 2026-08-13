/**
 * Helpers cryptographiques partagés pour l'API partenaires (clés API + signature webhook).
 */
const crypto = require('crypto');

const API_KEY_PREFIX = 'sk_live_';

/**
 * Génère une nouvelle clé API en clair (à ne renvoyer qu'une seule fois à l'appelant).
 */
function generateApiKey() {
  const randomPart = crypto.randomBytes(24).toString('base64url');
  return `${API_KEY_PREFIX}${randomPart}`;
}

/**
 * Hash déterministe d'une clé API pour stockage/lookup (jamais la clé en clair).
 */
function hashApiKey(plainKey) {
  return crypto.createHash('sha256').update(plainKey).digest('hex');
}

/**
 * Segment non sensible affiché dans l'UI admin pour identifier une clé sans la révéler.
 */
function apiKeyPrefixFor(plainKey) {
  return plainKey.slice(0, API_KEY_PREFIX.length + 6);
}

function generateWebhookSecret() {
  return crypto.randomBytes(32).toString('hex');
}

function signWebhookPayload(secret, rawBody) {
  return crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
}

module.exports = {
  API_KEY_PREFIX,
  generateApiKey,
  hashApiKey,
  apiKeyPrefixFor,
  generateWebhookSecret,
  signWebhookPayload,
};
