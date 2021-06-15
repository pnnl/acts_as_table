module ActsAsTable
  # ActsAsTable reader error.
  class ReaderError < ArgumentError
  end

  # Raised when the headers are not found.
  class HeadersNotFound < ReaderError
  end

  # Raised when the headers do not match the ActsAsTable row model.
  class InvalidHeaders < ReaderError
  end

  # ActsAsTable reader object.
  #
  # @!attribute [r] row_model
  #   Returns the ActsAsTable row model for this ActsAsTable reader object.
  #
  #   @return [ActsAsTable::RowModel]
  # @!attribute [r] input
  #   Returns the input stream for this ActsAsTable reader object.
  #
  #   @return [IO]
  # @!attribute [r] options
  #   Returns the options for this ActsAsTable reader object.
  #
  #   @return [Hash<Symbol, Object>]
  class Reader
    # Returns a new ActsAsTable reader object based on a symbolic name using the given arguments.
    #
    # @param [Symbol] format
    # @param [Array<Object>] args
    # @yieldparam [ActsAsTable::Reader] reader
    # @yieldreturn [void]
    # @return [ActsAsTable::Reader]
    # @raise [ArgumentError] If the given symbolic name is invalid.
    def self.for(format, *args, &block)
      ActsAsTable.for(format).reader(*args, &block)
    end

    attr_reader :row_model, :input, :options

    # Returns a new ActsAsTable reader object using the given ActsAsTable row model, input stream and options.
    #
    # @param [ActsAsTable::RowModel] row_model
    # @param [IO] input
    # @param [Hash<Symbol, Object>] options
    # @yieldparam [ActsAsTable::Reader] reader
    # @yieldreturn [void]
    # @return [ActsAsTable::Reader]
    def initialize(row_model, input = $stdin, **options, &block)
      @row_model, @input, @options = row_model, input, options.dup

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else self.instance_eval(&block)
        end
      end
    end

    # Delegates to the input stream for this ActsAsTable reader object.
    #
    # @param [String] method_name
    # @param [Array<Object>] args
    # @yield [*args, &block]
    # @yieldreturn [Object]
    # @return [Object]
    # @raise [NoMethodError]
    def method_missing(method_name, *args, &block)
      @input.respond_to?(method_name, false) ? @input.send(method_name, *args, &block) : super(method_name, *args, &block)
    end

    # Delegates to the input stream for this ActsAsTable reader object.
    #
    # @param [String] method_name
    # @param [Boolean] include_all
    # @return [Boolean]
    def respond_to?(method_name, include_all = false)
      @input.respond_to?(method_name, false) || super(method_name, include_all)
    end

    # Returns a pair, where the first element is the headers and the second element is a flag that indicates if input stream is at end of file.
    #
    # @return [Array<Object>]
    # @raise [ActsAsTable::HeadersNotFound] If the headers are not found by this ActsAsTable reader object.
    # @raise [ActsAsTable::InvalidHeaders] If the headers do not match the ActsAsTable row model for this ActsAsTable reader object.
    def read_headers
      # @return [ActsAsTable::Headers::Array]
      headers = @row_model.to_headers

      # @return [Boolean]
      eof = false

      # @return [Array<Array<String>, nil>]
      rows = ::Array.new(headers.size) { |index|
        row, eof = *self.read_row

        unless row.nil?
          row += ::Array.new(headers[index].size - row.size) { nil }
        end

        row
      }

      if rows.any?(&:nil?)
        raise ActsAsTable::HeadersNotFound.new("#{self.class}#read_headers - must exist")
      end

      unless [headers, rows].transpose.all? { |pair| pair[0] == pair[1] }
        raise ActsAsTable::InvalidHeaders.new("#{self.class}#read_headers - invalid")
      end

      [rows, eof]
    end

    # Returns a pair, where the first element is the next row or +nil+ if input stream is at end of file and the second element indicates if input stream is at end of file.
    #
    # @return [Object]
    def read_row
      raise ::NotImplementedError.new("#{self.class}#read_row")
    end

    # Enumerates the rows in the input stream.
    #
    # @yieldparam [Array<String, nil>, nil] row
    # @yieldreturn [void]
    # @return [Enumerable<Array<String, nil>, nil>]
    # @raise [ActsAsTable::HeadersNotFound] If the headers are not found by this ActsAsTable reader object.
    # @raise [ActsAsTable::InvalidHeaders] If the headers do not match the ActsAsTable row model for this ActsAsTable reader object.
    def each_row(&block)
      ::Enumerator.new { |enumerator|
        headers, eof = *self.read_headers

        until eof
          row, eof = *self.read_row

          unless eof
            enumerator << row
          end
        end
      }.each(&block)
    end

    # Returns a new ActsAsTable table object by reading all rows in the input stream.
    #
    # @return [ActsAsTable::Table]
    # @raise [ActsAsTable::HeadersNotFound] If the headers are not found by this ActsAsTable reader object.
    # @raise [ActsAsTable::InvalidHeaders] If the headers do not match the ActsAsTable row model for this ActsAsTable reader object.
    # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
    def read_table
      ActsAsTable::Table.new do |table|
        table.row_model = @row_model

        self.each_row do |row|
          records = table.from_row(row)

          records.each do |record|
            record.position = self.lineno
          end
        end
      end
    end
  end
end
