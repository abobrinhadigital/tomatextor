# frozen_string_literal: true

require_relative "tomatextor/version"
require_relative "tomatextor/config"
require_relative "tomatextor/model_manager"
require_relative "tomatextor/file_manager"
require_relative "tomatextor/transcriber"
require_relative "tomatextor/cli"

module Tomatextor
  class Error < StandardError; end
end
