# OAuth2 access token validation

For a JWT you can skip introspection entirely and validate locally with
`accessTokenValidation.jwt.localJwks.inlineString` (or `remoteJwks`), which is
what the docs walk through.

`AuthConfig` keeps the Gloo Edge schema, so the full field list lives in the
[Gloo Edge extauth API reference](https://docs.solo.io/gloo-edge/main/reference/api/github.com/solo-io/gloo/projects/gloo/api/v1/enterprise/options/extauth/v1/extauth.proto.sk/#accesstokenvalidation).

Docs: <https://docs.solo.io/kgateway/latest/security/extauth/oauth/access-token/>
