require "priority_queue"
require "set"

require "editalign/graph"

module EditAlign

  # TODO This should be A*, not Dijkstra (http://en.wikipedia.org/wiki/A*_search_algorithm).  All I need to do is add a heuristic function.

  # The Dijkstra search algorithm.
  class Dijkstra
    include Enumerable

    # attr_reader :source, :target, :graph, :agenda, :backtrace, :cost

    # Initialize this object to perform a search for the optimal paths from
    # _source_ to _target_ in _graph_.
    #
    # [_source_] the source node in the graph
    # [_target_] the target node in the graph
    # [_graph_] a WeightedDirectedGraph
    def initialize(source, target, graph)
      @source = source
      @target = target
      @graph = graph
      @agenda = SearchAgenda.new
      @cost = SearchPriorityQueue.new
      @backtrace = DijkstraBacktrace.new
      @graph.each do |node|
        @agenda << node
        @cost[node] = (node == @source) ? 0 : INFINITY
      end
    end

    # Display all the internal data structures in tabular form.
    def to_s
      "#{@graph}\n" +
      "Agenda: #{@agenda}\n" +
      "Cost: #{@cost}\n" +
      "Backtrace:\n#{@backtrace}"
    end

    # Enumerate paths between the specified nodes in order of cost.
    def each
      while true
        LOGGER.debug("Dijkstra find optimal paths\n#{self}")
        break if not find_next_optimal_path
        # Read the paths off the backtrace pointers.
        each_path_from_backtrace { |cost, path| yield [cost, path] }
        # Prepare the costs and backtrace structures for the next iteration.
        @remove_edges.each do |from, to|
          LOGGER.debug("Remove edge " +
                       "#{from} --#{@graph.weight(from, to)}--> #{to}")
          # Remove the last branching edges from the graph.
          @graph.remove_edge(from, to)
          LOGGER.debug("New graph\n#{@graph}")
          # Put nodes from removed edges back on the agenda and reset the
          # priority of the later node.
          @agenda << from
          @agenda << to
          LOGGER.debug("Rollback agenda to #{@agenda}")
          @cost[to] = @backtrace.optimal_cost(to)
          LOGGER.debug("Rollback cost to #{@cost}")
        end
      end # while true
    end

    # Find the next optimal path from the source node to the target in the
    # graph.  When this function returns true, the costs and backtrace data
    # structures will contain this path.
    #
    # If the function returns false, there are no more paths to be found.
    def find_next_optimal_path
      # Find the next path.
      until @agenda.empty?
        node = @cost.fetch_optimal_node(@agenda)
        optimal_cost = @cost[node]
        @agenda.delete(node)
        LOGGER.debug("Explore node #{node}(#{optimal_cost})\n" + \
                     "New agenda #{@agenda}")
        if optimal_cost == INFINITY
          LOGGER.debug("Target #{@target} is inaccessible")
          return false
        end
        if node == @target
          LOGGER.debug("Reached target #{@target}")
          break
        end
        @graph.each_adjacent(node) do |next_node|
          d = optimal_cost + @graph.weight(node, next_node)
          @backtrace.add_path_head(node, next_node, d)
          if d < @cost[next_node]
            @cost[next_node] = d
            LOGGER.debug("Relax cost(#{next_node}) = #{@cost[next_node]}\n" +
                         "New cost #{@cost}")
          end
        end
      end
      true
    end

    # Enumerate over all complete optimal paths in the backtrace tree.
    #
    # This function has two side effects:
    #    1. It removes backtrace info for all yielded paths.
    #    2. It populates the <em>branching_edges</em> Array with ordered
    #       pairs of nodes corresponding to edges to delete from the graph
    #       before running the next search.
    def each_path_from_backtrace
      @remove_edges = []
      # Do a depth-first enumeration through the backtrace tree finding
      # optimal cost paths.
      paths = [[@target]]
      until paths.empty?
        path = paths.pop
        node = path.first
        optimal_costs = @backtrace[node].keys
        optimal_cost = optimal_costs.min
        LOGGER.debug("Read off paths to #{node} of cost #{optimal_cost}")
        # Remove the edges between the previous node and this one if this is
        # the first optimal path branch.
        remove = @remove_edges.empty? and optimal_costs.length > 1
        @backtrace[path.first][optimal_cost].each do |prev_node|
          # Remove first optimal path branch edges or, if there are no
          # branches, edges coming from the source to the optimal path.
          if remove or (@remove_edges.empty? and
                        prev_node == @source)
            @remove_edges << [prev_node, node]
          end
          # Add the previous node to the head of the path.
          new_path = [prev_node] + path
          if prev_node == @source
            # Yield the complete path.
            LOGGER.debug("Found path #{new_path.inspect}")
            yield [optimal_cost, new_path]
          else
            # Put an incomplete path back on the agenda.
            paths << new_path
          end
        end # each prev_node
        @backtrace.delete_optimal_paths(path.first)
      end # while paths
    end

    protected :find_next_optimal_path, :each_path_from_backtrace
  end


  # A priority queue for use in the Dijkstra search.
  class SearchPriorityQueue < PriorityQueue
    # Given a set of nodes Q, return the node q in Q that has the optimal
    # cost.
    #
    # In the case of priority tie, an arbitrary optimal node is returned.
    def fetch_optimal_node(nodes)
      nodes.sort_by {|node| self[node]}.first
    end
    
    # Same as inspect
    def to_s
      inspect
    end
  end


  # Agenda for the Dijkstra search algorithm.
  #
  # This is just a set with stringification.
  class SearchAgenda < Set
    # Display in standard set notation.
    def to_s
      "{#{to_a.join(', ')}}"
    end
  end


  class BacktraceGraph < WeightedDirectedGraph
    # Enumerate the optimal complete paths from _source_ to _target_.
    #
    # [_source_] the source node in the graph
    # [_target_] the target node in the graph
    def each_optimal_path(source, target)
    end
    
    # The optimal cost to reach _node_.
    #
    # This is infinity if there are no paths to _node_ present in this
    # structure.
    #
    # [_node_] a node in the graph
    def optimal_cost(node)
    end
    
    # Are there multiple incoming nodes with different costs?
    #
    # [_node_] a node in the graph
    def multicost_incoming_nodes?(node)
    end
    
    # Upate the backtrace structure after exploring a node.
    #
    # [_from_] the node the path head points from
    # [_to_] the node the path head points to
    # [<em>total_cost</em>] the total cost to reach _to_ via _from_
    def add_path_head(from, to, total_cost)
      LOGGER.debug("Add path head (#{from} -#{total_cost}- #{to})")
      add_edge(from, to, total_cost)
      LOGGER.debug("New backtrace\n#{self}")
    end
  
    # Delete the lowest cost paths coming into the specified node.
    #
    # [_head_] the head node of the optimal paths to remove
    def delete_optimal_paths(head)
      LOGGER.debug("Delete optimal paths to #{head}")
      LOGGER.debug("New backtrace\n#{self}")
    end

  end


  # Backtrace: to -> total cost -> [from, from...]
  class DijkstraBacktrace < Hash

    # Display the structure in tabular form.
    def to_s
      s = []
      each_key do |to|
        s << "#{to}:"
        self[to].keys.sort.each do |total_cost|
          from = self[to][total_cost]
          s << "    #{total_cost} #{from.inspect}"
        end
      end
      s.join("\n")
    end

    # Enumerate the optimal complete paths from _source_ to _target_.
    #
    # [_source_] the source node in the graph
    # [_target_] the target node in the graph
    def each_optimal_path(source, target)
      # Do a depth-first enumeration through the backtrace.
      paths = [OptimalPath[target]]
      until paths.empty?
        path = paths.pop
        node = path.first
        optimal_cost = optimal_cost(node)
        # The optimal cost into the last node is the total cost for the path.
        path.total_cost ||= optimal_cost
        # Get the optimal-cost nodes pointing into the head of this path.
        prev_nodes = self[node][optimal_cost]
        # If this path crosses a less optimal one, remember this in
        # last_branch_edges.
        if multicost_incoming_nodes?(node)
          path.last_branch_edges ||= prev_nodes.map do |prev_node|
            [prev_node, node]
          end
        end
        # Enumerate the optimal-cost nodes pointing into the head of this
        # path.
        prev_nodes.each do |prev_node|
          # Prepend the incoming node to the path.
          new_path = [prev_node] + path
          # Yield the new path if it is complete.  Otherwise, put it back on
          # the paths list.
          if prev_node == source
            # If this path did not cross any less optimal ones, place the
            # branch after the source node.
            path.last_branch_edges ||= [new_path[0], new_path[1]]
            yield new_path
          else
            paths << new_path
          end
        end # prev_nodes.each
      end # until paths.empty?
    end

    # The optimal cost to reach _node_.
    #
    # This is infinity if there are no paths to _node_ present in this
    # structure.
    #
    # [_node_] a node in the graph
    def optimal_cost(node)
      optimal_costs = self[node].keys
      optimal_costs.empty? ? INFINITY : optimal_costs.min
    end

    # Are the multiple incoming nodes with different costs.
    #
    # [_node_] a node in the graph
    def multicost_incoming_nodes?(node)
      self[node].keys.length > 1
    end

    # Upate the backtrace structure after exploring a node.
    #
    # [_from_] the node the path head points from
    # [_to_] the node the path head points to
    # [<em>total_cost</em>] the total cost to reach _to_ via _from_
    def add_path_head(from, to, total_cost)
      LOGGER.debug("Add path head to backtrace #{from} -> #{to} (#{total_cost})")
      if not has_key?(to)
        self[to] = {}
      end
      if not self[to].has_key?(total_cost)
        self[to][total_cost] = []
      end
      self[to][total_cost] <<= from
      LOGGER.debug("New backtrace\n#{self}")
    end

    # Delete the lowest cost paths coming into the specified node.
    #
    # [_head_] the head node of the optimal paths to remove
    def delete_optimal_paths(head)
      optimal_cost = self[head].keys.min
      LOGGER.debug("Remove cost #{optimal_cost} paths to #{head}")
      self[head].delete(optimal_cost)
      LOGGER.debug("New backtrace\n#{self}")
    end

  end


  # A optimal path through the graph.
  class OptimalPath < Array
    # The total cost to traverse the path
    attr_accessor :total_cost
    # The topologically last edges in this path where it crosses less optimal
    # ones.
    attr_accessor :last_branch_edges

    def initialize
      @total_cost = nil
      @last_branch_edges = []
    end
  end


end
