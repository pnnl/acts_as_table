require 'singleton'

require 'active_record'
require 'active_record/version'
require 'active_support/core_ext/module'

begin
  require 'rails/engine'
  require 'acts_as_table/engine'
rescue ::LoadError
  # void
end

require 'acts_as_table/version'

# ActsAsTable is a Ruby on Rails plugin for working with tabular data.
module ActsAsTable
  extend ::ActiveSupport::Autoload

  # ActsAsTable serialization.
  autoload :Headers, 'acts_as_table/headers'
  autoload :Reader,  'acts_as_table/reader'
  autoload :Writer,  'acts_as_table/writer'

  # ActsAsTable utilities.
  autoload :Adapter, 'acts_as_table/adapter'
  autoload :Mapper,  'acts_as_table/mapper'
  autoload :Path,    'acts_as_table/path'

  # Finds an ActsAsTable serialization format module based on a symbolic name.
  #
  # @param [Symbol] format
  # @return [Module]
  # @raise [ArgumentError] If the given symbolic name is invalid.
  #
  # @example Find the ActsAsTable serialization format module for CSV format.
  #   ActsAsTable.for(:csv) #=> ActsAsTable::CSV
  #
  # @example Implement an ActsAsTable serialization format module.
  #   require 'active_support/core_ext/module'
  #
  #   module ActsAsTable
  #     # ActsAsTable serialization format module for "custom format."
  #     module CustomFormat
  #       extend ::ActiveSupport::Autoload
  #
  #       autoload :Reader, 'acts_as_table/custom_format/reader'
  #       autoload :Writer, 'acts_as_table/custom_format/writer'
  #
  #       # Returns the symbolic name for this ActsAsTable serialization format module.
  #       #
  #       # @return [Symbol]
  #       def format
  #         :custom_format
  #       end
  #
  #       # Returns a new ActsAsTable reader object for this serialization format module.
  #       #
  #       # @param [Array<Object>] args
  #       # @yieldparam [ActsAsTable::CustomFormat::Reader] reader
  #       # @yieldreturn [void]
  #       # @return [ActsAsTable::CustomFormat::Reader]
  #       def reader(*args, &block)
  #         Reader.new(*args, &block)
  #       end
  #
  #       # Returns a new ActsAsTable writer object for this serialization format module.
  #       #
  #       # @param [Array<Object>] args
  #       # @yieldparam [ActsAsTable::CustomFormat::Writer] writer
  #       # @yieldreturn [void]
  #       # @return [ActsAsTable::CustomFormat::Writer]
  #       def writer(*args, &block)
  #         Writer.new(*args, &block)
  #       end
  #     end
  #   end
  #
  def self.for(format)
    # @return [Hash<Symbol, Module>]
    module_by_format = self.config.formats.collect { |const_name|
      self.const_get(const_name, false)
    }.inject({}) { |acc, m|
      acc[m.format] ||= m
      acc
    }

    unless module_by_format.key?(format)
      raise ::ArgumentError.new("invalid format - expected: #{module_by_format.keys.inspect}, found: #{format.inspect}")
    end

    module_by_format[format]
  end

  # Uses the given ActsAsTable adapter object within the scope of the execution of the given block.
  #
  # If block given, yield with no arguments and return the result. Otherwise, return `nil`.
  #
  # @param [ActsAsTable::Adapter] new_adapter
  # @yieldreturn [Object]
  # @return [Object, nil]
  def self.use(new_adapter, &block)
    # @return [Object, nil]
    result = nil

    if block_given?
      # @return [ActsAsTable::Adapter]
      orig_adapter = self.config.adapter

      begin
        self.config.adapter = new_adapter

        result = block.call
      ensure
        self.config.adapter = orig_adapter
      end
    end

    result
  end

  autoload :VERSION

  # ActsAsTable configuration object.
  class Configuration
    include ::Singleton

    # @!attribute [rw] adapter
    #   Returns the ActsAsTable adapter object (default: `ActsAsTable::Adapter.new`).
    #
    #   @return [ActsAsTable::Adapter]
    attr_accessor :adapter

    # @!attribute [rw] formats
    #   Returns the non-inherited constant names for available ActsAsTable serialization format modules (default: `[]`).
    #
    #   @return [Array<Symbol>]
    attr_accessor :formats

    # @!attribute [rw] belongs_tos_table
    #   Returns the table name for the {ActsAsTable::BelongsTo} class (default: `:belongs_tos`).
    #
    #   @return [Symbol]
    # @!attribute [rw] column_models_table
    #   Returns the table name for the {ActsAsTable::ColumnModel} class (default: `:column_models`).
    #
    #   @return [Symbol]
    # @!attribute [rw] foreign_key_maps_table
    #   Returns the table name for the {ActsAsTable::ForeignKeyMap} class (default: `:foreign_key_maps`).
    #
    #   @return [Symbol]
    # @!attribute [rw] foreign_keys_table
    #   Returns the table name for the {ActsAsTable::ForeignKey} class (default: `:foreign_key`).
    #
    #   @return [Symbol]
    # @!attribute [rw] has_manies_table
    #   Returns the table name for the {ActsAsTable::HasMany} class (default: `:has_manies`).
    #
    #   @return [Symbol]
    # @!attribute [rw] has_many_targets_table
    #   Returns the table name for the {ActsAsTable::HasManyTarget} class (default: `:has_many_targets`).
    #
    #   @return [Symbol]
    # @!attribute [rw] lenses_table
    #   Returns the table name for the {ActsAsTable::Lense} class (default: `:lenses`).
    #
    #   @return [Symbol]
    # @!attribute [rw] primary_keys_table
    #   Returns the table name for the {ActsAsTable::PrimaryKey} class (default: `:primary_keys`).
    #
    #   @return [Symbol]
    # @!attribute [rw] record_errors_table
    #   Returns the table name for the {ActsAsTable::RecordError} class (default: `:record_errors`).
    #
    #   @return [Symbol]
    # @!attribute [rw] record_models_table
    #   Returns the table name for the {ActsAsTable::RecordModel} class (default: `:record_models`).
    #
    #   @return [Symbol]
    # @!attribute [rw] records_table
    #   Returns the table name for the {ActsAsTable::Record} class (default: `:records`).
    #
    #   @return [Symbol]
    # @!attribute [rw] row_models_table
    #   Returns the table name for the {ActsAsTable::RowModel} class (default: `:row_model`).
    #
    #   @return [Symbol]
    # @!attribute [rw] tables_table
    #   Returns the table name for the {ActsAsTable::Table} class (default: `:table`).
    #
    #   @return [Symbol]
    # @!attribute [rw] values_table
    #   Returns the table name for the {ActsAsTable::Value} class (default: `:value`).
    #
    #   @return [Symbol]
    %w(BelongsTo ColumnModel ForeignKey ForeignKeyMap HasMany HasManyTarget Lense PrimaryKey Record RecordError RecordModel RowModel Table Value).each do |class_name|
      attr_accessor :"#{class_name.pluralize.underscore}_table"
    end

    # Returns a new ActsAsTable configuration object.
    #
    # @return [ActsAsTable::Configuration]
    def initialize
      @adapter = ActsAsTable::Adapter.new

      @formats = []

      @belongs_tos_table = :belongs_tos
      @column_models_table = :column_models
      @foreign_key_maps_table = :foreign_key_maps
      @foreign_keys_table = :foreign_keys
      @has_manies_table = :has_manies
      @has_many_targets_table = :has_many_targets
      @lenses_table = :lenses
      @primary_keys_table = :primary_keys
      @record_errors_table = :record_errors
      @record_models_table = :record_models
      @records_table = :records
      @row_models_table = :row_models
      @tables_table = :tables
      @values_table = :values
    end
  end

  # Returns the ActsAsTable configuration object.
  #
  # @return [ActsAsTable::Configuration]
  def self.config
    Configuration.instance
  end

  # Configure ActsAsTable.
  #
  # @yieldreturn [void]
  # @return [void]
  #
  # @example Set the ActsAsTable adapter object.
  #   class CustomActsAsTableAdapter < ActsAsTable::Adapter
  #     # ...
  #   end
  #
  #   ActsAsTable.configure do
  #     config.adapter = CustomActsAsTableAdapter.new
  #   end
  #
  # @example Register an ActsAsTable serialization format module.
  #   require 'acts_as_table_custom_format' # underscore
  #
  #   ActsAsTable.configure do
  #     config.formats << :CustomFormat # constantize
  #   end
  #
  # @example Prefix the table names for the ActsAsTable model classes.
  #   ActsAsTable.configure do
  #     config.methods.select { |method_name| method_name.to_s.ends_with?("_table") }.each do |method_name|
  #       config.send(:"#{method_name}=", :"prefix_#{config.send(method_name)}")
  #     end
  #   end
  #
  def self.configure(&block)
    if block_given?
      self.instance_eval(&block)
    end

    return
  end

  # Delegates to ActsAsTable configuration object.
  #
  # @param [String] method_name
  # @param [Array<Object>] args
  # @yield [*args, &block]
  # @yieldreturn [Object]
  # @return [Object]
  # @raise [NoMethodError]
  def self.method_missing(method_name, *args, &block)
    self.config.respond_to?(method_name, false) ? self.config.send(method_name, *args, &block) : super(method_name, *args, &block)
  end

  # Delegates to ActsAsTable configuration object.
  #
  # @param [String] method_name
  # @param [Boolean] include_all
  # @return [Boolean]
  def self.respond_to?(method_name, include_all = false)
    self.config.respond_to?(method_name, false) || super(method_name, include_all)
  end
end
