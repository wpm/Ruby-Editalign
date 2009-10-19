module EditAlign


  # Exception raised by the optimal_alignment function when all the alignments
  # have been found.
  class NoMoreAlignments < Exception
  end

  # Derived classes must implement the optimal_alignment function.
  #
  # The operation cost function handles the following arguments:
  #
  # [_operation_] edit operation, :insert, :delete, or :substitute
  # [_items_] item or items the operation is applied to
  #
  # For insertion and deletion operations there is a single item.  For
  # substitution operations there are two: the first comes from the source
  # and the second comes from the target.
  class AlignmentGenerator
    include Enumerable
    
    attr_reader :source
    attr_reader :target

    # Initialize the generator with two arrays and a weighting function.  The
    # first array will be converted to the latter by means of edit operations.
    # The <em>operation_cost</em> function determines the cost of each
    # operation.
    #
    # If strings are specified for either of the arrays, they are converted
    # into arrays of characters.
    #
    # [_source_] the source array
    # [_target_] the destination array
    # [<em>operation_cost</em>] the operation weighting function
    #
    def initialize(source, target, &operation_cost)
      @source, @target = [source, target].map do |s|
        [nil] + (s.is_a?(String) ? s.scan(/./mu) : s)
      end
      @operation_cost = operation_cost.nil? ? lambda do |operation, *items|
        # A weighting function for the Levenshtein alignment.  Insertion,
        # deletion, and substitution of unlike items are cost 1 and
        # substitution of like items are cost 0.
        case operation
        when :substitute
          items[0] == items[1] ? 0 : 1
        when :insert
          1
        when :delete
          1
        else
          raise ArgumentError.new("Invalid edit operation #{operation}")
        end
      end : operation_cost
    end

    # Display the current costs grid.
    def to_s
      "#{@source}:#{@target}\n#{costs}"
    end

    # Yield alignments in order of cost.
    def each
      begin
        while true
          optimal_alignment do |a|
            LOGGER.debug(self)
            yield Alignment.new(a.first, source, target, a.last)
          end
          prepare_for_next_alignments
        end
      rescue NoMoreAlignments => e
        LOGGER.debug("Found all alignments.")
      end      
    end

    protected

    # The optimal alignment between source and target.  This is a
    # [_cost_, _ops_] 2-ple where _cost_ is the edit distance and _ops_ is an
    # array of edit operations.
    def optimal_alignment
      nil
    end

    # The costs grid.
    def costs
      # TODO Implement
    end

    # This function is called after all optimal alignments of a certain cost
    # have been found.  It changes the search state so that a subsequent call
    # to optimal_alignment will find all the alignments with the next highest
    # edit distance.
    def prepare_for_next_alignments
    end

  end
  
  
  class Alignment
    include Enumerable

    attr_reader :cost, :source, :target, :edit_operations
    
    def initialize(cost, source, target, edit_operations)
      @cost = cost
      @source = source
      @target = target
      @edit_operations = edit_operations
    end
  
    # Yields [source, target, edit operation] triples.
    def each
      source.zip(target, edit_operations).each { |t| yield t }
    end

  end

  # The optimal alignment.
  def EditAlign.alignment(aligner, source, target)
    aligner.new(source, target).first
  end

  # The optimal edit cost.
  def EditAlign.edit_distance(aligner, source, target)
    EditAlign.alignment(aligner, source, target).cost
  end

end