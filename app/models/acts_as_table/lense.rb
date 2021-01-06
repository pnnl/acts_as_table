module ActsAsTable
  # ActsAsTable attribute accessor (value provider).
  #
  # @note The name "Lense" was selected for 2 reasons: similarity of behavior of this class and the corresponding type(s) in the Haskell package, [lens](https://hackage.haskell.org/package/lens); and that "Attribute" is not allowed as a Ruby on Rails model class name (because the corresponding table name would be "attributes", which would conflict with {ActiveRecord::AttributeMethods#attributes}).
  #
  # @!attribute [rw] default_value
  #   Returns the default value for this ActsAsTable attribute accessor.
  #
  #   @return [String, nil]
  # @!attribute [rw] method_name
  #   Returns the method name for this ActsAsTable attribute accessor (an `attr_reader` or a Ruby on Rails model column name).
  #
  #   @return [String]
  class Lense < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProvider::InstanceMethods
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.lenses_table

    acts_as_table_value_provider

    # Returns the ActsAsTable column model for this ActsAsTable attribute accessor or `nil`.
    #
    # @return [ActsAsTable::ColumnModel, nil]
    belongs_to :column_model, **{
      class_name: 'ActsAsTable::ColumnModel',
      inverse_of: :lenses,
      required: false,
    }

    # Returns the ActsAsTable record model for this ActsAsTable attribute accessor.
    belongs_to :record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :lenses,
      required: true,
    }

    # Returns the ActsAsTable values that have been provided by this ActsAsTable attribute accessor.
    has_many :values, **{
      as: :value_provider,
      class_name: 'ActsAsTable::Value',
      dependent: :restrict_with_exception,
      foreign_key: 'value_provider_id',
      foreign_type: 'value_provider_type',
      inverse_of: :value_provider,
    }

    validates :default_value, **{
      presence: {
        unless: :column_model,
      },
    }

    validates :method_name, **{
      presence: true,
    }

    validate :record_model_class_must_respond_to_method_name, **{
      if: ::Proc.new { |lense| lense.method_name.present? },
    }

    protected

    # @param [ActiveRecord::Base, nil] base
    # @return [Object, nil]
    def _get_value(base = nil)
      if base.nil?
        nil
      else
        base.send(:"#{self.method_name}")
      end
    end

    # @param [ActiveRecord::Base, nil] base
    # @param [Object, nil] new_value
    # @return [Array<Object>]
    def _set_value(base = nil, new_value = nil)
      if base.nil?
        [
          nil,
          false,
        ]
      else
        # @return [Object, nil]
        orig_value = _get_value(base)

        # @return [Boolean]
        changed = !self.column_model.nil? && !(orig_value.nil? ? new_value.nil? : (new_value.nil? ? false : orig_value.to_s.eql?(new_value.to_s)))

        [
          base.send(:"#{self.method_name}=", new_value),
          changed,
        ]
      end
    end

    private

    # @param [Class] klass
    # @param [String] attribute_name
    # @return [Boolean]
    def _attr_accessor?(klass, attribute_name)
      [
        :"#{attribute_name}",
        :"#{attribute_name}=",
      ].all? { |sym|
        klass.instance_methods.include?(sym)
      }
    end

    # @param [Class] klass
    # @param [String] column_name
    # @return [Boolean]
    def _column?(klass, column_name)
      klass.column_names.include?(column_name.to_s)
    end

    # @return [void]
    def record_model_class_must_respond_to_method_name
      self.record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |klass|
        unless _attr_accessor?(klass, self.method_name) || _column?(klass, self.method_name)
          self.errors.add('method_name', :required)
        end
      }

      return
    end
  end
end
