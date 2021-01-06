module ActsAsTable
  # ActsAsTable writer object.
  #
  # @!attribute [r] row_model
  #   Returns the ActsAsTable row model for this ActsAsTable reader object.
  #
  #   @return [ActsAsTable::RowModel]
  # @!attribute [r] output
  #   Returns the output stream for this ActsAsTable reader object.
  #
  #   @return [IO]
  # @!attribute [r] options
  #   Returns the options for this ActsAsTable reader object.
  #
  #   @return [Hash<Symbol, Object>]
  class Writer
    # Returns a new ActsAsTable writer object based on a symbolic name using the given arguments.
    #
    # @param [Symbol] format
    # @param [Array<Object>] args
    # @yieldparam [ActsAsTable::Writer] writer
    # @yieldreturn [void]
    # @return [ActsAsTable::Writer]
    # @raise [ArgumentError] If the given symbolic name is invalid.
    def self.for(format, *args, &block)
      ActsAsTable.for(format).writer(*args, &block)
    end

    attr_reader :row_model, :output, :options

    # Returns a new ActsAsTable writer object using the given ActsAsTable row model, output stream and options.
    #
    # @param [ActsAsTable::RowModel] row_model
    # @param [IO] output
    # @param [Hash<Symbol, Object>] options
    # @yieldparam [ActsAsTable::Writer] writer
    # @yieldreturn [void]
    # @return [ActsAsTable::Writer]
    def initialize(row_model, output = $stdout, **options, &block)
      @row_model, @output, @options = row_model, output, options.dup

      if block_given?
        self.write_prologue

        case block.arity
          when 1 then block.call(self)
          else self.instance_eval(&block)
        end

        self.write_epilogue
      end
    end

    # Delegates to the output stream for this ActsAsTable writer object.
    #
    # @param [String] method_name
    # @param [Array<Object>] args
    # @yield [*args, &block]
    # @yieldreturn [Object]
    # @return [Object]
    # @raise [NoMethodError]
    def method_missing(method_name, *args, &block)
      @output.respond_to?(method_name, false) ? @output.send(method_name, *args, &block) : super(method_name, *args, &block)
    end

    # Delegates to the output stream for this ActsAsTable writer object.
    #
    # @param [String] method_name
    # @param [Boolean] include_all
    # @return [Boolean]
    def respond_to?(method_name, include_all = false)
      @output.respond_to?(method_name, false) || super(method_name, include_all)
    end

    # Writes the epilogue to the output stream.
    #
    # @return [ActsAsTable::Writer]
    def write_epilogue
      self
    end

    # Writes the prologue to the output stream.
    #
    # @return [ActsAsTable::Writer]
    def write_prologue
      # @return [ActsAsTable::Headers::Array]
      headers = @row_model.to_headers

      headers.each do |header|
        self.write_row(header)
      end

      self
    end

    # Writes a record to the output stream.
    #
    # @param [ActiveRecord::Base] base
    # @return [ActsAsTable::Writer]
    # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
    def write_base(base)
      row = @row_model.to_row(base)

      self.write_row(row)
    end
    alias_method :<<, :write_base

    # Writes a row to the output stream.
    #
    # @param [Array<String, nil>, nil] row
    # @return [ActsAsTable::Writer]
    def write_row(row)
      raise ::NotImplementedError.new("#{self.class}#write_row")
    end
  end
end
