// Provider-agnostic social connector layer.
// All providers normalize to a single SocialComment shape so the dashboard
// (and any agent that ingests them) speaks one language regardless of source.

export interface SocialComment {
  id: string
  provider: string
  author: string
  text: string
  target: string // the post / page / asset the comment is on
  createdAt: string
  likes?: number
}

export type ProviderStatus =
  | 'connected'   // real credentials present + reachable
  | 'mock'        // implemented, returning sample data until creds are supplied
  | 'coming_soon' // registered placeholder, not implemented yet

export interface SocialProvider {
  id: string
  name: string
  /** One-line scope description — must reflect consented-data-only reality. */
  description: string
  status: ProviderStatus
  /** Returns comments normalized to SocialComment[]. Mock until creds exist. */
  listComments(): Promise<SocialComment[]>
}
