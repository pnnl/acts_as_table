module ActsAsTable
  # ActsAsTable foreign key map.
  #
  # @!attribute [rw] extended
  #   Returns `true` if the source value for this ActsAsTable foreign key map is an extended regular expression. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  # @!attribute [rw] ignore_case
  #   Returns `true` if the source value for this ActsAsTable foreign key map is a regular expression that ignores character case. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  # @!attribute [rw] multiline
  #   Returns `true` if the source value for this ActsAsTable foreign key map is a multiline regular expression. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  # @!attribute [rw] position
  #   Returns the position of this ActsAsTable foreign key map.
  #
  #   @return [Integer]
  # @!attribute [rw] regexp
  #   Returns `true` if the source value for this ActsAsTable foreign key map is a regular expression. Otherwise, returns `false`.
  #
  #   @return [Boolean]
  # @!attribute [rw] source_value
  #   Returns the source value for this ActsAsTable foreign key map.
  #
  #   @return [Boolean]
  # @!attribute [rw] target_value
  #   Returns the target value for this ActsAsTable foreign key map.
  #
  #   @note If the source value for this ActsAsTable foreign key map is a regular expression, then the target value may reference any capture groups.
  #
  #   @return [Boolean]
  class ForeignKeyMap < ::ActiveRecord::Base
    # @!parse
    #   include ActsAsTable::ValueProvider
    #   include ActsAsTable::ValueProviderAssociationMethods

    self.table_name = ActsAsTable.foreign_key_maps_table

    # Returns the ActsAsTable foreign key for this map.
    belongs_to :foreign_key, **{
      class_name: 'ActsAsTable::ForeignKey',
      inverse_of: :foreign_key_maps,
      required: true,
    }

    # validates :extended, **{}

    # validates :ignore_case, **{}

    # validates :multiline, **{}

    validates :position, **{
      numericality: {
        greater_than_or_equal_to: 1,
        only_integer: true,
      },
      presence: true,
      uniqueness: {
        scope: ['foreign_key_id'],
      },
    }

    # validates :regexp, **{}

    validates :source_value, **{
      presence: true,
      uniqueness: {
        scope: ['foreign_key_id'],
      },
    }

    validates :target_value, **{
      presence: true,
    }

    validate :source_value_as_regexp_must_be_valid, **{
      if: ::Proc.new { |foreign_key_map| foreign_key_map.source_value.present? },
    }

    # Returns the source value for this ActsAsTable foreign key map as a regular expression.
    #
    # @return [Regexp]
    # @raise [RegexpError]
    def source_value_as_regexp
      # @return [String]
      pattern = self.source_value.to_s

      unless self.regexp?
        pattern = "\\A#{::Regexp.quote(pattern)}\\z"
      end

      # @return [Integer]
      flags = {
        :extended => :EXTENDED,
        :ignore_case => :IGNORECASE,
        :multiline => :MULTILINE,
      }.each_pair.inject(0) { |acc, pair|
        method_name, const_name = *pair

        self.send(:"#{method_name}?") ? (acc | ::Regexp.const_get(const_name, false)) : acc
      }

      ::Regexp.new(pattern, flags)
    end

    private

    # @return [void]
    def source_value_as_regexp_must_be_valid
      begin
        self.source_value_as_regexp
      rescue ::RegexpError
        self.errors.add('source_value', :invalid)
      end

      return
    end
  end
end
