module ActsAsTable
  # ActsAsTable primary key (value provider).
  #
  # @!attribute [rw] method_name
  #   Returns the method name for this ActsAsTable primary key (a Ruby on Rails model column name).
  #
  #   @return [String]
  class PrimaryKey < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProvider::InstanceMethods
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.primary_keys_table

    acts_as_table_value_provider

    # Returns the ActsAsTable column model for this ActsAsTable primary key or `nil`.
    #
    # @return [ActsAsTable::ColumnModel, nil]
    belongs_to :column_model, **{
      class_name: 'ActsAsTable::ColumnModel',
      inverse_of: :primary_keys,
      required: false,
    }

    # Returns the ActsAsTable record model for this ActsAsTable primary key.
    belongs_to :record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :primary_keys,
      required: true,
    }

    # Returns the ActsAsTable values that have been provided by this ActsAsTable primary key.
    has_many :values, **{
      as: :value_provider,
      class_name: 'ActsAsTable::Value',
      dependent: :restrict_with_exception,
      foreign_key: 'value_provider_id',
      foreign_type: 'value_provider_type',
      inverse_of: :value_provider,
    }

    validates :method_name, **{
      presence: true,
    }

    validates :record_model_id, **{
      uniqueness: true,
    }

    validate :record_model_class_must_respond_to_method_name, **{
      if: ::Proc.new { |primary_key| primary_key.method_name.present? },
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

        [
          orig_value,
          false,
        ]
      end
    end

    private

    # @param [Class] klass
    # @param [String] column_name
    # @return [Boolean]
    def _column?(klass, column_name)
      klass.column_names.include?(column_name.to_s)
    end

    # @return [void]
    def record_model_class_must_respond_to_method_name
      self.record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |klass|
        unless _column?(klass, self.method_name)
          self.errors.add('method_name', :required)
        end
      }

      return
    end
  end
end
