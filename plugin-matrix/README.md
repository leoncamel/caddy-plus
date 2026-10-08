# Plugin Matrix

Each Caddy version in `../caddy-versions.txt` has one matching plugin manifest named `<caddy-version>.txt`.

| Caddy version | alidns | coraza-caddy | caddy-l4 | Notes |
| --- | --- | --- | --- | --- |
| `2.10.2` | `v1.0.29` | `v2.1.0` | — | `coraza-caddy v2.2.0+` requires Caddy v2.11.2; stay at v2.1.0 on the 2.10.x line. `caddy-l4 v0.1.x` requires Caddy v2.11.4+; not available. |
| `2.11.2` | `v1.0.29` | `v2.5.0` | — | `caddy-l4 v0.1.x` requires Caddy v2.11.4+; not available for 2.11.2. |
| `2.11.7` | `v1.0.29` | `v2.6.2` | `v0.1.2` | `caddy-l4 v0.1.2` requires Caddy v2.11.4+ and Go 1.25.1. |
