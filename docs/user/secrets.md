# Secrets and API keys

Metadata providers need credentials. They are never stored in config, manifests,
logs, or HTML.

## Store a secret

```bat
games-library.cmd -SetSecret steamgriddb
games-library.cmd -SetSecret igdbClientId
games-library.cmd -SetSecret igdbClientSecret
```

You will be prompted for the value. Then reference it in config:

```json
"metadata": {
  "providers": {
    "steamGridDb": { "enabled": true, "apiKey": "{secret:steamgriddb}" },
    "igdb": { "enabled": true, "clientId": "{secret:igdbClientId}", "clientSecret": "{secret:igdbClientSecret}" }
  }
}
```

## Environment variables

`{env:VAR}` reads an environment variable. A local `.env` file in the repository
root is loaded automatically at startup (gitignored). See `.env.example`.

## Manage secrets

```bat
games-library.cmd -ListSecrets
games-library.cmd -RemoveSecret steamgriddb
```