# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'yaml'

module Tomatextor
  class ModelManager
    MODELS_FILE = File.expand_path("../../data/models.yml", __dir__)
    BASE_URL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

    # Lista estática inicial como último recurso de fallback
    STATIC_MODELS = %w[
      tiny tiny.en base base.en small small.en medium medium.en large-v1 large-v2 large-v3 large-v3-turbo
    ].freeze

    attr_reader :model_size, :models_dir

    def initialize(model_size: "small", models_dir: nil)
      @models_dir = models_dir || File.expand_path("../../models", __dir__)
      @model_size = validate_model!(model_size)
    end

    def model_filename
      "ggml-#{@model_size}.bin"
    end

    def model_path
      File.join(@models_dir, model_filename)
    end

    def model_exists?
      File.exist?(model_path)
    end

    def ensure_model_downloaded!
      return model_path if model_exists?

      puts "Modelo #{model_filename} não encontrado localmente."
      download_model!
      
      model_path
    end

    # Busca os nomes dos arquivos .bin no repositório do HuggingFace
    def self.fetch_available_models
      uri = URI("https://huggingface.co/api/models/ggerganov/whisper.cpp/tree/main")
      response = Net::HTTP.get(uri)
      tree = JSON.parse(response)

      models = tree.select { |f| f["path"] =~ /^ggml-.*\.bin$/ }
                   .map { |f| f["path"].gsub(/^ggml-/, "").gsub(/\.bin$/, "") }
                   .sort

      File.write(MODELS_FILE, { "models" => models }.to_yaml)
      models
    rescue StandardError => e
      puts "[AVISO]: Falha ao atualizar lista de modelos: #{e.message}"
      available_models_list
    end

    def self.available_models_list
      if File.exist?(MODELS_FILE)
        data = YAML.load_file(MODELS_FILE)
        (data && data["models"]) || STATIC_MODELS
      else
        STATIC_MODELS
      end
    end

    def self.models_with_details
      available_models_list
    end

    private

    def validate_model!(size)
      list = self.class.available_models_list
      return size if list.include?(size)

      puts "Modelo '#{size}' não encontrado na lista local. Consultando HuggingFace..."
      updated_list = self.class.fetch_available_models
      
      return size if updated_list.include?(size)

      raise "Tamanho de modelo inválido: '#{size}'. Modelos disponíveis: #{updated_list.join(', ')}"
    end

    def download_model!
      url = "#{BASE_URL}/#{model_filename}"
      FileUtils.mkdir_p(@models_dir)
      
      puts "Iniciando download de #{url} para #{@models_dir}..."
      
      URI.parse(url).open do |remote|
        File.open(model_path, "wb") do |local|
          while (chunk = remote.read(8192))
            local.write(chunk)
          end
        end
      end
      
      puts "Download concluído com sucesso: #{model_path}"
    rescue StandardError => e
      FileUtils.rm_f(model_path) if File.exist?(model_path)
      raise "Falha ao baixar modelo GGML: #{e.message}"
    end
  end
end
