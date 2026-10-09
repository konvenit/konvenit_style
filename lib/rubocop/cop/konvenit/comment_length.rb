module RuboCop
  module Cop
    module Konvenit
      # Limits full-line comment blocks to `Max` lines (default 2).
      # Magic comments, rubocop directives and annotate blocks are ignored.
      class CommentLength < Base
        MSG = "Comment has too many lines. [%<count>d/%<max>d]".freeze
        IGNORED_COMMENT = /\A#\s*(rubocop:|frozen_string_literal:|encoding:|coding:|typed:|shareable_constant_value:)/
        ANNOTATE_HEADER = /\A#\s*== (Schema Info|Route Map)/

        def on_new_investigation
          comment_blocks.each do |block|
            next if block.size <= max || block.first.text.match?(ANNOTATE_HEADER)
            range = block[max].source_range.join(block.last.source_range)
            add_offense(range, message: format(MSG, count: block.size, max: max))
          end
        end

        private

        def comment_blocks
          full_line_comments.slice_when do |previous, current|
            current.loc.line != previous.loc.line + 1 || current.loc.column != previous.loc.column
          end
        end

        def full_line_comments
          processed_source.comments.select do |comment|
            comment_line?(processed_source.lines[comment.loc.line - 1]) && !comment.text.match?(IGNORED_COMMENT)
          end
        end

        def max
          cop_config.fetch("Max", 2)
        end
      end
    end
  end
end
