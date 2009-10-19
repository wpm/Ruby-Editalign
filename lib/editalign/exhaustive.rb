require "set"

module EditAlign

  # ExhaustiveSearch has the same backtrace issues as Dijkstra.  In fact they can probaby share the same backtrace class.

  class ExhaustiveSearch < AlignmentGenerator
    attr_reader :costs

    def initialize(source_init, target_init, &operation_cost)
      super
      # The backtrace is a hash of [i,j] -> [k,l].
      @backtrace = {}
      # Initialize a two-dimensional cost array.  Index by (row, column) where
      # elements of the source label columns and elements of the target label
      # rows.
      @costs = LabeledMatrix.new(source, target)
      @costs[0][0] = 0
      # Fill in the top row with the cost of delete operations.
      (1..@costs.num_cols-1).each do |j|
        @costs[0][j] = @costs[0][j-1] + @operation_cost.call(:delete, source[j])
        @backtrace[[0, j]] = [0, j-1]
      end
      # Fill in the first column with the cost of insert operations.
      (1..@costs.num_rows-1).each do |i|
        @costs[i][0] = @costs[i-1][0] + @operation_cost.call(:insert, target[i])
        @backtrace[[i, 0]] = [i-1, 0]
      end
      # A set of links removed from the grid.
      @removed = Set.new
    end
    
    # Create [previous cell, cost] 2-ples for each edit operation.
    def incomig_cells(i,j)
      s = []
      if not @removed.include?([ [i, j-1], [i,j] ])
        insert = [ [i, j-1],  @costs[i][j-1] +
                   @operation_cost.call(:insert, @costs.row_labels[i]) ]
        s << insert
      end
      if not @removed.include?([ [i-1,j], [i,j] ])
        delete = [ [i-1, j],  @costs[i-1][j] +
                   @operation_cost.call(:delete, @costs.col_labels[i]) ]
        s << delete
      end
      if not @removed.include?([ [i-1, j-1], [i,j] ])
        substitute = [ [i-1, j-1], @costs[i-1][j-1] +
                       @operation_cost.call(:substitute,
                                            [@costs.col_labels[i-1],
                                             @costs.row_labels[j-1]]) ]
        s << substitute
      end
      s
    end
    
    def optimal_alignment
      # Enumerate over the cells in the table besides the first row and
      # column.
      # For each cell calculate the cost target arrive there by insertion,
      # deletion, and substitution.
      (1..@costs.num_rows-1).each do |i|
        (1..@costs.num_cols-1).each do |j|
          # Add the lowest cost to the grid and the lowest cost previous cell
          # to the backtrace.
          # TODO handle next_steps == []
          incoming = incomig_cells(i,j)
          raise NoMoreAlignments if incoming.empty?
          min = from.min { |a, b| a.last <=> b.last }
          @backtrace[[i,j]] = min.first
          @costs[i][j] = min.last
        end
      end
      # Yield the optimal alignment.
      yield [@costs[@costs.num_rows-1][@costs.num_cols-1], read_backtrace]
    end # optimal_alignment
    
    protected
    
    # Read the edit operations off the backtrace.
    def read_backtrace
      edit_operations = []
      i = @costs.num_rows-1
      j = @costs.num_cols-1
      while true
        m,n = @backtrace[[i,j]]
        break if [m, n] == [0, 0]
        edit_operations << if m == i and n == j-1
          :insert
        elsif m == i-1 and n == j
          :delete
        elsif m == i-1 and n ==j-1
          :substitute
        else
          raise "Invalid backtrace [#{m}, #{n}] -> [#{i}, #{j}]"
        end
        i = m
        j = n
      end
      edit_operations
    end
    
    def prepare_for_next_alignments
      
    end
    
  end # ExhaustiveSearch


  # * source:: the source array
  # * target:: the destination array
  # def EditAlign.exhaustive_grid_search(source, target, &weight)
  #   backtrace = {}
  #   # Initialize a two-dimensional cost array.  Index by (row, column) where
  #   # source are columns and target are rows.
  #   cost = LabeledMatrix.new(source, target)
  #   cost[0][0] = 0
  #   # Fill in the top row with the cost of delete operations.
  #   (1..cost.num_cols-1).each do |j|
  #     cost[0][j] = cost[0][j-1] + weight.call(:delete, source[j])
  #     backtrace[[0, j]] = [0, j-1]
  #   end
  #   # Fill in the first column with the cost of insert operations.
  #   (1..cost.num_rows-1).each do |i|
  #     cost[i][0] = cost[i-1][0] + weight.call(:insert, target[i])
  #     backtrace[[i, 0]] = [i-1, 0]
  #   end
  #   # Enumerate over the remaining cells in the table.
  #   (1..cost.num_rows-1).each do |i|
  #     (1..cost.num_cols-1).each do |j|
  #       # For each cell calculate the cost target arrive there by insertion,
  #       # deletion, and substitution.
  #       insert = [ [i, j-1],  cost[i][j-1] + weight.call(:insert, cost.row_labels[i]) ]
  #       delete = [ [i-1, j],  cost[i-1][j] + weight.call(:delete, cost.col_labels[i]) ]
  #       substitute = [ [i-1, j-1], cost[i-1][j-1] + weight.call(:substitute, [cost.col_labels[i-1], cost.row_labels[j-1]]) ]
  #       # Add the lowest cost target the matrix and backtrack.
  #       min = [insert, delete, substitute].min { |a, b| a.last <=> b.last }
  #       backtrace[[i,j]] = min.first
  #       cost[i][j] = min.last
  #     end
  #   end
  #   # TODO Finish implementation
  #   [cost, backtrace]
  # end

end