module ActsAsTable
  # ActsAsTable row model (value provider).
  #
  # @!attribute [rw] name
  #   Returns the name of this ActsAsTable row model.
  #
  #   @return [String]
  class RowModel < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProvider::InstanceMethods
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.row_models_table

    acts_as_table_value_provider

    # Returns the root ActsAsTable record model for this ActsAsTable row model.
    belongs_to :root_record_model, **{
      class_name: 'ActsAsTable::RecordModel',
      inverse_of: :row_models_as_root,
      required: true,
    }

    # Returns the ActsAsTable column models for this ActsAsTable row model.
    has_many :column_models, -> { order(position: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::ColumnModel',
      dependent: :destroy,
      foreign_key: 'row_model_id',
      inverse_of: :row_model,
      validate: true,
    }

    # Returns the ActsAsTable singular macro associations for this ActsAsTable row model.
    has_many :belongs_tos, **{
      autosave: true,
      class_name: 'ActsAsTable::BelongsTo',
      dependent: :destroy,
      foreign_key: 'row_model_id',
      inverse_of: :row_model,
      validate: true,
    }

    # Returns the ActsAsTable collection macro associations for this ActsAsTable row model.
    has_many :has_manies, **{
      autosave: true,
      class_name: 'ActsAsTable::HasMany',
      dependent: :destroy,
      foreign_key: 'row_model_id',
      inverse_of: :row_model,
      validate: true,
    }

    # Returns the ActsAsTable record models for this ActsAsTable row model.
    has_many :record_models, **{
      autosave: true,
      class_name: 'ActsAsTable::RecordModel',
      dependent: :destroy,
      foreign_key: 'row_model_id',
      inverse_of: :row_model,
      validate: true,
    }

    # Returns the ActsAsTable tables that have been provided by this ActsAsTable row model.
    has_many :tables, **{
      class_name: 'ActsAsTable::Table',
      dependent: :restrict_with_exception,
      foreign_key: 'row_model_id',
      inverse_of: :row_model,
    }

    validates :name, **{
      presence: true,
    }

    validate :record_models_includes_root_record_model, **{
      if: ::Proc.new { |row_model| row_model.root_record_model.present? },
    }

    # Draw an ActsAsTable row model.
    #
    # @yieldparam [ActsAsTable::Mapper::RowModel] row_model_mapper
    # @yieldreturn [void]
    # @return [void]
    #
    # @see ActsAsTable::Mapper::RowModel
    def draw(&block)
      ActsAsTable::Mapper::RowModel.new(self, &block)

      return
    end

    # Returns the ActsAsTable headers array object for the ActsAsTable column models for this ActsAsTable row model.
    #
    # @return [ActsAsTable::Headers::Array]
    def to_headers
      ActsAsTable::Headers::Array.new(self.column_models)
    end

    # Returns the ActsAsTable records for the given row.
    #
    # @param [Array<String, nil>, nil] row
    # @param [ActiveRecord::Relation<ActsAsTable::Record>] records
    # @return [Array<ActsAsTable::Record>]
    # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
    def from_row(row = [], records = ActsAsTable::Record.all)
      # @return [Hash<ActsAsTable::RecordModel, Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>>]
      value_by_record_model_and_value_provider = self.record_models.inject({}) { |acc_for_record_model, record_model|
        acc_for_record_model[record_model] = record_model.each_acts_as_table_value_provider(except: [:row_model]).inject({}) { |acc_for_value_provider, value_provider|
          acc_for_value_provider[value_provider] = value_provider.column_model.try { |column_model|
            # @return [Integer]
            index = column_model.position - 1

            if (index >= 0) && (index < row.size)
              row[index]
            else
              nil
            end
          }

          acc_for_value_provider
        }

        acc_for_record_model
      }

      # @return [ActsAsTable::ValueProvider::WrappedValue]
      hash = ActsAsTable.adapter.set_value_for(self, nil, value_by_record_model_and_value_provider, default: true)

      hash.target_value.each_pair.collect { |pair|
        record_model, pair = *pair

        new_record_or_persisted, pair_by_value_provider = *pair

        records.build(record_model_changed: pair_by_value_provider.changed?) do |record|
          record.base = new_record_or_persisted

          record.record_model = record_model

          # @note {ActiveRecord::Validations#validate} is an alias for {ActiveRecord::Validations#valid?} that does not raise an exception when the record is invalid.
          new_record_or_persisted.validate

          # @return [Array<String>]
          attribute_names = []

          pair_by_value_provider.target_value.each do |value_provider, target_value|
            # @return [String]
            attribute_name = \
              case value_provider
              when ActsAsTable::ForeignKey
                klass = record_model.class_name.constantize

                reflection = klass.reflect_on_association(value_provider.method_name)

                reflection.foreign_key
              else
                value_provider.method_name
              end

            attribute_names << attribute_name

            record.values.build(target_value: target_value.target_value, value_provider_changed: target_value.changed?) do |value|
              value.value_provider = value_provider

              value_provider.column_model.try { |column_model|
                value.column_model = column_model

                value.position = column_model.position

                # @return [Integer]
                index = column_model.position - 1

                value.source_value = \
                  if (index >= 0) && (index < row.size)
                    row[index]
                  else
                    nil
                  end
              }

              new_record_or_persisted.errors[attribute_name].each do |message|
                value.record_errors.build(attribute_name: attribute_name, message: message)
              end
            end
          end

          new_record_or_persisted.errors.each do |attribute_name, message|
            unless attribute_names.include?(attribute_name.to_s)
              record.record_errors.build(attribute_name: attribute_name, message: message)
            end
          end
        end
      }
    end

    # Returns the row for the given record.
    #
    # @param [ActiveRecord::Base, nil] base
    # @return [Array<String, nil>, nil]
    # @raise [ArgumentError]
    def to_row(base = nil)
      # @return [ActsAsTable::ValueProvider::WrappedValue]
      value_by_record_model_and_value_provider = ActsAsTable.adapter.get_value_for(self, base, default: false)

      # @return [Integer]
      column_models_maximum_position = (self.persisted? ? self.column_models.maximum(:position) : self.column_models.to_a.collect(&:position).max) || 0

      # @return [Array<String, nil>]
      row = ::Array.new(column_models_maximum_position) { nil }

      self.record_models.each do |record_model|
        # @return [ActsAsTable::ValueProvider::WrappedValue, nil]
        value_by_value_provider = value_by_record_model_and_value_provider.target_value.try(:[], record_model)

        record_model.each_acts_as_table_value_provider(except: [:row_model]) do |value_provider|
          value_provider.column_model.try { |column_model|
            # @return [Integer]
            index = column_model.position - 1

            if (index >= 0) && (index < column_models_maximum_position)
              # @return [ActsAsTable::ValueProvider::WrappedValue, nil]
              value = value_by_value_provider.try(:target_value).try(:[], value_provider)

              row[index] = value.try(:target_value)
            end
          }
        end
      end

      row.all?(&:nil?) ? nil : row
    end

    include ActsAsTable::RecordModelClassMethods

    # Returns `true` if the given ActsAsTable record model is reachable from the root ActsAsTable record model for this ActsAsTable row model. Otherwise, returns `false`.
    #
    # @param [ActsAsTable::RecordModel] record_model
    # @return [Boolean]
    def reachable_record_model?(record_model)
      self.class.reachable_record_model_for?(self.root_record_model, record_model)
    end

    # Returns the ActsAsTable record models that are reachable from the root ActsAsTable record model for this ActsAsTable row model (in topological order).
    #
    # @return [Array<ActsAsTable::RecordModel>]
    def reachable_record_models
      self.class.reachable_record_models_for(self.root_record_model)
    end

    # Get the value for the given record using the given options.
    #
    # @param [ActiveRecord::Base, nil] base
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    # @raise [ArgumentError]
    def get_value(base = nil, **options)
      self.class.get_value_for(self.root_record_model, base, **options)
    end

    # Set the new value for the given record using the given options.
    #
    # @param [ActiveRecord::Base, nil] base
    # @param [Hash<ActsAsTable::RecordModel, Hash<ActsAsTable::ValueProvider::InstanceMethods, Object>>] new_value_by_record_model_and_value_provider
    # @param [Hash<Symbol, Object>] options
    # @option options [Boolean] :default
    # @return [ActsAsTable::ValueProvider::WrappedValue]
    # @raise [ArgumentError]
    def set_value(base = nil, new_value_by_record_model_and_value_provider = {}, **options)
      self.class.set_value_for(self.root_record_model, base, new_value_by_record_model_and_value_provider, **options)
    end

    private

    # @return [void]
    def record_models_includes_root_record_model
      unless self.record_models.include?(self.root_record_model)
        self.errors.add('root_record_model_id', :inclusion)
      end

      return
    end
  end
end
