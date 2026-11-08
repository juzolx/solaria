# App Store Connect: App Privacy answers (launch version)

**Launch (online off, no purchases):** "Data Not Collected". Tracking: **No**. No third-party SDKs that collect data.

- The local error log (user://debug_log.txt) and share-card PNGs (user://share) stay on the device and are never transmitted, so they are not "collected" in Apple's sense.
- Account deletion: not applicable at launch, because the game creates no accounts. Do not mention a deletion path in the listing.
- Privacy Policy URL: host store/PRIVACY_POLICY.md somewhere public (a free GitHub Pages site works) and paste the link. Fill in [date of release] and [contact email] first (owner).
- Export compliance: the build sets ITSAppUsesNonExemptEncryption=false.

## Only if online features are ever switched on (future version, not launch)
Update this page, the privacy policy and the App Privacy answers together, to roughly:

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| User ID (anonymous account id) | Yes | Yes | No | App Functionality |
| Other User Content (online name, guild name) | Yes | Yes | No | App Functionality |
| Gameplay Content (floors, runs, cloud backups) | Yes | Yes | No | App Functionality |

An in-game account deletion path is then required (Apple 5.1.1(v)), and user-generated names need filtering and a report/block path (Apple 1.2).
