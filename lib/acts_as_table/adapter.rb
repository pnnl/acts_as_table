module ActsAsTable
  # ActsAsTable adapter object.
  #
  # @note The "adapter pattern" is a software design pattern that is used to make existing classes work with others without modifying their source code.
  #
  # @see ActsAsTable.use
  # @see ActsAsTable::Configuration#adapter
  # @see ActsAsTable::Configuration#adapter=
  class Adapter
    # Finds the first record with the given attributes, or creates a record with the attributes if one is not found.
    #
    # @param [ActsAsTable::RecordModel] record_model
    # @param [#find_or_initialize_by] callee
    # @param [Symbol] method_name
    # @param [Array<Object>] args
    # @yieldparam [ActiveRecord::Base] base
    # @yieldreturn [void]
    # @return [ActiveRecord::Base]
    def find_or_initialize_by_for(record_model, callee, method_name = :find_or_initialize_by, *args, &block)
      callee.send(method_name, *args, &block)
    end

    # Initializes new record from relation while maintaining the current scope.
    #
    # @param [ActsAsTable::RecordModel] record_model
    # @param [#new] callee
    # @param [Symbol] method_name
    # @param [Array<Object>] args
    # @yieldparam [ActiveRecord::Base] base
    # @yieldreturn [void]
    # @return [ActiveRecord::Base]
    def new_for(record_model, callee, method_name = :new, *args, &block)
      callee.send(method_name, *args, &block)
    end

    # Get the value for the given record using the given options.
    #
    # @param [#get_value] value_provider
    # @param [ActiveRecord::Base, nil] base
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    def get_value_for(value_provider, base = nil, **options)
      value_provider.get_value(base, **options)
    end

    # Set the new value for the given record using the given options.
    #
    # @param [#set_value] value_provider
    # @param [ActiveRecord::Base, nil] base
    # @param [Object, nil] new_value
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    def set_value_for(value_provider, base = nil, new_value = nil, **options)
      value_provider.set_value(base, new_value, **options)
    end

    # Returns a new ActsAsTable wrapped value object.
    #
    # @param [ActsAsTable::ValueProvider::InstanceMethods] value_provider
    # @param [ActiveRecord::Base, nil] base
    # @param [Object, nil] source_value
    # @param [Object, nil] target_value
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :changed
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    def wrap_value_for(value_provider, base = nil, source_value = nil, target_value = nil, **options)
      ActsAsTable::ValueProvider::WrappedValue.new(value_provider, base, source_value, target_value, **options)
    end

    def classify_for(value_provider, table_name)
      table_name.classify
    end

    def tableize_for(value_provider, class_name)
      class_name.tableize
    end
  end
end
