import { facebookProvider } from './facebook'
import type { SocialProvider } from './types'

const comingSoon = (id: string, name: string, description: string): SocialProvider => ({
  id, name, description, status: 'coming_soon', listComments: async () => [],
})

// Facebook is the first concrete provider; others are registered placeholders
// that plug into the same SocialProvider contract.
export const providers: SocialProvider[] = [
  facebookProvider,
  comingSoon('instagram', 'Instagram', 'Comments on media you manage (Graph API, consented data).'),
  comingSoon('x', 'X (Twitter)', 'Mentions & replies for connected accounts.'),
  comingSoon('linkedin', 'LinkedIn', 'Comments on organization posts you administer.'),
]
