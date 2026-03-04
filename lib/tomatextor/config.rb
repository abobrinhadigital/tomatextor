# frozen_string_literal: true

require 'dotenv'
require 'fileutils'

module Tomatextor
  class Config
    attr_reader :new_audio_dir, :history_audio_dir, :new_transcription_dir, :history_transcription_dir, :model_size

    def self.load!
      Dotenv.load
      new
    end

    def initialize
      @new_audio_dir = ENV.fetch("NEW_AUDIO_DIR", File.expand_path("../../audios/novos", __dir__))
      @history_audio_dir = ENV.fetch("HISTORY_AUDIO_DIR", File.expand_path("../../audios/processados", __dir__))
      @new_transcription_dir = ENV.fetch("NEW_TRANSCRIPTION_DIR", File.expand_path("../../transcricoes/novas", __dir__))
      @history_transcription_dir = ENV.fetch("HISTORY_TRANSCRIPTION_DIR", File.expand_path("../../transcricoes/processados", __dir__))
      @model_size = ENV.fetch("WHISPER_MODEL_SIZE", "small")
    end

    # Método auxiliar para garantir que todas as pastas de entrada/saída existam
    # para evitar problemas ao inicializar o bot
    def ensure_directories!
      FileUtils.mkdir_p(@new_audio_dir)
      FileUtils.mkdir_p(@history_audio_dir)
      FileUtils.mkdir_p(@new_transcription_dir)
      FileUtils.mkdir_p(@history_transcription_dir)
    end
  end
end
