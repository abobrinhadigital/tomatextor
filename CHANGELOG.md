# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-04

- Removida limitação chata de 80 caracteres de tradução (flag `--max-len`) do motor do Whisper, deixando o sistema fatiar os blocos pela pontuação real do texto.
- Adicionado regex no pós-processamento Ruby para garantir quebra de parágrafo apenas no final de sentenças (., ! ou ?).
- Removido log `--print-progress` verboso no `whisper-cli` para que o terminal fique limpo durante processamentos grandes.
- Removida flag de `--max-context` zero. Deixando os algoritmos mais potentes trabalharem.

## [1.0.0] - 2026-03-04

- Inicialização da estrutura básica do projeto em Ruby com gerenciamento via Bundler.
- Classe `Tomatextor::ModelManager` para download e validação de modelos GGML.
- Classe `Tomatextor::FileManager` para conversão de áudio via FFmpeg e gestão de arquivos.
- Classe `Tomatextor::Transcriber` integrada com a gem `whispercpp` (suporte a `initial_prompt`).
- Interface de linha de comando (CLI) completa com `transcribe`, `list_models` e `list_dictionary`.
- Suporte a idioma fixo em Português (`pt`) e modelos quantizados.
- Criada estrutura de diretório `data/` para armazenamento padronizado em **YAML**.
- Sincronização dinâmica de modelos via API do HuggingFace, salva em `data/models.yml`.
- Dicionário técnico legado do projeto Python migrado para `data/dictionary.yml`.
- Arquivos de dados (`models.yml`, `dictionary.yml`) padronizados como sequências YAML puras.
- Comando `list_models --sync` unifica listagem e atualização (removido `sync_models` separado).
- Motor de transcrição migrado da gem `whispercpp` para o **binário nativo** `whisper-cli`,
  compilado com suporte a CUDA (`-DGGML_CUDA=ON`, arquitetura `sm_86` para RTX 3050).
- `Transcriber` reescrito com `Open3.popen2e` para saída em tempo real durante transcrição.
- Ativados parâmetros de qualidade: `--flash-attn`, `--max-context 0`, `--entropy-thold 2.8`.
- Adicionada quebra de linha automática na transcrição via `--max-len 80`.
- Nomeação de transcrições padronizada para `AAAA-MM-DD-transcricao-X.txt` com índice sequencial diário.
- Contador de índice considera tanto `transcricoes/novas/` quanto `transcricoes/processados/` para evitar colisões no mesmo dia.
- `README.md` reescrito do zero: requisitos, instalação, configuração, arquivos de dados e todos os comandos documentados.
- Separador de documento YAML `---` adicionado ao `data/dictionary.yml` para padronizar com `data/models.yml`.
- Adicionado comando `delete_models` ao CLI: lista modelos com tamanho, exibe total de espaço e pede confirmação antes de remover.
