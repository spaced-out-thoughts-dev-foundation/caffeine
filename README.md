<div align="center">
  <img src="https://zen.sre.studio/public/images/caffeine_icon.png" alt="Caffeine Icon" width="256" height="256">
</div>

[![Test Caffeine Language](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/caffeine.yml/badge.svg)](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/caffeine.yml)

[![Test Brewface GUI](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/brewface.yml/badge.svg)](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/brewface.yml)

[![Test Roast IR Processing Library](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/roast.yml/badge.svg)](https://github.com/spaced-out-thoughts-dev-foundation/caffeine/actions/workflows/roast.yml)

An intent-based, constraint-oriented domain-specific-language for defining [service level objectives (SLOs)](https://sre.google/sre-book/service-level-objectives/) that transpile to the [OpenSLO](https://openslo.com/) standard written in [Racket](https://racket-lang.org/).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CAFFEINE ECOSYSTEM                           │
└─────────────────────────────────────────────────────────────────────────┘

                           ┌─────────────────┐
                           │   .cf FILES     │
                           │                 │
                           │ service web {   │
                           │   avail 99.9%   │
                           │ }               │
                           │ web -> api      │
                           └─────────────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  CAFFEINE DSL   │
                           │   (caffeine/)   │
                           │                 │
                           │ Parses files to │
                           │ intermediate    │
                           │ representation  │
                           └─────────────────┘
                                    │
                                    │ IR Data
                                    ▼
                           ┌─────────────────┐
                           │ INTERMEDIATE    │
                           │ REPRESENTATION  │
                           │                 │
                           │ Structured data │
                           │ format for all  │
                           │ processing      │
                           └─────────────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │  ROAST LIBRARY  │
                           │   (roast/)      │
                           │                 │
                           │ IR Processing   │
                           │ & Analysis      │
                           │                 │
                           │ • File Loading  │
                           │ • Validation    │
                           │ • Service List  │
                           │ • Dependencies  │
                           │ • Metrics       │
                           └─────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
           ┌─────────────────┐     ┌─────────────────┐
           │  BREWFACE GUI   │     │  FUTURE TOOLS   │
           │  (brewface/)    │     │                 │
           │                 │     │                 │
           │ Visual Graph    │     │ CLI Tools       │
           │ Editor &        │     │ Web Interfaces  │
           │ Visualizer      │     │ Analysis        │
           │                 │     │ Exporters       │
           │ • Graph Canvas  │     │                 │
           │ • File Editor   │     │ • JSON Export   │
           │ • Live Updates  │     │ • OpenSLO       │
           │ • Zen Theme     │     │ • Prometheus    │
           │                 │     │ • Grafana       │
           └─────────────────┘     └─────────────────┘
```
