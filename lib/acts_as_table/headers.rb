module ActsAsTable
  # ActsAsTable headers.
  module Headers
    # ActsAsTable headers array object.
    #
    # @!attribute [r] column_models
    #   Returns the ActsAsTable column models for this ActsAsTable headers array object.
    #
    #   @return [Enumerable<ActsAsTable::ColumnModel>]
    class Array < ::Array
      attr_reader :column_models

      # Returns a new ActsAsTable headers array object.
      #
      # @param [Enumerable<ActsAsTable::ColumnModel>] column_models
      # @return [ActsAsTable::Headers::Array]
      def initialize(column_models)
        @column_models = column_models.to_a

        # @return [Array<Array<String>>]
        header_names_without_padding = @column_models.collect { |column_model|
          column_model.name.split(column_model.separator)
        }

        # @return [Integer]
        max_header_names_without_padding_size = header_names_without_padding.collect(&:size).max || 0

        # @return [Array<Array<String, nil>>]
        @header_names_with_padding = header_names_without_padding.collect { |split_name|
          split_name + ::Array.new(max_header_names_without_padding_size - split_name.size) { nil }
        }.collect { |header_names|
          header_names.freeze
        }.freeze

        # @return [Array<Array<String, nil>>]
        headers = @header_names_with_padding.transpose.collect(&:freeze)

        super(headers)

        self.freeze
      end

      # Returns a 3-level array indexed by the header index, the header name index and the pair index.
      #
      # The elements in the 3rd level are pairs, where the first element is the header name and the second element is the ActsAsTable column models count for the header name.
      #
      # @note This method is intended to be used to render tables with merged cells in the header rows (where the ActsAsTable column models count is the column span).
      #
      # @return [Array<Array<Array<Object>>>]
      #
      # @example Render HTML "thead" element with merged "th" elements.
      #   <thead>
      #     <% @row_model.to_headers.with_column_models_count.each do |header| %>
      #       <tr>
      #         <% header.each do |pair| %>
      #           <%= content_tag(:th, pair[0], colspan: pair[1], scope: 'col') %>
      #         <% end %>
      #       </tr>
      #     <% end %>
      #   </thead>
      #
      def with_column_models_count
        # Drop the last row (the corresponding instances of the {ActsAsTable::ColumnModel} class).
        @with_column_models_count ||= Hash.for(@column_models, @header_names_with_padding).to_array[0..-2]
      end
    end

    # ActsAsTable headers hash object.
    #
    # @!attribute [r] column_models_count
    #   Returns the ActsAsTable column models count for this ActsAsTable headers hash object.
    #
    #   @return [Integer]
    class Hash < ::Hash
      # Returns a new ActsAsTable headers hash object for the given ActsAsTable column models and header names.
      #
      # @param [Enumerable<ActsAsTable::ColumnModel>] column_models
      # @param [Array<Array<String, nil>>] header_names_with_padding
      # @return [ActsAsTable::Headers::Hash]
      def self.for(column_models, header_names_with_padding)
        # @!method _block(orig_hash, counter)
        #   Returns the new ActsAsTable headers hash object with accumulated ActsAsTable column models count.
        #
        #   @param [ActsAsTable::Headers::Hash] orig_hash
        #   @param [Integer] counter
        #   @return [ActsAsTable::Headers::Hash]
        _block = ::Proc.new { |orig_hash, counter|
          # @return [Hash<String, Object>]
          new_hash = orig_hash.each_pair.inject({}) { |acc, pair|
            key, value = *pair

            case value
            when ::Array
              counter += value.size

              # @return [Array<ActsAsTable::ColumnModel>]
              acc[key] = value
            when ::Hash
              # @return [ActsAsTable::Headers::Hash]
              new_hash_for_value = _block.call(value, 0)

              counter += new_hash_for_value.column_models_count

              # @return [ActsAsTable::Headers::Hash]
              acc[key] = new_hash_for_value
            end

            acc
          }

          self.new(counter).merge(new_hash).freeze
        }

        # @return [Hash<String, Object>]
        orig_hash = header_names_with_padding.each_with_index.inject({}) { |acc, pair|
          header_names, index = *pair

          # @return [Integer]
          max_header_names_index = header_names.size - 1

          # @return [Hash<String, Object>]
          column_models_for_index = header_names.each_with_index.inject(acc) { |header_acc, pair|
            header_name, header_name_index, = *pair

            if header_name_index == max_header_names_index
              header_acc[header_name] ||= []
              header_acc[header_name] << column_models[index]
            else
              header_acc[header_name] ||= {}
            end

            header_acc[header_name]
          }

          column_models_for_index.freeze

          acc
        }

        _block.call(orig_hash, 0)
      end

      attr_reader :column_models_count

      # Returns a new ActsAsTable headers hash object.
      #
      # @param [Integer] column_models_count
      # @param [Array<Object>] args
      # @yieldparam [ActsAsTable::Headers::Hash] hash
      # @yieldparam [String] key
      # @yieldreturn [ActsAsTable::Headers::Hash, ActsAsTable::ColumnModel]
      # @return [ActsAsTable::Headers::Hash]
      def initialize(column_models_count, *args, &block)
        super(*args, &block)

        @column_models_count = column_models_count
      end

      # Returns this ActsAsTable headers hash object as an array.
      #
      # @return [Array<Array<Object>>]
      def to_array
        # @!method _block(acc, hash_with_column_models_count, depth)
        #   Returns the new ActsAsTable headers hash object with accumulated ActsAsTable column models count.
        #
        #   @param [Array<Array<Object>>] acc
        #   @param [ActsAsTable::Headers::Hash] hash_with_column_models_count
        #   @param [Integer] depth
        #   @return [ActsAsTable::Headers::Hash]
        _block = ::Proc.new { |acc, hash_with_column_models_count, depth|
          hash_with_column_models_count.each do |key, hash_with_column_models_count_or_column_models|
            case hash_with_column_models_count_or_column_models
            when ::Array
              acc[depth] ||= []
              acc[depth] << [key, hash_with_column_models_count_or_column_models.size]

              hash_with_column_models_count_or_column_models.each do |column_model|
                acc[depth + 1] ||= []
                acc[depth + 1] << [column_model]
              end
            when ::Hash
              acc[depth] ||= []
              acc[depth] << [key, hash_with_column_models_count_or_column_models.column_models_count]

              _block.call(acc, hash_with_column_models_count_or_column_models, depth + 1)
            end
          end

          acc
        }

        _block.call([], self, 0)
      end
    end
  end
end
