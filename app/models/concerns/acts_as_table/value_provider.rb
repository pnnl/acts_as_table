module ActsAsTable
  # ActsAsTable value provider (concern).
  #
  # @note The minimum implementation is the protected `_get_value` and `_set_value` instance methods.
  module ValueProvider
    extend ::ActiveSupport::Concern

    class_methods do
      # Returns `true` if the class is an ActsAsTable value provider. Otherwise, returns `false`.
      #
      # @return [Boolean]
      def acts_as_table_value_provider?
        false
      end

      # Mark the class as an ActsAsTable value provider.
      #
      # @return [void]
      def acts_as_table_value_provider
        unless self.acts_as_table_value_provider?
          self.class_eval do
            def self.acts_as_table_value_provider?
              true
            end
          end

          self.include(InstanceMethods)
        end

        return
      end
    end

    # ActsAsTable wrapped value object.
    #
    # @!attribute [r] value_provider
    #   Returns the ActsAsTable value provider for this ActsAsTable wrapped value object.
    #
    #   @return [ActsAsTable::ValueProvider::InstanceMethods]
    # @!attribute [r] base
    #   Returns the record for this ActsAsTable wrapped value object.
    #
    #   @return [ActiveRecord::Base, nil]
    # @!attribute [r] source_value
    #   Returns the source value of this ActsAsTable wrapped value object.
    #
    #   @return [Object, nil]
    # @!attribute [r] target_value
    #   Returns the target value of this ActsAsTable wrapped value object.
    #
    #   @return [Object, nil]
    # @!attribute [r] options
    #   Returns the options for this ActsAsTable wrapped value object.
    #
    #   @return [Hash<Symbol, Object>]
    class WrappedValue
      attr_reader :value_provider, :base, :source_value, :target_value, :options

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
      def initialize(value_provider, base = nil, source_value = nil, target_value = nil, **options)
        options.assert_valid_keys(:changed, :default)

        @value_provider, @base, @source_value, @target_value, @options = value_provider, base, source_value, target_value, options.dup
      end

      # Sets the ':changed' option for this ActsAsTable wrapped value object to 'true'.
      #
      # @return [Boolean]
      def changed!
        @options[:changed] = true
      end

      # Returns 'true' if the value of this ActsAsTable wrapped value object has changed. Otherwise, returns 'false'.
      #
      # @return [Boolean]
      def changed?
        !!@options[:changed]
      end
      alias_method :changed, :changed?

      # Returns 'true' if the value of this ActsAsTable wrapped value object is the default value for the value provider. Otherwise, returns 'false'.
      #
      # @return [Boolean]
      def default?
        !!@options[:default]
      end
      alias_method :default, :default?
    end

    # ActsAsTable value provider instance methods (concern).
    #
    # @note The design of this module is inspired by the the Haskell package, [lens](https://hackage.haskell.org/package/lens).
    module InstanceMethods
      extend ::ActiveSupport::Concern

      # Reads the value for the given record using the given options.
      #
      # @param [ActiveRecord::Base, nil] base
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      def get_value(base = nil, **options)
        options.assert_valid_keys(:default)

        if base.nil?
          return ActsAsTable.adapter.wrap_value_for(self, base, nil, nil)
        end

        # @return [Object, nil]
        source_value = _get_value(base)

        # @return [Object, nil]
        target_value = _modify_get_value_before_default(source_value)

        default = \
          if options[:default].try { |boolean_or_proc| _should_default?(target_value, boolean_or_proc) } && self.respond_to?(:default_value)
            target_value = self.default_value

            true
          else
            false
          end

        ActsAsTable.adapter.wrap_value_for(self, base, source_value, target_value, default: default)
      end

      # Writes the new value for the given record using the given options.
      #
      # @param [ActiveRecord::Base, nil] base
      # @param [Object, nil] new_value
      # @param [Hash<Symbol, Object>] options
      # @option options [Boolean] :default
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      def set_value(base = nil, new_value = nil, **options)
        options.assert_valid_keys(:default)

        if base.nil?
          return ActsAsTable.adapter.wrap_value_for(self, base, nil, nil)
        end

        # @return [Object, nil]
        target_value = _modify_set_value_before_default(new_value)

        changed = false

        default = \
          if options[:default].try { |boolean_or_proc| _should_default?(target_value, boolean_or_proc) } && self.respond_to?(:default_value)
            target_value = self.default_value

            true
          else
            false
          end

        target_value, changed = *_set_value(base, target_value)

        ActsAsTable.adapter.wrap_value_for(self, base, new_value, target_value, changed: changed, default: default)
      end

      protected

      # @param [ActiveRecord::Base, nil] base
      # @return [Object, nil]
      def _get_value(base = nil)
        nil
      end

      # @param [Object, nil] new_value
      # @return [Object, nil]
      def _modify_get_value_before_default(new_value = nil)
        new_value
      end

      # @param [Object, nil] new_value
      # @return [Object, nil]
      def _modify_set_value_before_default(new_value = nil)
        new_value
      end

      # @param [ActiveRecord::Base, nil] base
      # @param [Object, nil] new_value
      # @return [Array<Object>]
      def _set_value(base = nil, new_value = nil)
        # @return [Object, nil]
        orig_value = _get_value(base)

        [
          orig_value,
          false,
        ]
      end

      private

      # @param [Object, nil] new_value
      # @param [#call, nil] default
      # @return [Boolean]
      def _should_default?(new_value = nil, default = nil)
        if default.respond_to?(:call)
          if default.respond_to?(:arity)
            case default.arity
              when 1 then default.call(new_value)
              else new_value.instance_exec(&default)
            end
          else
            default.call(new_value)
          end
        else
          new_value.nil?
        end
      end
    end
  end
end
