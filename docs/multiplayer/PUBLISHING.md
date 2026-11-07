# What the owner needs to do to test reserved match servers (M2)

Publishing changes what players can reach, so these steps are the owner's. Nothing below has been done yet.

1. **Experience settings** (Studio → Game Settings, with the TD place open):
   - Security → turn on **Enable Studio Access to API Services** (DataStore and MemoryStore in Studio).
   - Security → **Allow Third Party Teleports** can stay off (all places are in one experience).
2. **Create the Match place in the same experience:** Creator Dashboard → the TD experience → Places → **Add Place** (or in Studio: View → Asset Manager → Places → right-click → Add New Place). Name it "TD Match".
3. **Fill the Match place:** open it in Studio, copy in `ReplicatedStorage.TD` (Config, Lobby, Remotes), `ServerScriptService.TD` (all combat services, MatchContext, PlayerDataService, `Match` folder **without** HubService/HubBuilder/PartyService/MatchLaunchService), `StarterPlayerScripts.TD`, and `Workspace.TDMap`. Wire `MatchServerBridge` as in INTEGRATION.md. Publish the place (File → Publish to Roblox).
4. **Send the executor the Match place id** (shown in Asset Manager / Creator Dashboard). It goes into `ModeLobbyConfig.Places.Match` in both places; then publish the Hub place again.
5. **Keep it private while testing:** Creator Dashboard → experience → Permissions/Privacy → **Private** (or Friends only). Test with 2–3 accounts (you plus friends or alt accounts) on live servers, not Studio.
6. **Checklist to run live and report back:** Story lobby solo start → reserved server → win → results → Return to Hub; 2-player party with one player ready late; Replay; leave mid-match and rejoin (once the hub has a Rejoin button calling `MatchLaunchService.rejoin`); a non-member following a friend into the match is sent to the hub; auto return after 90 s.

Until step 6 passes, teleport behaviour counts as **not verified**.
