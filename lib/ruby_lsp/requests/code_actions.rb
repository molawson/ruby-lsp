# typed: strict
# frozen_string_literal: true

module RubyLsp
  module Requests
    # ![Code actions demo](../../misc/code_actions.gif)
    #
    # The [code actions](https://microsoft.github.io/language-server-protocol/specification#textDocument_codeAction)
    # request informs the editor of RuboCop quick fixes that can be applied. These are accessible by hovering over a
    # specific diagnostic.
    #
    # # Example
    #
    # ```ruby
    # def say_hello
    # puts "Hello" # --> code action: quick fix indentation
    # end
    # ```
    class CodeActions < BaseRequest
      extend T::Sig

      sig do
        params(
          uri: String,
          document: Document,
          range: Document::RangeShape,
          context: T::Hash[Symbol, T.untyped],
        ).void
      end
      def initialize(uri, document, range, context)
        super(document)

        @uri = uri
        @range = range
        @context = context
      end

      sig { override.returns(T.nilable(T.all(T::Array[Interface::CodeAction], Object))) }
      def run
        diagnostics = @context[:diagnostics]

        code_actions = diagnostics.filter_map do |diagnostic|
          code_action = diagnostic.dig(:data, :code_action)
          next if code_action.nil?

          # We want to return only code actions that are within range or that do not have any edits, such as refactor
          # code actions
          range = code_action.dig(:edit, :documentChanges, 0, :edits, 0, :range)
          code_action if diagnostic.dig(:data, :correctable) && cover?(range)
        end

        code_actions << refactor_code_action(@range, @uri)
      end

      private

      sig { params(range: T.nilable(Document::RangeShape)).returns(T::Boolean) }
      def cover?(range)
        range.nil? ||
          ((@range.dig(:start, :line))..(@range.dig(:end, :line))).cover?(
            (range.dig(:start, :line))..(range.dig(:end, :line)),
          )
      end

      sig { params(range: Document::RangeShape, uri: String).returns(Interface::CodeAction) }
      def refactor_code_action(range, uri)
        Interface::CodeAction.new(
          title: "Refactor: Extract Variable",
          kind: Constant::CodeActionKind::REFACTOR_EXTRACT,
          data: {
            range: range,
            uri: uri,
          },
        )
      end
    end
  end
end
