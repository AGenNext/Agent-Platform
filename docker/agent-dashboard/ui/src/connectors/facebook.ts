import type { SocialComment, SocialProvider } from './types'

// Facebook provider.
// Live mode activates ONLY when the app supplies these at build/runtime:
//   VITE_FB_TOKEN   — a user/page access token (obtained via client-side OAuth)
//   VITE_FB_PAGE_ID — the page/asset whose feed comments to read
// Until then it returns mock data. The Graph API only ever returns
// user-consented data for assets the token is authorized on — never
// "everyone's data".
const GRAPH = 'https://graph.facebook.com/v19.0'
const TOKEN = import.meta.env.VITE_FB_TOKEN as string | undefined
const PAGE_ID = import.meta.env.VITE_FB_PAGE_ID as string | undefined

const MOCK: SocialComment[] = [
  { id: 'fb_1', provider: 'facebook', author: 'Priya Raman', text: 'Does the agent pipeline support our RFP template out of the box?', target: 'Post · Q3 launch', createdAt: '2026-06-14T09:12:00Z', likes: 4 },
  { id: 'fb_2', provider: 'facebook', author: 'Marcus Lee', text: 'Loving the new dashboard — when is the gateway cost view shipping?', target: 'Post · Product update', createdAt: '2026-06-14T08:40:00Z', likes: 11 },
  { id: 'fb_3', provider: 'facebook', author: 'Dana Okafor', text: 'Can agents reply to these comments automatically with a human gate?', target: 'Post · AMA', createdAt: '2026-06-13T17:05:00Z', likes: 2 },
]

interface GraphComment { id: string; message?: string; from?: { name?: string }; created_time?: string; like_count?: number }
interface GraphFeedItem { id: string; message?: string; story?: string; comments?: { data: GraphComment[] } }
interface GraphFeed { data?: GraphFeedItem[] }

function normalize(feed: GraphFeed): SocialComment[] {
  const out: SocialComment[] = []
  for (const post of feed.data ?? []) {
    const target = post.message ?? post.story ?? `Post ${post.id}`
    for (const c of post.comments?.data ?? []) {
      out.push({
        id: c.id,
        provider: 'facebook',
        author: c.from?.name ?? 'Unknown',
        text: c.message ?? '',
        target,
        createdAt: c.created_time ?? new Date().toISOString(),
        likes: c.like_count,
      })
    }
  }
  return out
}

export const facebookProvider: SocialProvider = {
  id: 'facebook',
  name: 'Facebook',
  description: 'Comments on pages & posts your access token is authorized on (consented data via Graph API).',
  status: TOKEN && PAGE_ID ? 'connected' : 'mock',
  async listComments() {
    if (!TOKEN || !PAGE_ID) return MOCK
    const url = `${GRAPH}/${PAGE_ID}/feed?fields=message,story,comments{message,from,created_time,like_count}&access_token=${TOKEN}`
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Graph API ${res.status}`)
    return normalize(await res.json())
  },
}
