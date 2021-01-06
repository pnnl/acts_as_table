module ActsAsTable
  # ActsAsTable record.
  #
  # @!attribute [rw] position
  #   Returns the position of this ActsAsTable record.
  #
  #   @return [Integer]
  # @!attribute [r] record_errors_count
  #   Returns the number of ActsAsTable record errors for this ActsAsTable record.
  #
  #   @return [Integer]
  # @!attribute [rw] record_model_changed
  #   Returns `true` if the ActsAsTable record model changed the record for this ActsAsTable record. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  # @!attribute [r] values_count
  #   Returns the number of ActsAsTable values for this ActsAsTable record.
  #
  #   @return [Integer]
  class Record < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.records_table

    # Returns the record for this ActsAsTable record or `nil`.
    #
    # @return [ActiveRecord::Base, nil]
    belongs_to :base, **{
      polymorphic: true,
      required: false,
    }

    # Returns the ActsAsTable record model for this ActsAsTable record.
    belongs_to :record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :records,
      required: true,
    }

    # Returns the ActsAsTable table for this ActsAsTable record.
    belongs_to :table, **{
      class_name: 'ActsAsTable::Table',
      counter_cache: 'records_count',
      inverse_of: :records,
      required: true,
    }

    # Returns the ActsAsTable record errors for this ActsAsTable record.
    has_many :record_errors, -> { order(attribute_name: :asc, message: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::RecordError',
      dependent: :destroy,
      foreign_key: 'record_id',
      inverse_of: :record,
      validate: true,
    }

    # Returns the ActsAsTable values for this ActsAsTable record.
    has_many :values, -> { order(position: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::Value',
      dependent: :destroy,
      foreign_key: 'record_id',
      inverse_of: :record,
      validate: true,
    }

    validates :position, **{
      numericality: {
        greater_than_or_equal_to: 1,
        only_integer: true,
      },
      presence: true,
      uniqueness: {
        scope: ['table_id', 'record_model_id'],
      },
    }

    # validates :record_model_changed, **{}

    validate :record_must_be_valid_class, :record_model_must_belong_to_row_model_for_table, **{
      if: ::Proc.new { |record| record.record_model.present? },
    }

    private

    # @return [void]
    def record_must_be_valid_class
      self.record_type.try { |record_type|
        unless record_type.eql?(self.record_model.class_name)
          self.errors.add('record_type', :invalid)
        end
      }
    end

    # @return [void]
    def record_model_must_belong_to_row_model_for_table
      self.table.try(:row_model).try(:record_models).try { |record_models|
        unless record_models.include?(self.record_model)
          self.errors.add('record_model_id', :invalid)
        end
      }

      return
    end
  end
end
