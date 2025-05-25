# caffeine

Local first seems very much predicated on the "local thing" being a browser. [The seminal paper](https://www.inkandswitch.com/essay/local-first/) presents seven ideals:

1. No spinners: your work at your fingertips
2. Your work is not trapped on one device
3. The network is optional
4. Seamless collaboration with your colleagues
5. The Long Now
6. Security and privacy by default
7. You retain ultimate ownership and control

Yet, as I see it, only (1) necesitates a browser. What if we took this same model but we applied it to an airgapped sidecar running physically connected to the user's device, communicating directly with the application. Since these two devices are hard-wired and the "secure" device is airgapped, we should still get (1).

The [automerge](https://automerge.org/) libraries seem to converge on the following parts:
1. underlying CRDT data structure
2. a repo supporting network based syncing with a storage adapter as well
