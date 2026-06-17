import type { SocialComment, SocialProvider } from './types'

// Facebook provider.
//
// Security/governance: the browser NEVER holds the Graph access token. Live
// comments are fetched through a SurrealDB-governed endpoint that stores the
// token server-side, enforces per-user authorization, and pins a supported
// Graph API version server-side (configurable, not hardcoded in the client).
// Until that endpoint returns data, the provider serves mock data.
//
// The Graph API only ever exposes data the token is authorized on (pages/posts
// you administer) — never "everyone's data".
const ENDPOINT = '/api/connectors/facebook/comments'

const MOCK: SocialComment[] = [
  { id: 'fb_1', provider: 'facebook', author: 'Priya Raman', text: 'Does the agent pipeline support our RFP template out of the box?', target: 'Post · Q3 launch', createdAt: '2026-06-14T09:12:00Z', likes: 4 },
  { id: 'fb_2', provider: 'facebook', author: 'Marcus Lee', text: 'Loving the new dashboard — when is the gateway cost view shipping?', target: 'Post · Product update', createdAt: '2026-06-14T08:40:00Z', likes: 11 },
  { id: 'fb_3', provider: 'facebook', author: 'Dana Okafor', text: 'Can agents reply to these comments automatically with a human gate?', target: 'Post · AMA', createdAt: '2026-06-13T17:05:00Z', likes: 2 },
]

export const facebookProvider: SocialProvider = {
  id: 'facebook',
  name: 'Facebook',
  description: 'Comments on pages & posts you administer (consented data via a server-governed Graph token).',
  status: 'mock',
  async listComments() {
    try {
      const res = await fetch(ENDPOINT)
      if (!res.ok) return MOCK
      const data = (await res.json()) as SocialComment[]
      return Array.isArray(data) && data.length ? data : MOCK
    } catch {
      return MOCK
    }
  },
}
