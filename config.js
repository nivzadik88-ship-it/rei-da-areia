// Supabase connection for the ranking, shared careers and weekly challenge.
// The anon key is public by design: the database's row-level security decides what it can do.
// Leave both empty to play fully offline.
window.REI_CONFIG = {
  supabaseUrl: 'https://yyqvwsmlzkdyeyanvlxa.supabase.co',
  supabaseAnonKey: 'sb_publishable_mUow3s-P7Ci0kijGiyXwbw_iu9pcWGG',
  // PostHog analytics (optional): paste the Project API key (starts with phc_). Host: US = https://us.i.posthog.com, EU = https://eu.i.posthog.com
  posthogKey: '',
  posthogHost: 'https://us.i.posthog.com',
};
