# Reading a Backend Spec, and Where Each Convention Lives

## Reading the Spec

Backends hand over either an OpenAPI/Swagger spec or a Postman collection.
`contracts/openapi.json` is OpenAPI 3; convert what you get into it before
writing code.

- **OpenAPI** (YAML/JSON file or URL): read `servers[]` (base URL), `paths`
  (operations, `operationId`, parameters, `requestBody`, `responses`),
  `components/schemas` (`required`, `nullable`, `enum`, `default`,
  `format: date-time`), `components/securitySchemes` and the global
  `security`. An operation with `"security": []` is callable without a
  session.
- **Postman** (JSON export or URL): read the `item[]` requests (method,
  `url.raw`/`url.path`, `body.raw`), the saved example `response[]` bodies and
  status codes (they stand in for schemas), `auth` at collection or request
  level, and the variables (`{{baseUrl}}`, `{{token}}`) from `variable[]` or
  the environment file. Give each request an `operationId` when you add it to
  the spec.

## Where Each Convention Lives

Each convention below is implemented once, in the REST adapter
(`grep -rl "implements ApiClient" lib`), for every call. Read only the row the
spec changes, and **stop and ask** before changing one.

| Convention | Code | What to change |
|---|---|---|
| Auth paths, public paths | `AuthEndpoints` in the auth service (`grep -rn "class AuthEndpoints" lib`) | Login/refresh/logout paths; `public` lists paths sent without a token, whose `401` is final (no refresh). |
| Auth header | the `Interceptor` that sets `Authorization` (`grep -rl "implements Interceptor" lib`) | Header scheme (`Bearer` today). |
| Token refresh | the Chopper `Authenticator` (`grep -rl "extends Authenticator" lib`) | Refresh request/response DTOs; which statuses expire the session (a repeated `401` today). |
| Response envelope | the converter's `convertResponse` | If responses are wrapped (`{ "data": … }`), unwrap once there; never in DTOs or repositories. |
| Error body, status → error code | `toResult` and the error DTO (`grep -rl "ApiErrorDto(" lib`) | Error body shape (`{ code, message }` today); status mapping; timeout. |
| Pagination | `PaginatedData` in `lib/src/shared/` | Default `?page&limit` with `hasNextPage = items.length == limit`. Server metadata → a page DTO mapped to `PaginatedData`. |
| Base URL | `BASE_URL` in `env/*.json` and the spec's `servers` | No trailing slash: service paths start with `/`. |
