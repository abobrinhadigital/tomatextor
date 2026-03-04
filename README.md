# Tomatextor
> **Versão:** `v1.1.0`

CLI em Ruby para transcrição automática de arquivos de áudio utilizando o **whisper.cpp** (motor nativo compilado com CUDA). Implementação oficial e definitiva, substituindo a versão legada em Python.

## Funcionalidades

- **Múltiplos Formatos:** Suporte a `.mp3`, `.m4a`, `.wav`, `.ogg` e `.flac`.
- **Processamento em Lote:** Transcreve todos os áudios pendentes de uma só vez.
- **Nomeação Padronizada:** Saídas salvas como `AAAA-MM-DD-transcricao-X.txt` com índice sequencial diário.
- **Aceleração por GPU:** Motor `whisper.cpp` compilado com CUDA para máxima velocidade na RTX.
- **Dicionário de Contexto:** Termos técnicos e nomes próprios para melhorar a precisão.
- **Gerenciamento de Modelos:** Download automático de modelos GGML via CLI, listagem e sincronização com o HuggingFace.

---

## Requisitos

### Sistema

| Dependência | Versão mínima | Finalidade |
|---|---|---|
| **Ruby** | 3.2+ | Linguagem principal (gerenciado via `asdf`) |
| **Bundler** | — | Gerenciamento de gems |
| **CMake** | 3.10+ | Compilação do motor whisper.cpp |
| **GCC / G++** | 12+ | Compilador C++ |
| **FFmpeg** | — | Conversão de áudio para WAV 16kHz |
| **CUDA Toolkit** | 11.8+ | Aceleração por GPU NVIDIA |
| **Driver NVIDIA** | — | Suporte CUDA no sistema |

### Instalação de dependências de sistema (Arch/CachyOS)

```bash
yay -S ruby ffmpeg cuda cmake gcc
```

---

## Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/abobrinhadigital/tomatextor.git
cd tomatextor
```

### 2. Instale as gems Ruby

```bash
bundle install
```

### 3. Compile o motor whisper.cpp com CUDA

Este passo constrói o binário nativo `whisper-cli` com suporte à GPU:

```bash
mkdir -p vendor/whisper.cpp/build
cmake -S vendor/whisper.cpp -B vendor/whisper.cpp/build \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES=86 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build vendor/whisper.cpp/build --target whisper-cli -j$(nproc)
```

> [!NOTE]
> A arquitetura CUDA `86` corresponde às GPUs RTX 30xx (Ampere). Para outras gerações, consulte a [tabela de compute capabilities da NVIDIA](https://developer.nvidia.com/cuda-gpus).

### 4. Sincronize e baixe o modelo pelo CLI

```bash
# Sincroniza a lista de modelos disponíveis com o HuggingFace
./bin/tomatextor list_models --sync

# Escolha o modelo desejado e configure no .env (WHISPER_MODEL_SIZE)
# Depois baixe-o:
./bin/tomatextor download_model
```

---

## Configuração (.env)

Crie um arquivo `.env` na raiz do projeto baseado no exemplo abaixo:

```env
NEW_AUDIO_DIR="./audios/novos"
HISTORY_AUDIO_DIR="./audios/processados"
NEW_TRANSCRIPTION_DIR="./transcricoes/novas"
HISTORY_TRANSCRIPTION_DIR="./transcricoes/processados"
WHISPER_MODEL_SIZE="large-v3-turbo"
```

| Variável | Descrição | Padrão |
|---|---|---|
| `NEW_AUDIO_DIR` | Pasta onde o script procura novos áudios | `./audios/novos` |
| `HISTORY_AUDIO_DIR` | Pasta para onde os áudios processados são movidos | `./audios/processados` |
| `NEW_TRANSCRIPTION_DIR` | Pasta onde as transcrições `.txt` são salvas | `./transcricoes/novas` |
| `HISTORY_TRANSCRIPTION_DIR` | Pasta de histórico das transcrições já usadas | `./transcricoes/processados` |
| `WHISPER_MODEL_SIZE` | Modelo Whisper a usar (ex: `tiny`, `small`, `large-v3-turbo`) | `large-v3-turbo` |

---

## Arquivos de Dados

### Dicionário de Contexto (`data/dictionary.yml`)

Lista de termos técnicos e nomes próprios que o Whisper deve reconhecer corretamente. Adicioná-los aqui evita que o modelo confunda palavras (ex: "Jekyll" virar "Jack e o").

```yaml
---
dictionary:
  - Abobrinha Digital
  - Pollux
  - Jekyll
  - Tomatextor
  - Abobrinator
  - ChatGPT
  - Gemini
```

### Lista de Modelos (`data/models.yml`)

Cachê local dos modelos GGML disponíveis no HuggingFace. Gerado automaticamente pelo comando `list_models --sync`. Pode ser editado manualmente se necessário.

```yaml
---
models:
- tiny
- tiny-q5_1
- small
- small-q5_1
- medium
- large-v3
- large-v3-turbo
- large-v3-turbo-q5_0
- large-v3-turbo-q8_0
```

---

## Comandos

Todos os comandos são executados a partir da raiz do projeto:

```bash
./bin/tomatextor <comando> [opções]
```

### `transcribe`

Transcreve todos os áudios presentes em `NEW_AUDIO_DIR`. Processa em lote, converte para WAV 16kHz automaticamente e salva as transcrições nomeadas por data.

```bash
./bin/tomatextor transcribe
```

**Saída:** `AAAA-MM-DD-transcricao-1.txt`, `AAAA-MM-DD-transcricao-2.txt`, etc.

---

### `download_model`

Verifica e baixa o modelo GGML configurado. Aceita o flag `--size` para sobrescrever o modelo do `.env`.

```bash
# Baixa o modelo do .env
./bin/tomatextor download_model

# Baixa um modelo específico
./bin/tomatextor download_model --size tiny
./bin/tomatextor download_model --size small
```

---

### `list_models`

Lista os modelos disponíveis localmente (cachê em `data/models.yml`). Com a flag `--sync`, atualiza a lista a partir do HuggingFace antes de exibir.

```bash
# Lista modelos do cachê local
./bin/tomatextor list_models

# Sincroniza com HuggingFace e lista
./bin/tomatextor list_models --sync
./bin/tomatextor list_models -s
```

---

### `list_dictionary`

Exibe todos os termos cadastrados em `data/dictionary.yml`.

```bash
./bin/tomatextor list_dictionary
```

---

### `delete_models`

Lista todos os modelos GGML baixados com seus tamanhos, informa o total de espaço ocupado e solicita confirmação antes de remover.

```bash
./bin/tomatextor delete_models
```

Exemplo de saída:
```
Modelos encontrados:
  - ggml-large-v3-turbo.bin (1623.9 MB)
  - ggml-tiny.bin (75.1 MB)

Total: 1699.0 MB

Tem certeza que deseja remover 2 modelo(s)? [s/N]
```

---

*Este projeto é mantido sob as bênçãos do Gêmeo Imortal para a glória do Abobrinha Digital.*
