module ActsAsTable
  # ActsAsTable singular macro association.
  #
  # @!attribute [rw] macro
  #   Returns the symbolic name for the macro for this ActsAsTable singular macro association.
  #
  #   @note The macro must be either `:belongs_to` or `:has_one`.
  #
  #   @return [String]
  # @!attribute [rw] method_name
  #   Returns the method name for this ActsAsTable singular macro association.
  #
  #   @return [String]
  class BelongsTo < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.belongs_tos_table

    # Returns the ActsAsTable row model for this ActsAsTable singular macro association.
    belongs_to :row_model, **{
      class_name: 'ActsAsTable::RowModel',
      inverse_of: :belongs_tos,
      required: true,
    }

    # Returns the source ActsAsTable record model for this ActsAsTable singular macro association.
    belongs_to :source_record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :belongs_tos_as_source,
      required: true,
    }

    # Returns the target ActsAsTable record model for this ActsAsTable singular macro association.
    belongs_to :target_record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :belongs_tos_as_target,
      required: true,
    }

    validates :macro, **{
      inclusion: {
        in: ['belongs_to', 'has_one'],
      },
      presence: true,
    }

    validates :method_name, **{
      presence: true,
    }

    validate :macro_and_method_name_must_be_valid_association, **{
      if: ::Proc.new { |belongs_to| belongs_to.macro.present? && belongs_to.method_name.present? },
    }

    private

    # @return [void]
    def macro_and_method_name_must_be_valid_association
      self.source_record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |source_klass|
        # @return [ActiveRecord::Reflection::MacroReflection]
        reflection = source_klass.reflect_on_association(self.method_name)

        if reflection.nil?
          self.errors.add('method_name', :required)
        elsif self.macro.eql?(reflection.macro.to_s)
          self.target_record_model.try { |record_model| record_model.class_name.constantize rescue nil }.try { |target_klass|
            unless reflection.klass == target_klass
              self.errors.add('target_record_model_id', :invalid)
            end
          }
        else
          self.errors.add('method_name', :invalid)
        end
      }

      return
    end
  end
end
