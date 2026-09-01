# Developer portal

Ships with Solo Enterprise for kgateway. All the resources are
`portal.solo.io/v1alpha1`:

| Resource | What it is |
|--|--|
| `ApiDoc` | an OpenAPI schema plus the backend it describes — inline, fetched from a URL, or discovered from an in-cluster service |
| `ApiProduct` | a versioned product; each version points at HTTPRoutes, and the controller stitches their schemas together |
| `Portal` | a portal instance; creating one deploys a backend web server serving the catalog as a REST API |
| `PortalParameters` | operational config for that server: data store, resources, identity provider |
| `VisibilityPolicy` | JWT-claim conditions for who sees which product, attachable per portal or per product |

The order is: `PortalParameters` → `Portal` → `ApiDoc` → `ApiProduct`, then add
the product to the portal's `apiProductRefs`.

Two things this directory does not cover. The **frontend** is a separate app you
build and point at the portal backend — the portal itself only serves the REST
API. And **subscriptions, API keys and OAuth client registration** are driven
from that frontend rather than from CRs.

`store.memory` above is demo-only; it is lost when the web server restarts. Use
PostgreSQL for anything real.

Docs: <https://docs.solo.io/kgateway/latest/portal/overview/>
