# typed: strict
# frozen_string_literal: true

require "cgi"
require "uri"
require "ruby_lsp/document"

module RubyLsp
  class Store
    extend T::Sig

    sig { params(encoding: String).void }
    attr_writer :encoding

    sig { returns(String) }
    attr_accessor :formatter

    sig { void }
    def initialize
      @state = T.let({}, T::Hash[String, Document])
      @encoding = T.let("utf-8", String)
      @formatter = T.let("auto", String)
    end

    sig { params(uri: String).returns(Document) }
    def get(uri)
      document = @state[uri]
      return document unless document.nil?

      set(uri, File.binread(CGI.unescape(URI.parse(uri).path)))
      T.must(@state[uri])
    end

    sig { params(uri: String, content: String).void }
    def set(uri, content)
      document = Document.new(content, @encoding)
      @state[uri] = document
    end

    sig { params(uri: String, edits: T::Array[Document::EditShape]).void }
    def push_edits(uri, edits)
      T.must(@state[uri]).push_edits(edits)
    end

    sig { void }
    def clear
      @state.clear
    end

    sig { returns(T::Boolean) }
    def empty?
      @state.empty?
    end

    sig { params(uri: String).void }
    def delete(uri)
      @state.delete(uri)
    end

    sig do
      type_parameters(:T)
        .params(
          uri: String,
          request_name: Symbol,
          block: T.proc.params(document: Document).returns(T.type_parameter(:T)),
        ).returns(T.type_parameter(:T))
    end
    def cache_fetch(uri, request_name, &block)
      get(uri).cache_fetch(request_name, &block)
    end
  end
end
