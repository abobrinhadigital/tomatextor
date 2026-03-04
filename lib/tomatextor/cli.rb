# frozen_string_literal: true

require 'thor'
require_relative 'config'
require_relative 'model_manager'
require_relative 'file_manager'
require_relative 'transcriber'

module Tomatextor
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "list_models", "Lista os modelos suportados (locais)"
    method_option :sync, type: :boolean, aliases: "-s", desc: "Sincroniza a lista com o HuggingFace antes de listar", default: false
    def list_models
      if options[:sync]
        puts "Sincronizando modelos com o repositório oficial..."
        ModelManager.fetch_available_models
        puts "Sincronização concluída!"
      end

      puts "Modelos suportados (use o nome exato no seu .env ou via --size):"
      ModelManager.available_models_list.each { |m| puts "- #{m}" }
      
      unless options[:sync]
        puts "\nDica: Use 'tomatextor list_models --sync' para buscar novidades no HuggingFace."
      end
    end

    desc "list_dictionary", "Lista os termos técnicos e nomes cadastrados no dicionário"
    def list_dictionary
      path = File.expand_path("../../data/dictionary.yml", __dir__)
      if File.exist?(path)
        data = YAML.load_file(path)
        terms = data["dictionary"] || []
        puts "Termos no dicionário de contexto:"
        terms.each { |t| puts "- #{t}" }
      else
        puts "Dicionário não encontrado em data/dictionary.yml"
      end
    end

    desc "download_model", "Baixa o modelo Whisper (GGML) do HuggingFace"
    method_option :size, aliases: "-s", desc: "Tamanho do modelo (tiny, small, large-v3-turbo, etc). Se não passado, lê do .env", default: nil
    def download_model
      config = Config.load!
      target_size = options[:size] || config.model_size
      
      puts "Verificando e baixando o modelo GGML (#{target_size}) se necessário..."
      manager = ModelManager.new(model_size: target_size)
      manager.ensure_model_downloaded!
    end

    desc "delete_models", "Remove os modelos GGML baixados para liberar espaço em disco"
    def delete_models
      models_dir = File.expand_path("../../models", __dir__)
      models = Dir.glob(File.join(models_dir, "ggml-*.bin"))

      if models.empty?
        puts "Nenhum modelo encontrado em #{models_dir}."
        return
      end

      puts "Modelos encontrados:"
      total_mb = 0
      models.each do |m|
        size_mb = (File.size(m) / 1024.0 / 1024.0).round(1)
        total_mb += size_mb
        puts "  - #{File.basename(m)} (#{size_mb} MB)"
      end
      puts "\nTotal: #{total_mb.round(1)} MB"
      puts "\nTem certeza que deseja remover #{models.size} modelo(s)? [s/N]"
      confirm = $stdin.gets.to_s.strip.downcase

      if confirm == "s"
        models.each { |m| FileUtils.rm(m) }
        puts "#{models.size} modelo(s) removido(s) com sucesso."
      else
        puts "Operação cancelada. Seus modelos estão a salvo."
      end
    end

    desc "transcribe", "Lê e transcreve os áudios da pasta configurada"
    def transcribe
      config = Config.load!
      config.ensure_directories!

      # Prepara o modelo GGML
      manager = ModelManager.new(model_size: config.model_size)
      model_path = manager.ensure_model_downloaded!

      # Instancia os orquestradores
      file_manager = FileManager.new(config)
      audios = file_manager.pending_audios

      if audios.empty?
        puts "Nenhum arquivo de áudio encontrado em #{config.new_audio_dir}."
        return
      end

      transcriber = Transcriber.new(model_path)

      puts "Iniciando processamento de #{audios.size} arquivo(s)..."

      audios.each_with_index do |audio_file, index|
        puts "\n[#{index + 1}/#{audios.size}] Processando #{File.basename(audio_file)}"
        
        # 1. Converte pra WAV 16kHz
        wav_file = file_manager.convert_to_wav16k(audio_file)
        next unless wav_file # pula se deu erro

        begin
          # 2. Roda a IA
          text = transcriber.transcribe(wav_file)
          
          # 3. Salva TXT
          file_manager.save_transcription!(audio_file, text)
          
          # 4. Arquiva
          file_manager.archive_audio!(audio_file)
        ensure
          # Garante limpeza do temporário
          FileUtils.rm_f(wav_file) if File.exist?(wav_file)
        end
      end
      
      puts "\nTranscrição em lote finalizada! Protegido contra deuses caóticos."
    end
  end
end
