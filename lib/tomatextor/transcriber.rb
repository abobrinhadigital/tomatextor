# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'tempfile'

module Tomatextor
  class Transcriber
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)
    WHISPER_CLI = File.join(PROJECT_ROOT, "vendor/whisper.cpp/build/bin/whisper-cli")
    DICTIONARY_PATH = File.join(PROJECT_ROOT, "data/dictionary.yml")

    attr_reader :model_path

    def initialize(model_path)
      @model_path = model_path
      raise "Binário whisper-cli não encontrado em #{WHISPER_CLI}" unless File.exist?(WHISPER_CLI)
      puts "  -> Motor Whisper (binário nativo) pronto: #{File.basename(model_path)}"
    end

    def transcribe(audio_wav_path)
      puts "  -> Processando áudio no motor do Whisper..."

      cmd = [
        WHISPER_CLI,
        "--model",          model_path,
        "--language",       "pt",
        "--output-txt",
        "--no-timestamps",
        "--max-context",    "0",       # Evita delírios por contexto acumulado (= no-context)
        "--flash-attn",                # Flash Attention: menos alucinação em áudios longos
        "--entropy-thold",  "2.8",    # Corta segmentos incertos antes de alucinar
        "--file",           audio_wav_path
      ]

      # Adiciona o dicionário de contexto, se existir
      if File.exist?(DICTIONARY_PATH)
        data = YAML.load_file(DICTIONARY_PATH)
        if data && data["dictionary"]
          prompt = data["dictionary"].join(", ")
          puts "  -> Usando dicionário de contexto: #{prompt}"
          cmd += ["--prompt", prompt]
        end
      end

      # Roda o whisper-cli em tempo real, imprimindo a saída conforme ela aparece
      exit_status = nil
      Open3.popen2e(*cmd) do |_stdin, out_err, thread|
        out_err.each_line { |line| print line }
        exit_status = thread.value
      end

      unless exit_status.success?
        raise "Falha na transcrição (exit #{exit_status.exitstatus})"
      end

      # O whisper-cli salva em <audio>.txt automaticamente quando --output-txt é usado
      txt_path = "#{audio_wav_path}.txt"
      if File.exist?(txt_path)
        # Lê o arquivo e usa regex para quebrar linha onde há pontuação
        result = File.read(txt_path).strip
        result = result.gsub(/([.?!])\s+/, "\\1\n\n")
        File.delete(txt_path)
        result
      else
        raise "Arquivo de transcrição não encontrado: #{txt_path}"
      end
    end
  end
end
