module ActsAsTable
  # ActsAsTable value provider association methods (concern).
  module ValueProviderAssociationMethods
    extend ::ActiveSupport::Concern

    class_methods do
      # Returns an array of {ActiveRecord::Reflection::MacroReflection} objects for all ActsAsTable value provider associations in the class.
      #
      # @note If you only want to reflect on a certain association type, pass in the symbol (`:has_many`, `:has_one`, `:belongs_to`) as the first parameter.
      #
      # @param [Symbol, nil] macro
      # @param [Hash<Symbol, Object>] options
      # @option options [Array<Symbol>, nil] :only
      # @option options [Array<Symbol>, nil] :except
      # @return [Array<ActiveRecord::Reflection::MacroReflection>]
      def reflect_on_acts_as_table_value_provider_associations(macro = nil, **options)
        options.assert_valid_keys(:except, :only)

        self.reflect_on_all_associations(macro).select { |reflection|
          reflection.klass.acts_as_table_value_provider?
        }.select { |reflection|
          (options[:except].nil? || !options[:except].collect(&:to_sym).include?(reflection.name.to_sym)) && (options[:only].nil? || options[:only].collect(&:to_sym).include?(reflection.name.to_sym))
        }
      end
    end

    # Enumerates all associated records for all ActsAsTable value provider associations in the class.
    #
    # @note If you only want to reflect on a certain association type, pass in the symbol (`:has_many`, `:has_one`, `:belongs_to`) as the first parameter.
    #
    # @param [Symbol, nil] macro
    # @param [Hash<Symbol, Object>] options
    # @option options [Array<Symbol>, nil] :only
    # @option options [Array<Symbol>, nil] :except
    # @return [Enumerable<ActsAsTable::ValueProvider::InstanceMethods>]
    def each_acts_as_table_value_provider(macro = nil, **options, &block)
      ::Enumerator.new { |enumerator|
        {
          belongs_to: [],
          has_one: [],
          has_many: [:each],
          has_and_belongs_to_many: [:each],
        }.each do |method_name, args|
          if macro.nil? || (macro == method_name)
            reflections = self.class.reflect_on_acts_as_table_value_provider_associations(method_name, **options)

            reflections.each do |reflection|
              self.send(reflection.name).try(*args) { |value_provider|
                enumerator << value_provider
              }
            end
          end
        end
      }.each(&block)
    end
  end
end
