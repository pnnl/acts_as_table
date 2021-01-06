module ActsAsTable
  # ActsAsTable table.
  #
  # @!attribute [r] records_count
  #   Returns the number of ActsAsTable records for this ActsAsTable table.
  #
  #   @return [Integer]
  class Table < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.tables_table

    # Returns the ActsAsTable row model for this ActsAsTable table.
    belongs_to :row_model, **{
      class_name: 'ActsAsTable::RowModel',
      inverse_of: :tables,
      required: true,
    }

    # Returns the ActsAsTable records for this ActsAsTable table.
    has_many :records, -> { order(position: :asc) }, **{
      autosave: true,
      class_name: 'ActsAsTable::Record',
      dependent: :destroy,
      foreign_key: 'table_id',
      inverse_of: :table,
      validate: true,
    }

    # Returns the ActsAsTable records for the given row.
    #
    # @param [Array<String, nil>, nil] row
    # @return [Array<ActsAsTable::Record>]
    # @raise [ArgumentError] If the name of a class for a given record does not match the class name for the corresponding ActsAsTable record model.
    def from_row(row = [])
      self.row_model.from_row(row, self.records)
    end
  end
end
