# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

module Tomatextor
  class FileManager
    attr_reader :config

    # Extensões suportadas originalmente pelo Tomatextor
    SUPPORTED_EXTENSIONS = %w[.mp3 .m4a .wav .ogg .flac].freeze

    def initialize(config)
      @config = config
    end

    # Retorna a lista de arquivos de áudio válidos na pasta de entrada
    def pending_audios
      Dir.glob(File.join(config.new_audio_dir, '*')).select do |file|
        File.file?(file) && SUPPORTED_EXTENSIONS.include?(File.extname(file).downcase)
      end
    end

    # Converte o arquivo de origem para WAV, Mono, 16000Hz (requisito whisper.cpp)
    # Retorna o caminho do arquivo temporário gerado ou nil se falhar
    def convert_to_wav16k(source_file)
      temp_wav = File.join(Dir.tmpdir, "#{File.basename(source_file, '.*')}_16k.wav")
      
      puts "  -> Convertendo #{File.basename(source_file)} para WAV 16kHz..."
      
      # Comando ffmpeg:
      # -y (sobrescrever sem perguntar)
      # -i (input)
      # -ar 16000 (audio rate 16kHz)
      # -ac 1 (audio channels: mono)
      # -c:a pcm_s16le (codec específico para whisper)
      cmd = ["ffmpeg", "-y", "-i", source_file, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", temp_wav]
      
      _, stderr, status = Open3.capture3(*cmd)
      
      if status.success?
        temp_wav
      else
        puts "  -> Erro ao converter arquivo pelo ffmpeg: #{stderr}"
        nil
      end
    end

    # Salva o texto gerado com nome padronizado: AAAA-MM-DD-transcricao-X.txt
    # onde X é o próximo número sequencial do dia (conta novas + já processadas)
    def save_transcription!(_original_filename, text)
      today = Time.now.strftime("%Y-%m-%d")
      pattern_new  = File.join(config.new_transcription_dir,     "#{today}-transcricao-*.txt")
      pattern_hist = File.join(config.history_transcription_dir, "#{today}-transcricao-*.txt")
      next_index = Dir.glob(pattern_new).size + Dir.glob(pattern_hist).size + 1
      txt_path = File.join(config.new_transcription_dir, "#{today}-transcricao-#{next_index}.txt")

      File.write(txt_path, text.strip)
      puts "  -> Transcrição salva em: #{txt_path}"
      txt_path
    end

    # Move o arquivo processado para a pasta de histórico
    def archive_audio!(source_file)
      dest_file = File.join(config.history_audio_dir, File.basename(source_file))
      FileUtils.mv(source_file, dest_file)
      puts "  -> Áudio original movido para histórico."
    end
  end
end
