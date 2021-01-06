module ActsAsTable
  # ActsAsTable path object.
  #
  # @!attribute [r] klass
  #   Returns the class for this ActsAsTable path object.
  #
  #   @return [Class]
  # @!attribute [r] parent
  #   Returns the parent of this ActsAsTable path object or `nil`, if this ActsAsTable path object is the start.
  #
  #   @return [ActsAsTable::Path, nil]
  # @!attribute [r] options
  #   Returns the options for this ActsAsTable path object.
  #
  #   @return [Hash<Symbol, Object>]
  # @!method belongs_to(method_name, **options)
  #   Reflect on a `:belongs_to` association using this ActsAsTable path object.
  #
  #   @param [#to_s] method_name
  #   @param [Hash<Symbol, Object>] options
  #   @option options [Object] :data
  #   @return [ActsAsTable::Path]
  #   @raise [ArgumentError] If the association is invalid.
  # @!method has_one(method_name, **options)
  #   Reflect on a `:has_one` association using this ActsAsTable path object.
  #
  #   @param [#to_s] method_name
  #   @param [Hash<Symbol, Object>] options
  #   @option options [Object] :data
  #   @return [ActsAsTable::Path]
  #   @raise [ArgumentError] If the association is invalid.
  # @!method has_many(method_name, index, **options)
  #   Reflect on a `:has_many` association using this ActsAsTable path object.
  #
  #   @param [#to_s] method_name
  #   @param [Integer] index
  #   @param [Hash<Symbol, Object>] options
  #   @option options [Object] :data
  #   @return [ActsAsTable::Path]
  #   @raise [ArgumentError] If the association is invalid.
  # @!method has_and_belongs_to_many(method_name, index, **options)
  #   Reflect on a `:has_and_belongs_to_many` association using this ActsAsTable path object.
  #
  #   @param [#to_s] method_name
  #   @param [Integer] index
  #   @param [Hash<Symbol, Object>] options
  #   @option options [Object] :data
  #   @return [ActsAsTable::Path]
  #   @raise [ArgumentError] If the association is invalid.
  class Path
    include ::Enumerable

    attr_reader :klass, :parent, :options

    # Returns a new ActsAsTable path object for the given class, parent (optional) and options.
    #
    # @param [Class] klass
    # @param [ActsAsTable::Path, nil] parent
    # @param [Hash<Symbol, Object>] options
    # @option options [#to_s] :macro
    # @option options [#to_s] :method_name
    # @option options [Integer, nil] :index
    # @option options [Object] :data
    # @return [ActsAsTable::Path]
    def initialize(klass, parent = nil, **options)
      options.assert_valid_keys(:data, :index, :macro, :method_name)

      @klass, @parent, @options = klass, parent, options.dup
    end

    # Enumerate this ActsAsTable path object, its parent, its grandparent, etc.
    #
    # @yieldparam [ActsAsTable::Path] path
    # @yieldreturn [void]
    # @return [Enumerable<ActsAsTable::Path>]
    def each(&block)
      ::Enumerator.new { |enumerator|
        # @return [ActsAsTable::Path, nil]
        path = self

        until path.nil?
          enumerator << path

          # @return [ActsAsTable::Path, nil]
          path = path.parent
        end
      }.each(&block)
    end

    # Returns the symbolic name for this ActsAsTable path object.
    #
    # @return [Symbol]
    def to_sym
      if self.parent.nil?
        nil
      else
        self.inject([]) { |acc, path|
          acc << path.options.values_at(:method_name, :index)
          acc
        }.reverse.flatten(1).compact.collect(&:to_s).join('_').to_sym
      end
    end

    # Terminates this ActsAsTable path object and returns its symbolic name.
    #
    # @param [#to_s] method_name
    # @return [Symbol]
    def attribute(method_name)
      unless [:"#{method_name}", :"#{method_name}="].all? { |sym| @klass.instance_methods.include?(sym) } || @klass.column_names.include?(method_name.to_s)
        raise ::ArgumentError.new("method_name - #{method_name.inspect} is invalid")
      end

      self.inject([[method_name]]) { |acc, path|
        acc << path.options.values_at(:method_name, :index)
        acc
      }.reverse.flatten(1).compact.collect(&:to_s).join('_').to_sym
    end

    %i(belongs_to has_one).each do |macro|
      define_method(macro) do |method_name, **options|
        options.assert_valid_keys(:data)

        # @return [ActiveRecord::Reflection::MacroReflection]
        reflection = @klass.reflect_on_association(method_name)

        if reflection.nil? || (reflection.macro != macro)
          raise ::ArgumentError.new("method_name - #{method_name.inspect} is invalid")
        end

        self.class.new(reflection.klass, self, **options.merge({
          macro: macro,
          method_name: method_name,
          index: nil,
        }))
      end
    end

    %i(has_many has_and_belongs_to_many).each do |macro|
      define_method(macro) do |method_name, index, **options|
        options.assert_valid_keys(:data)

        # @return [ActiveRecord::Reflection::MacroReflection]
        reflection = @klass.reflect_on_association(method_name)

        if reflection.nil? || (reflection.macro != macro)
          raise ::ArgumentError.new("method_name - #{method_name.inspect} is invalid")
        end

        self.class.new(reflection.klass, self, **options.merge({
          macro: macro,
          method_name: method_name,
          index: index,
        }))
      end
    end
  end
end
