# DanDi Bot - Regras permanentes

## Publicacao obrigatoria

- Depois de qualquer alteracao no Flutter Web ou em `functions/`, executar os testes relevantes e gerar o build Web de producao.
- Publicar o resultado no Cloudflare Pages, projeto `dandi-bot`, branch de producao `master`.
- O destino oficial e sempre `https://dandi-bot.pages.dev/`.
- Depois do deploy, verificar o dominio oficial e confirmar que a funcionalidade alterada esta presente. Nao considerar a tarefa concluida apenas com build local.
- Usar deploy com working tree suja quando necessario, preservando todas as alteracoes locais existentes.
- So deixar de publicar quando o usuario pedir explicitamente para nao fazer deploy ou quando houver bloqueio de autenticacao/permissao; nesse caso, informar o bloqueio claramente.

## Fluxo padrao

```powershell
& 'C:\flutter_windows_3.44.0-stable\flutter\bin\flutter.bat' build web --release --no-wasm-dry-run --dart-define=DANDI_BACKEND_URL=https://dandi-bot.pages.dev
& 'C:\Program Files\nodejs\npx.cmd' wrangler pages deploy build\web --project-name dandi-bot --branch master --commit-dirty=true
```

## Git

- Preservar mudancas soltas que ja existirem no workspace.
- Nunca reverter alteracoes do usuario para preparar um deploy.
